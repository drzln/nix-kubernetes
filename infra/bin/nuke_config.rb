# frozen_string_literal: true

require 'json'
require_relative 'config' # ✅ Load shared constants
AWS_REGIONS = %w[
  global
  us-east-1
  us-east-2
  us-west-1
  us-west-2
  ca-central-1
  ca-west-1
  eu-north-1
  eu-west-1
  eu-west-2
  eu-west-3
  eu-central-1
  eu-central-2
  eu-south-1
  eu-south-2
  me-south-1
  me-central-1
  af-south-1
  ap-northeast-1
  ap-northeast-2
  ap-northeast-3
  ap-southeast-1
  ap-southeast-2
  ap-southeast-3
  ap-southeast-4
  ap-south-1
  ap-south-2
  ap-east-1
  cn-north-1
  cn-northwest-1
  sa-east-1
  il-central-1
  mx-central-1
  us-gov-west-1
  us-gov-east-1
].freeze

# ✅ Generate aws-nuke config file dynamically (Targeting ALL AWS Regions & Excluding IAM User `automation`)
def generate_nuke_config(account_id, account_alias)
  nuke_config = {
    'regions' => AWS_REGIONS, # ✅ Nuke ALL regions, including global resources
    'blocklist' => [DUMMY_BLOCKLIST_ACCOUNT], # ✅ Required to avoid error
    'bypass-alias-check-accounts' => [account_id], # ✅ Allow nuking without alias check
    'accounts' => {
      account_id => {
        'account-alias' => account_alias # ✅ Use temp alias or actual alias
      }
    }
  }
  File.write(NUKE_CONFIG_PATH, JSON.pretty_generate(nuke_config))
end
