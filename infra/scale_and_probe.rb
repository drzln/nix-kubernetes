#!/usr/bin/env ruby
# frozen_string_literal: true

# ─────────────────────────────────────────────────────────────
# scale_and_probe.rb
#
# • Reads the rendered Terraform-style JSON produced by
#     pangea show templates/network.rb
# • Finds every aws_autoscaling_group
# • Scales each group to *one* instance
# • Waits until an instance is InService and has a public IP
# • Logs-in as **root** using the _single_ key you pass with --ssh-key
# • Runs `hostname` to prove SSH works
# • Executes:   colmena build  →  ruby fetch_ips.rb  →  colmena apply
# • Ensures **all** ASGs are scaled back to zero, even on failure
# ─────────────────────────────────────────────────────────────

require 'json'
require 'optparse'
require 'aws-sdk-autoscaling'
require 'aws-sdk-ec2'
require 'net/ssh'
require 'time'

# ─── helpers ─────────────────────────────────────────────────
def log(msg) = warn("[#{Time.now.iso8601}] #{msg}")

def abort!(msg)
  log("ERROR: #{msg}")
  exit 1
end

def scale_asg(asg_client, name, size)
  asg_client.update_auto_scaling_group(
    auto_scaling_group_name: name,
    min_size: size,
    max_size: size,
    desired_capacity: size
  )
end

def wait_for_instance(asg_client, ec2_client, group_name, timeout)
  deadline = Time.now + timeout
  loop do
    # ask the ASG about its instances
    asg = asg_client.describe_auto_scaling_groups(
      auto_scaling_group_names: [group_name]
    ).auto_scaling_groups.first

    instance_id = asg.instances.find { |i| i.lifecycle_state == 'InService' }&.instance_id
    if instance_id
      ec2  = ec2_client.describe_instances(instance_ids: [instance_id])
      inst = ec2.reservations[0].instances[0]
      ip   = inst.public_ip_address
      return [instance_id, ip] if ip
    end

    raise 'timeout waiting for EC2 public IP' if Time.now >= deadline

    sleep 5
  end
end

def probe_ssh(ip:, key_path:, max_wait:)
  deadline   = Time.now + max_wait
  backoff    = 5
  last_error = nil
  loop do
    begin
      hostname = Net::SSH.start(
        ip, 'root',
        keys: [File.expand_path(key_path)],
        non_interactive: true,
        verify_host_key: :never, # disables StrictHostKeyChecking
        auth_methods: %w[publickey],
        timeout: 10
      ) { |ssh| ssh.exec!('hostname').strip }

      log "SSH OK (root@#{ip}) → hostname=#{hostname}"
      return hostname
    rescue Net::SSH::AuthenticationFailed,
           Net::SSH::Disconnect,
           Net::SSH::ConnectionTimeout,
           Errno::ETIMEDOUT,
           SocketError => e
      last_error = e
      log "SSH not ready (#{e.class}: #{e.message}) – retrying in #{backoff}s"
    end
    raise last_error if Time.now >= deadline

    sleep backoff
    backoff = [backoff * 1.5, 30].min
  end
end

# ─── CLI options ─────────────────────────────────────────────
opts = {
  key: '~/.ssh/id_rsa',
  wait: 300
}
OptionParser.new do |o|
  o.banner = 'Usage: scale_and_probe.rb --ssh-key KEYFILE [--wait SECONDS]'
  o.on('-k', '--ssh-key PATH', 'Private key used for root SSH') { |v| opts[:key] = v }
  o.on('-w', '--wait SECONDS', Integer,
       'Maximum seconds to wait for an EC2 instance (default 300)') { |v| opts[:wait] = v }
end.parse!

abort!('Private key file not found') unless File.readable?(File.expand_path(opts[:key]))

# ─── Obtain plan JSON directly from `pangea show …` ──────────
plan_json = `pangea show templates/network.rb`
abort! 'pangea show failed or returned empty output' if plan_json.empty?

plan      = JSON.parse(plan_json, symbolize_names: true)
asg_defs  = plan.dig(:resource, :aws_autoscaling_group) || {}
asg_names = asg_defs.keys
abort! 'No autoscaling groups found in plan output' if asg_names.empty?
log "Autoscaling groups found: #{asg_names.join(', ')}"

# ─── AWS clients ─────────────────────────────────────────────
region = ENV.fetch('AWS_REGION', 'us-east-1')
asg_client = Aws::AutoScaling::Client.new(region: region)
ec2_client = Aws::EC2::Client.new(region: region)

# ─── Main workflow ───────────────────────────────────────────
begin
  asg_names.each do |name|
    log "Scaling #{name} → 1"
    scale_asg(asg_client, name, 1)

    log 'Waiting for instance to become InService + public IP…'
    instance_id, public_ip = wait_for_instance(asg_client, ec2_client, name, opts[:wait])
    log "Instance #{instance_id} ready at #{public_ip}"

    log 'Establishing SSH as root…'
    probe_ssh(ip: public_ip, key_path: opts[:key], max_wait: opts[:wait])
  end

  log 'All ASGs validated via SSH – running colmena pipeline'
  system('colmena build') || abort!('colmena build failed')
  system('rm -f dynamic-nodes.nix')
  system('ruby fetch_ips.rb')    || abort!('fetch_ips.rb failed')
  system('colmena apply')        || abort!('colmena apply failed')

# ─── Always scale back to zero ───────────────────────────────
ensure
  asg_names.each do |name|
    log "Scaling #{name} back to 0"
    begin
      scale_asg(asg_client, name, 0)
    rescue Aws::Errors::ServiceError => e
      log "Failed to scale #{name}: #{e.message}"
    end
  end
  log 'Cleanup complete – all ASGs set to desired_capacity = 0'
end
