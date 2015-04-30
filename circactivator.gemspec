lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "circactivator/version"
require "English"

Gem::Specification.new do |gem|
  gem.name          = "circactivator"
  gem.version       = CircActivator::VERSION
  gem.license       = "Apache 2.0"
  gem.authors       = ["Adam Leff"]
  gem.email         = ["aleff@webmd.net"]
  gem.description   = "Program to update Circonus check bundles to activate metrics for collection."
  gem.summary       = gem.description

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = %w[circactivator]
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 2.1.2"

  gem.add_dependency "httparty",      "~> 0.13.3"
  gem.add_dependency "mixlib-log",    "~> 1.6.0"
  gem.add_dependency "settingslogic", "~> 2.0.9"
  gem.add_dependency "thor",          "~> 0.19.1"

  gem.add_development_dependency "pry",     "~> 0.10"
  gem.add_development_dependency "bundler", "~> 1.3"
  gem.add_development_dependency "rspec",   "~> 3.2"
  gem.add_development_dependency "webmock", "~> 1.21"
end