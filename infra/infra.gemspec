# frozen_string_literal: true

lib = File.expand_path(%(lib), __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name                  = %(infra)
  spec.version               = %(0.0.1)
  spec.authors               = [%(drzthslnt@gmail.com)]
  spec.email                 = [%(drzthslnt@gmail.com)]
  spec.description           = %(infrastructure)
  spec.summary               = %(infrastructure)
  spec.homepage              = %(https://github.com/drzln/#{spec.name})
  spec.license               = %(MIT)
  spec.require_paths         = [%(lib)]
  spec.required_ruby_version = %(>=3.3.0)

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  %w[
    rake
    rspec
    debug
    rubocop
    ruby-lsp
    rubocop-rake
    rubocop-rspec
    debug_inspector
  ].each do |dep|
    spec.add_development_dependency dep
  end

  %w[
    rexml
    pangea
    bundler
    toml-rb
    net-ssh
    tty-box
    tty-color
    tty-table
    tty-option
    aws-sdk-s3
    aws-sdk-ec2
    tty-progressbar
    aws-sdk-dynamodb
    aws-sdk-autoscaling
    abstract-synthesizer
    terraform-synthesizer
  ].each do |dep|
    spec.add_dependency dep
  end
  spec.metadata['rubygems_mfa_required'] = 'true'
end
