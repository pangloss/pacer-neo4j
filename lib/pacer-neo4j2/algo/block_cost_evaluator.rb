module Pacer
  module Neo4j2
    module Algo
      class BlockCostEvaluator
        import org.neo4j.graphalgo.CostEvaluator
        import org.neo4j.graphdb.Direction
        import com.tinkerpop.blueprints.impls.neo4j2.Neo4j2Edge
        include CostEvaluator

        DIRS = {
          Direction::INCOMING => :in,
          Direction::OUTGOING => :out,
          Direction::BOTH => :both
        }

        attr_reader :block, :graph, :default

        def initialize(block, graph, default)
          @block = block
          @graph = graph
          @default = default.to_f
        end

        def getCost(rel, dir)
          e = Pacer::Wrappers::EdgeWrapper.new graph, Neo4j2Edge.new(rel, graph.blueprints_graph)
          result = block.call e, DIRS[dir]
          if result.is_a? Numeric
            result.to_f
          elsif default
            default
          else
            fail Pacer::ClientError, "No cost returned and no default specified: #{ result.inspect }"
          end
        end
      end
    end
  end
end
