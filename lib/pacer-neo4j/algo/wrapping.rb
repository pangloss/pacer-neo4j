module Pacer
  module Neo4j
    module Algo
      module Wrapping
        import org.neo4j.graphdb.Node
        import org.neo4j.graphdb.Relationship
        import com.tinkerpop.blueprints.impls.neo4j.Neo4jVertex
        import com.tinkerpop.blueprints.impls.neo4j.Neo4jEdge

        private

        def wrap_path(p)
          p.collect do |e|
            if e.is_a? Node
              wrap_vertex e
            elsif e.is_a? Relationship
              wrap_edge e
            else
              e
            end
          end
        end

        def neo_vertex(v)
          Neo4jVertex.new(v, graph.blueprints_graph)
        end

        def neo_edge(v)
          Neo4jEdge.new(e, graph.blueprints_graph)
        end

        def wrap_vertex(v)
          Pacer::Wrappers::VertexWrapper.new graph, Neo4jVertex.new(v, graph.blueprints_graph)
        end

        def wrap_edge(e)
          Pacer::Wrappers::EdgeWrapper.new graph, Neo4jEdge.new(e, graph.blueprints_graph)
        end
      end
    end
  end
end
