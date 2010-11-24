# -*- encoding: utf-8 -*-
require 'rubygems' unless defined?(::Gem)
require File.dirname(__FILE__) + "/lib/ripl/fresh"
 
Gem::Specification.new do |s|
  s.name        = "ripl-fresh"
  s.version     = Ripl::Fresh::VERSION
  s.authors     = ["Jan Lelis"]
  s.email       = "mail@janlelis.de"
  s.homepage    = "http://github.com/janlelis/fresh"
  s.summary     = "Fresh Ruby Enhanced SHell"
  s.description = "Fresh Ruby Enhanced SHell automatically detects, if your current command should be Ruby or a system command."
  s.required_rubygems_version = ">= 1.3.6"
  s.executables = ['ripl-fresh', 'fresh']
  s.add_dependency 'ripl', '>= 0.2.5'
  s.files = Dir.glob(%w[{lib,test}/**/*.rb bin/* [A-Z]*.{txt,rdoc} ext/**/*.{rb,c} **/deps.rip]) + %w{Rakefile .gemspec}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE"]
  s.license = 'MIT'
end
