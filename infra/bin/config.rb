# lib/config.rb
# frozen_string_literal: true

AWS_PROFILE ||= 'pleme' # ✅ Define once, prevent redefinition
AWS_REGION ||= 'us-east-1'
NUKE_CONFIG_PATH ||= 'aws-nuke-config.yml'
DUMMY_BLOCKLIST_ACCOUNT ||= '000000000000'
TEMP_ALIAS ||= 'aws-nuke-bypass'
