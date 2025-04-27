#!/usr/bin/env ruby
# frozen_string_literal: true

begin
  system('ruby fetch_ips.rb')
  system('colmena build')
  system('colmena apply')
ensure
  asg_names.each do |name|
    log "Scaling #{name} back to 0"
    begin
      scale_asg(asg, name, 0)
    rescue StandardError
      log("Could not scale #{name}: #{$ERROR_INFO}")
    end
  end
  log 'Cleanup complete'
end
