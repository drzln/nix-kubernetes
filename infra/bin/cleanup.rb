# frozen_string_literal: true
# infra/bin/cleanup.rb

require_relative 'config'

def revoke_aws_credentials
  system("aws sts revoke-session --profile #{AWS_PROFILE} 2>/dev/null")
end

def cleanup_nuke_config
  File.delete(NUKE_CONFIG_PATH) if File.exist?(NUKE_CONFIG_PATH)
end
