# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pp-adaptive/version"

Gem::Specification.new do |s|
  s.name        = "creative-pp-adaptive"
  s.required_ruby_version = '>= 2.0.0'
  s.version     = AdaptivePayments::VERSION
  s.authors     = ["d11wtq, Epigene, Sacristan, CreativeGS"]
  s.email       = ["hi@creative.gs"]
  s.homepage    = "https://github.com/CreativeGS/pp-adaptive"
  s.summary     = %q{Rubygem for working with PayPal's Adaptive Payments API}
  s.description = %q{Provides complete access to PayPal's Adaptive Payments API}

  s.rubyforge_project = "creative-pp-adaptive"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency     "rest-client"
  s.add_runtime_dependency     "virtus",      "~> 1.0.0"
  s.add_runtime_dependency     "json"

  s.add_development_dependency "rspec",       "~> 3.6.0"
  s.add_development_dependency "rake"
  s.add_development_dependency "pry"
  s.add_development_dependency "simplecov"
end
