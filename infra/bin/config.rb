# lib/config.rb
# frozen_string_literal: true
# infra/bin/config.rb

AWS_PROFILE ||= 'pleme'
AWS_REGION ||= 'us-east-1'
NUKE_CONFIG_PATH ||= 'aws-nuke-config.yml'
DUMMY_BLOCKLIST_ACCOUNT ||= '000000000000'
TEMP_ALIAS ||= 'aws-nuke-bypass'
