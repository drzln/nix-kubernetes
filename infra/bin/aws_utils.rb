# frozen_string_literal: true
# infra/bin/aws_utils.rb

require_relative 'config' # ✅ Load shared constants

# ✅ Ensure aws-nuke is installed
def check_aws_nuke_installed
  system('command -v aws-nuke > /dev/null') || abort("aws-nuke is not installed. Install it using 'nix shell nixpkgs#aws-nuke'")
end

# ✅ Fetch AWS Account ID dynamically
def fetch_aws_account_id
  `aws sts get-caller-identity --query "Account" --profile #{AWS_PROFILE} --output text`.strip.tap do |account_id|
    abort('Failed to retrieve AWS Account ID. Check AWS credentials.') if account_id.empty? || account_id == 'None'
  end
end

# ✅ Fetch or Assign AWS Account Alias (Required for AWS Nuke)
def fetch_or_set_account_alias
  alias_result = `aws iam list-account-aliases --query "AccountAliases[0]" --profile #{AWS_PROFILE} --output text`.strip
  return alias_result unless alias_result.empty? || alias_result == 'None'

  system("aws iam create-account-alias --account-alias #{TEMP_ALIAS} --profile #{AWS_PROFILE}")
  TEMP_ALIAS
end

# ✅ Run aws-nuke to destroy everything (Excluding IAM User)
def run_aws_nuke
  system("aws-nuke run --config #{NUKE_CONFIG_PATH} --profile #{AWS_PROFILE} --no-dry-run --no-prompt --no-alias-check") || abort('AWS nuke failed.')
end
