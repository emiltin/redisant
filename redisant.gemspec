# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redisant/version'

Gem::Specification.new do |spec|
  spec.name          = "redisant"
  spec.version       = Redisant::VERSION
  spec.authors       = ["Emil Tin"]
  spec.email         = ["emil@tin.dk"]

  spec.summary       = %q{ORM-like Redis storage.}
  spec.description   = %q{Schema-less ORM-like Redis store.}
  spec.homepage      = "https://github.com/emiltin/redisant"
  spec.license       = "MIT"
  spec.required_ruby_version = '>= 2.0.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", '~> 2.2.26', '>= 2.2.26'
  spec.add_development_dependency "rake", '~> 13.0.6', '>= 13.0.6'
  spec.add_development_dependency "rspec", '~> 3.10.0', '>= 3.10.0'
  spec.add_development_dependency "redis", '~> 4.4.0', '>= 4.4.0'
end
