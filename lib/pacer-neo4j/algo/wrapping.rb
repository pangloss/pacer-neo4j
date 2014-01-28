module Pacer
  module Neo4j
    module Algo
      module Wrapping
        import org.neo4j.graphdb.Node
        import org.neo4j.graphdb.Relationship
        import com.tinkerpop.blueprints.impls.neo4j2.Neo4j2Vertex
        import com.tinkerpop.blueprints.impls.neo4j2.Neo4j2Edge

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

        def wrap_vertex(v)
          Pacer::Wrappers::VertexWrapper.new graph, Neo4j2Vertex.new(v, graph.blueprints_graph)
        end

        def wrap_edge(e)
          Pacer::Wrappers::EdgeWrapper.new graph, Neo4j2Edge.new(e, graph.blueprints_graph)
        end
      end
    end
  end
end
