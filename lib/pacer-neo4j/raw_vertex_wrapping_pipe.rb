module Pacer
  module Neo4j
    class RawVertexWrappingPipe < Pacer::Pipes::RubyPipe
      import com.tinkerpop.blueprints.impls.neo4j.Neo4jVertex

      attr_reader :graph

      def initialize(graph)
        super()
        @graph = graph.blueprints_graph
      end

      def processNextStart
        Neo4jVertex.new starts.next, graph
      end
    end
  end
end
