module Pacer
  module Neo4j
    module Algo
      # Uses the interface defined here:
      # http://api.neo4j.org/1.8/org/neo4j/graphdb/Path.html
      #
      # Note that I have removed methods that I didn't understand, assuming they are internal.
      class PathWrapper
        import org.neo4j.graphdb.Node
        import com.tinkerpop.blueprints.impls.neo4j.Neo4jVertex
        import com.tinkerpop.blueprints.impls.neo4j.Neo4jEdge

        attr_reader :graph, :raw_path

        def initialize(path, graph)
          @raw_path = path
          @graph = graph
          @gv = graph.v
          @ge = graph.e
        end

        #Returns the end vertex of this path.
        def end_v
          wrap_vertex raw_path.endNode
        end

        # Iterates through both the vertices and edges of this path in order.
        def path
          raw_path.iterator.to_route.map(graph: graph, element_type: :mixed) do |e|
            if e.is_a? Node
              wrap_vertex e
            else
              wrap_edge e
            end
          end
        end

        def to_a
          path.to_a
        end

        # Returns the last edge in this path.
        def end_e
          wrap_edge raw_path.lastRelationship
        end

        # Returns the length of this path.
        def length
          raw_path.length
        end

        # Returns all the vertices in this path starting from the start vertex going forward towards the end vertex.
        def v
          raw_path.nodes.map { |n| wrap_vertex n }.to_route based_on: @gv
        end

        # Returns all the edges in between the vertices which this path consists of.
        def e
          raw_path.relationships.map { |r| wrap_edge r }.to_route based_on @ge
        end

        # Returns all the vertices in this path in reversed order, i.e.
        def reverse_v
          raw_path.reverseNodes.map { |n| wrap_vertex n }.to_route based_on @gv
        end

        # Returns all the edges in between the vertices which this path consists of in reverse order, i.e.
        def reverse_e
          raw_path.reverseRelationships.map { |r| wrap_edge r }.to_route based_on @ge
        end

        # Returns the start vertex of this path.
        def start_v
          wrap_vertex raw_path.startNode
        end

        def to_s
          "#{ start_v.inspect }-(#{length})->#{end_v.inspect}"
        end

        def inspect
          "#<Path #{ to_s }>"
        end
        private

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
