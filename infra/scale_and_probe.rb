#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'optparse'
require 'time'
require 'aws-sdk-autoscaling'
require 'aws-sdk-ec2'
require 'net/ssh'
require 'English' # ← gives us $CHILD_STATUS

# ─── helpers ──────────────────────────────────────────────────────────
def log(msg) = warn "[#{Time.now.iso8601}] #{msg}"

def abort!(msg)
  log("ERROR: #{msg}")
  exit 1
end

DEFAULT_KEY = File.expand_path(
  "#{ENV.fetch('HOME', nil)}/.ssh/id_rsa"
).freeze
DEFAULT_WAIT  = 300
PLAN_COMMAND  = 'pangea show templates/network.rb'

# ─── CLI ──────────────────────────────────────────────────────────────
opts = {
  key: DEFAULT_KEY,
  wait: DEFAULT_WAIT,
  region: ENV.fetch('AWS_REGION', 'us-east-1')
}
OptionParser.new do |o|
  o.banner = 'Usage: ruby scale_and_probe.rb [OPTIONS]'
  o.on('-k', '--ssh-key PATH') { |v| opts[:key] = v }
  o.on('-w', '--wait SECS', Integer) { |v| opts[:wait] = v }
  o.on('-r', '--region NAME') { |v| opts[:region] = v }
end.parse!

abort! "SSH key #{opts[:key]} not readable" unless File.readable?(opts[:key])

# ─── render plan JSON ─────────────────────────────────────────────────
plan_json = `#{PLAN_COMMAND}`
abort! "Command “#{PLAN_COMMAND}” failed" unless $CHILD_STATUS&.success?

plan       = JSON.parse(plan_json, symbolize_names: true)
asg_defs   = plan.dig(:resource, :aws_autoscaling_group) || {}
asg_names  = asg_defs.keys
abort! 'No aws_autoscaling_group resources found' if asg_names.empty?
log "ASGs: #{asg_names.join(', ')}"

# ─── AWS clients ─────────────────────────────────────────────────────
asg  = Aws::AutoScaling::Client.new(region: opts[:region])
ec2  = Aws::EC2::Client.new(region: opts[:region])

# ─── functions ───────────────────────────────────────────────────────
def scale_asg(client, name, size)
  client.update_auto_scaling_group(
    auto_scaling_group_name: name,
    min_size: size,
    max_size: size,
    desired_capacity: size
  )
end

def wait_for_instance(asg_c, ec2_c, name, timeout)
  deadline = Time.now + timeout
  loop do
    grp = asg_c.describe_auto_scaling_groups(
      auto_scaling_group_names: [name]
    ).auto_scaling_groups.first

    inst_id = grp.instances.find { |i| i.lifecycle_state == 'InService' }&.instance_id
    if inst_id
      inst = ec2_c.describe_instances(instance_ids: [inst_id])
                  .reservations[0].instances[0]
      ip   = inst.public_ip_address
      return [inst_id, ip] if ip
    end
    raise Timeout::Error if Time.now >= deadline

    sleep 5
  end
end

def probe_ssh(ip:, key_path:, wait:)
  deadline = Time.now + wait
  backoff  = 5
  last_err = nil
  loop do
    host = Net::SSH.start(
      ip, 'root',
      keys: [key_path],
      keys_only: true,
      use_agent: false,
      non_interactive: true,
      verify_host_key: :never,
      auth_methods: %w[publickey],
      timeout: 10
    ) { |ssh| ssh.exec!('hostname').strip }
    log "SSH OK -> #{host.inspect}"
    return host
  rescue Net::SSH::AuthenticationFailed,
         Net::SSH::Disconnect,
         Net::SSH::ConnectionTimeout,
         Errno::ECONNREFUSED,
         Errno::ETIMEDOUT,
         SocketError => e
    last_err = e
    secs_left = (deadline - Time.now).ceil
    raise last_err if secs_left <= 0

    log "SSH not ready (#{e.class}) – retrying in #{backoff}s (#{secs_left}s left)"
    sleep backoff
    backoff = [(backoff * 1.5).ceil, 30].min
  end
end

# ─── main workflow ───────────────────────────────────────────────────
begin
  asg_names.each do |name|
    log "Scaling #{name} → 1"
    scale_asg(asg, name, 1)

    log 'Waiting for instance…'
    inst_id, ip = wait_for_instance(asg, ec2, name, opts[:wait])
    log "Instance #{inst_id} @ #{ip}"

    probe_ssh(ip: ip, key_path: opts[:key], wait: opts[:wait])
  end
  log 'All ASGs reachable via SSH ✔'
  system('rm -rf dyanamic-nodes.nix')
  system('colmena build')
  system('ruby fetch_ips.rb')
  # system('colmena apply')
ensure
  # asg_names.each do |name|
  #   log "Scaling #{name} back to 0"
  #   begin
  #     scale_asg(asg, name, 0)
  #   rescue StandardError
  #     log("Could not scale #{name}: #{$ERROR_INFO}")
  #   end
  # end
  log 'Cleanup complete'
end
