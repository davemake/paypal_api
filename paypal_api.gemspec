# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "paypal/version"

Gem::Specification.new do |s|
  s.name        = "paypal_api"
  s.version     = Paypal::VERSION
  s.authors     = ["Matt Handler"]
  s.email       = ["matt.handler@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{an interface to paypals api}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "paypal_api"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", "~> 2.6"
  s.add_development_dependency "rake", "0.8.7"
end
