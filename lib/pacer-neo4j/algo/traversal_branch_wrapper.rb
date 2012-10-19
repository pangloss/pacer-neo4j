module Pacer
  module Neo4j
    module Algo
      # Uses the interfaces defined here:
      # http://api.neo4j.org/1.8/org/neo4j/graphdb/Path.html
      # http://api.neo4j.org/1.8/org/neo4j/graphdb/traversal/TraversalBranch.html
      #
      # Note that I have removed methods that I didn't understand, assuming they are internal.
      class TraversalBranchWrapper
        import org.neo4j.graphdb.Node
        import com.tinkerpop.blueprints.impls.neo4j.Neo4jVertex
        import com.tinkerpop.blueprints.impls.neo4j.Neo4jEdge

        attr_reader :graph, :tb

        def initialize(tb, graph)
          @tb = tb
          @graph = graph
          @gv = graph.v
          @ge = graph.e
        end

        #Returns the end vertex of this path.
        def end_v
          wrap_vertex tb.endNode
        end

        # Iterates through both the vertices and edges of this path in order.
        def path
          tb.iterator.to_route.map(graph: graph, element_type: :mixed) do |e|
            if e.is_a? Node
              wrap_vertex e
            else
              wrap_edge e
            end
          end
        end

        # Returns the last edge in this path.
        def end_e
          wrap_edge tb.lastRelationship
        end

        # Returns the length of this path.
        def length
          tb.length
        end

        # Returns all the vertices in this path starting from the start vertex going forward towards the end vertex.
        def v
          tb.nodes.map { |n| wrap_vertex n }.to_route based_on: @gv
        end

        # Returns all the edges in between the vertices which this path consists of.
        def e
          tb.relationships.map { |r| wrap_edge r }.to_route based_on @ge
        end

        # Returns all the vertices in this path in reversed order, i.e.
        def reverse_v
          tb.reverseNodes.map { |n| wrap_vertex n }.to_route based_on @gv
        end

        # Returns all the edges in between the vertices which this path consists of in reverse order, i.e.
        def reverse_e
          tb.reverseRelationships.map { |r| wrap_edge r }.to_route based_on @ge
        end

        # Returns the start vertex of this path.
        def start_v
          wrap_vertex tb.startNode
        end

        # Returns whether or not the traversal should continue further along this branch.
        def continues?
          tb.continues
        end

        # Returns the number of edges this expansion source has expanded.
        def num_expanded
          tb.expanded
        end

        # Returns whether or not this branch (the Path representation of this
        # branch at least) should be included in the result of this traversal,
        # i.e. returned as one of the Paths from f.ex.
        # TraversalDescription.traverse(org.neo4j.graphdb.Node...)
        def included?
          tb.includes
        end

        # The parent expansion source which created this TraversalBranch.
        def parent
          TraversalBranchWrapper.new tb.parent, graph
        end

        # Explicitly tell this branch to be pruned so that consecutive calls to #next() is guaranteed to return null.
        def prune!
          tb.prune
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
