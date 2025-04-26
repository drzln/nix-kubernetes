#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'time'

# AWS settings
AMI_NAME = 'pangea-kubernetes-crio'
AWS_REGION = 'us-east-1'
TARGET_REGIONS = %w[us-west-1 us-west-2 eu-west-1].freeze # ✅ Regions to copy the AMI after creation
GIT_HASH = `git rev-parse --short HEAD`.strip
BUILD_VERSION = "#{Time.now.utc.strftime('%Y%m%d-%H%M%S')}-#{GIT_HASH.freeze}".freeze

# Function to delete an AMI and its associated snapshot
def delete_ami(ami_id, aws_region)
  puts "❌ Deleting AMI: #{ami_id}"

  # Get associated snapshot ID
  snapshot_id = `aws ec2 describe-images --image-ids #{ami_id} --query "Images[0].BlockDeviceMappings[0].Ebs.SnapshotId" --region #{aws_region} --output text`.strip

  # Deregister the AMI
  system("aws ec2 deregister-image --image-id #{ami_id} --region #{aws_region}")
  puts "✅ AMI #{ami_id} deregistered."

  # Delete the snapshot if it exists
  return if snapshot_id == 'None'

  puts "❌ Deleting associated snapshot: #{snapshot_id}"
  system("aws ec2 delete-snapshot --snapshot-id #{snapshot_id} --region #{aws_region}")
  puts "✅ Snapshot #{snapshot_id} deleted."
end

def restrictive_deletes
  # Step 1: Delete old AMI with the same name
  puts "🔍 Checking for existing AMI named '#{AMI_NAME}'..."
  existing_ami_id = `aws ec2 describe-images --filters "Name=name,Values=#{AMI_NAME}" --query "Images[0].ImageId" --region #{AWS_REGION} --output text`.strip
  delete_ami(existing_ami_id, AWS_REGION) unless existing_ami_id == 'None'

  # Step 2: Delete any AMIs **not** named "pangea-kubernetes-crio"
  puts '🔍 Checking for other AMIs that should not exist...'
  other_amis = `aws ec2 describe-images --owners self --query "Images[?Name!='#{AMI_NAME}'].ImageId" --region #{AWS_REGION} --output text`.strip.split

  if other_amis.empty?
    puts '✅ No unwanted AMIs found.'
  else
    other_amis.each do |ami_id|
      delete_ami(ami_id, AWS_REGION)
    end
  end

  # Step 3: Find and delete all unattached EBS volumes
  puts '🔍 Checking for unattached EBS volumes...'
  unattached_volumes = `aws ec2 describe-volumes --filters "Name=status,Values=available" --query "Volumes[*].VolumeId" --region #{AWS_REGION} --output text`.strip.split

  if unattached_volumes.empty?
    puts '✅ No unattached EBS volumes found.'
  else
    unattached_volumes.each do |volume_id|
      puts "❌ Deleting unused EBS volume: #{volume_id}"
      system("aws ec2 delete-volume --volume-id #{volume_id} --region #{AWS_REGION}")
      puts "✅ Volume #{volume_id} deleted."
    end
  end
end

# Step 4: Generate the Packer JSON template as a Ruby hash
packer_template = {
  variables: {
    aws_region: AWS_REGION,
    instance_type: 't3.medium'
  },
  builders: [
    {
      type: 'amazon-ebs',
      ssh_username: 'root',
      ami_name: AMI_NAME,
      ami_description: "nix-kubernetes images #{BUILD_VERSION}",
      region: 'us-east-1',
      source_ami: 'ami-08ee7b48673f8a214',
      instance_type: 'm5.xlarge',
      launch_block_device_mappings: [
        {
          device_name: '/dev/xvda',
          volume_size: 20,
          volume_type: 'gp3'
        }
      ],
      ami_regions: TARGET_REGIONS,
      tags: {
        'Name' => AMI_NAME,
        'Version' => BUILD_VERSION
      },
      subnet_id: 'subnet-03fa741ea3dfd69d8',
      vpc_id: 'vpc-0d09bd50f08dd63f0'
    }
  ],
  provisioners: [
    {
      type: 'file',
      source: 'configuration.nix',
      destination: '/etc/nixos/configuration.nix'
    },
    {
      type: 'shell',
      inline: [
        'sudo nixos-rebuild switch'
      ]
    }
    # {
    #   type: 'shell',
    #   inline: [
    #     'nix-env -q',
    #     'sudo nix-store --gc',
    #     'sudo nix-collect-garbage -d',
    #     'sudo nix-env --delete-generations old',
    #     'sudo nix-store --optimise',
    #     'sudo rm -rf /nix/store/*-debug',
    #     'sudo rm -rf /var/log/nix* /nix/var/nix/profiles/per-user/root /nix/var/log/nix/drvs/*',
    #     'sudo find /nix/store -type f -exec strip --strip-unneeded {} \\; 2>/dev/null',
    #     'sudo tar -czf /nix/store.tar.gz /nix/store && rm -rf /nix/store && tar -xzf /nix/store.tar.gz',
    #     'sudo nix-store --delete --everything'
    #   ]
    # }
  ]
}

# Save the Packer template as JSON
template_path = 'packer/templates/kubernetes/template.json'
puts "💾 Writing Packer template to #{template_path}..."
File.write(template_path, JSON.pretty_generate(packer_template))

# Step 5: Run Packer to build the AMI
puts '🚀 Running Packer build...'
system('packer init packer/templates/kubernetes/packer.pkr.hcl')
system('cd packer/templates/kubernetes && packer build template.json')
puts '✅ Packer build completed!'

# Step 6: Find the newly created AMI ID
new_ami_id = `aws ec2 describe-images --filters "Name=name,Values=#{AMI_NAME}" --query "Images[0].ImageId" --region #{AWS_REGION} --output text`.strip

if new_ami_id == 'None'
  puts '❌ Error: Could not find newly created AMI!'
  exit 1
end

puts "✅ New AMI created: #{new_ami_id}"

puts "🎉 Deployment complete! New AMI ID: #{new_ami_id} is now available in #{AWS_REGION} and copied to #{TARGET_REGIONS.join(', ')}."
