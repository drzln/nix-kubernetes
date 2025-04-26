# frozen_string_literal: true

require_relative 'config' # ✅ Load shared constants

# ✅ Revoke AWS Credentials (MFA, Session Tokens, Role Assumptions) but KEEP ~/.aws/config
def revoke_aws_credentials
  system("aws sts revoke-session --profile #{AWS_PROFILE} 2>/dev/null")
end

# ✅ Cleanup AWS Nuke Config File
def cleanup_nuke_config
  File.delete(NUKE_CONFIG_PATH) if File.exist?(NUKE_CONFIG_PATH)
end
