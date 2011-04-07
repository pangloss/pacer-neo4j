# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pacer-neo4j/version"

Gem::Specification.new do |s|
  s.name        = "pacer-neo4j"
  s.version     = Pacer::Neo4j::VERSION
  s.platform    = 'jruby'
  s.authors     = ["Darrick Wiebe"]
  s.email       = ["darrick@innatesoftware.com"]
  s.homepage    = "http://neo4j.org"
  s.summary     = %q{Neo4J jars and related code for Pacer}
  s.description = s.summary

  s.add_dependency 'pacer-graph', "~> #{Pacer::Neo4j::VERSION.split('.')[0,2].join('.')}"

  s.rubyforge_project = "pacer-neo4j"

  s.files         = `git ls-files`.split("\n") + [Pacer::Neo4j::JAR_PATH]
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
