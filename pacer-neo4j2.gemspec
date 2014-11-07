# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pacer-neo4j2/version"

Gem::Specification.new do |s|
  s.name        = "pacer-neo4j2"
  s.version     = Pacer::Neo4j2::VERSION
  s.platform    = 'java'
  s.authors     = ["Darrick Wiebe"]
  s.email       = ["dw@xnlogic.com"]
  s.homepage    = "http://neo4j.org"
  s.summary     = %q{Neo4J jars and related code for Pacer}
  s.description = s.summary

  s.add_dependency 'pacer', Pacer::Neo4j2::PACER_REQ
  s.add_dependency "lock_jar", "~> 0.10.0"

  s.rubyforge_project = "pacer-neo4j2"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]
end
