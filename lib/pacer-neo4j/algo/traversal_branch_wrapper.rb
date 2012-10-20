module Pacer
  module Neo4j
    module Algo
      # Uses the interface defined here:
      # http://api.neo4j.org/1.8/org/neo4j/graphdb/traversal/TraversalBranch.html
      #
      # Note that I have removed methods that I didn't understand, assuming they are internal.
      class TraversalBranchWrapper < PathWrapper
        # Returns whether or not the traversal should continue further along this branch.
        def continues?
          raw_path.continues
        end

        # Returns the number of edges this expansion source has expanded.
        def num_expanded
          raw_path.expanded
        end

        # Returns whether or not this branch (the Path representation of this
        # branch at least) should be included in the result of this traversal,
        # i.e. returned as one of the Paths from f.ex.
        # TraversalDescription.traverse(org.neo4j.graphdb.Node...)
        def included?
          raw_path.includes
        end

        # The parent expansion source which created this TraversalBranch.
        def parent
          TraversalBranchWrapper.new raw_path.parent, graph
        end

        # Explicitly tell this branch to be pruned so that consecutive calls to #next() is guaranteed to return null.
        def prune!
          raw_path.prune
        end

        def to_s
          "#{super} num_expanded: #{ num_expanded }#{ continues? ? ' continues' : '' }#{ included? ? ' included' : '' }"
        end

        def inspect
          "#<TBR #{to_s}>"
        end
      end
    end
  end
end
