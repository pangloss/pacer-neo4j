require 'yaml'

module Pacer
  Neo4jVertex = com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jVertex
  # Extend the java class imported from blueprints.
  class Neo4jVertex
    include Pacer::Core::Graph::VerticesRoute
    include ElementMixin
    include VertexMixin
  end
end
