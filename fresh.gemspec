# -*- encoding: utf-8 -*-
require 'rubygems' unless defined? Gem
require File.dirname(__FILE__) + "/lib/ripl/fresh"

Gem::Specification.new do |s|
  s.name        = "fresh"
  s.version     = Ripl::Fresh::VERSION
  s.authors     = ["Jan Lelis"]
  s.email       = "mail@janlelis.de"
  s.homepage    = "http://github.com/janlelis/fresh"
  s.summary     = "[dummy package] Fresh Ruby Enhanced SHell"
  s.description = "[dummy package] Fresh Ruby Enhanced SHell automatically detects, if your current command should be Ruby or a system command."
  s.add_dependency 'ripl-fresh', ">= #{ Ripl::Fresh::VERSION }"
end
