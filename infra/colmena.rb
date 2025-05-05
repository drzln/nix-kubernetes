#!/usr/bin/env ruby
# frozen_string_literal: true
# colmena.rb

begin
  system('colmena apply --parallel 1')
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
