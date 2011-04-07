require 'yaml'

module Pacer
  Neo4jIndex = com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jIndex

  class Neo4jIndex
    include IndexMixin
  end
end
