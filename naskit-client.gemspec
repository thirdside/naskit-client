# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'naskit/version'

Gem::Specification.new do |spec|
  spec.name          = "naskit-client"
  spec.version       = Naskit::VERSION
  spec.authors       = ["Guillaume Malette"]
  spec.email         = ["guillaume.malette@jadedpixel.com"]
  spec.description   = %q{TODO: Write a gem description}
  spec.summary       = %q{TODO: Write a gem summary}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 2.2.10"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "webmock", "~> 1.11.0"
  spec.add_development_dependency "rspec"

  spec.add_dependency "choice"
end
