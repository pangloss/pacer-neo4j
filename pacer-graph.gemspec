# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pacer-graph/version"

Gem::Specification.new do |s|
  s.name        = "pacer-graph"
  s.version     = PacerGraph::VERSION
  s.platform    = 'jruby'
  s.authors     = ["Darrick Wiebe"]
  s.email       = ["darrick@innatesoftware.com"]
  s.homepage    = "http://www.tinkerpop.com"
  s.summary     = %q{Tinkerpop Stack packaged for Pacer}
  s.description = s.summary

  s.rubyforge_project = "pacer-graph"

  s.files         = `git ls-files`.split("\n") + [PacerGraph::JAR]
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
