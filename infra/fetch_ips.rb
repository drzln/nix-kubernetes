#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'aws-sdk-ec2'

NODE_TAG_KEY   = 'colmena'
AWS_REGION     = ENV.fetch('AWS_REGION', 'us-east-1')
OUTPUT_FILE    = File.expand_path('dynamic-nodes.nix', __dir__)

ec2 = Aws::EC2::Client.new(region: AWS_REGION)

filters = [
  { name: 'tag:product', values: ['kubernetes'] },
  { name: 'instance-state-name', values: ['running'] }
]

ips =
  ec2.describe_instances(filters:).reservations.flat_map(&:instances).each_with_object({}) do |inst, acc|
    node_name_tag = inst.tags.detect { |t| t.key == NODE_TAG_KEY }
    next unless node_name_tag && inst.public_ip_address

    acc[node_name_tag.value] = inst.public_ip_address
  end

abort 'No running instances with tag colmena=*' if ips.empty?

File.write(
  OUTPUT_FILE,
  # produces: { master-1 = "3.94.1.2"; master-2 = "3.94.1.3"; … }
  "{ #{ips.map { |k, v| "#{k} = \"#{v}\";" }.join(' ')} }"
)

puts "Wrote #{OUTPUT_FILE}"
