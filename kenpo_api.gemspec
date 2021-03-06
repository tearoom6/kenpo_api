# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kenpo_api/version'

Gem::Specification.new do |spec|
  spec.name          = 'kenpo_api'
  spec.version       = KenpoApi::VERSION
  spec.authors       = ['tearoom6']
  spec.email         = ['tearoom6.biz@gmail.com']

  spec.summary       = %q{Unofficial API for ITS kenpo reservation system.}
  spec.description   = %q{Unofficial API for ITS kenpo reservation system.}
  spec.homepage      = 'https://github.com/tearoom6/kenpo_api'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    #spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1'
  spec.add_development_dependency 'rake', '~> 10'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'pry', '~> 0.11.3'

  spec.add_dependency 'faraday', '~> 0.10'
  spec.add_dependency 'cookiejar', '~> 0.3'
  spec.add_dependency 'nokogiri', '~> 1'
  spec.add_dependency 'dry-validation', '~> 0.10'
end
