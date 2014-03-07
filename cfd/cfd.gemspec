# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cfd/version'

Gem::Specification.new do |spec|
  spec.name          = "cfd"
  spec.version       = Cfd::VERSION
  spec.authors       = ["HARADA Makoto"]
  spec.email         = ["haramako@gmail.com"]
  spec.description   = %q{CFD}
  spec.summary       = %q{CFD}
  spec.homepage      = ""
  spec.license       = "MIT"
  spec.extensions    = %w[ext/cfd/extconf.rb]

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
