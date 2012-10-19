module Pacer
  module Neo4j
    module Algo
      class BlockEstimateEvaluator
        import org.neo4j.graphalgo.EstimateEvaluator
        import com.tinkerpop.blueprints.impls.neo4j.Neo4jVertex
        include EstimateEvaluator

        attr_reader :block, :graph, :default

        def initialize(block, graph, default)
          @block = block
          @graph = graph
          @default = default.to_f
        end

        def getCost(node, goal)
          node = Pacer::Wrappers::VertexWrapper.new graph, Neo4jVertex.new(node, graph.blueprints_graph)
          goal = Pacer::Wrappers::VertexWrapper.new graph, Neo4jVertex.new(goal, graph.blueprints_graph)
          result = block.call node, goal
          if result.is_a? Numeric
            result.to_f
          elsif default
            default
          else
            fail Pacer::ClientError, "No estimate returned and no default specified: #{ result.inspect }"
          end
        end
      end
    end
  end
end
