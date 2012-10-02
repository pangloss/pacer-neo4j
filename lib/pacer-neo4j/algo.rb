module Pacer
  module Core::Graph::VerticesRoute
    def path_to(to_v, opts = {})
      chain_route({transform: :shortest_path, element_type: :path, target: to_v}.merge opts)
    end
  end

  module Transform
    module ShortestPath
      import org.neo4j.graphalgo.CommonEvaluators
      import org.neo4j.graphalgo.GraphAlgoFactory
      import org.neo4j.graphdb.Direction
      import org.neo4j.kernel.Traversal
      import org.neo4j.graphdb.DynamicRelationshipType

      attr_accessor :target

      # specify one or many edge labels that the path may take in the given direction
      attr_accessor :in_e, :out_e, :both_e

      attr_accessor :path_expander

      # use dijkstra unless the below estimate properties are set
      attr_accessor :cost_evaluator, :cost_property, :cost_default, :cost_block

      def cost(property = nil, default = nil, &block)
        self.cost_property = property
        self.cost_default = default
        self.cost_block = block
        self
      end

      # use the aStar algorithm
      attr_accessor :estimate_evaluator, :lat_property, :long_property, :estimate_block

      def estimate(lat = nil, long = nil, &block)
        self.lat_property = lat
        self.long_property = long
        self.estimate_block = estimate_block
        self
      end

      # use pathsWithLength
      attr_accessor :length

      # default to shortest_path unless find_all is set
      attr_accessor :max_depth

      # use shortestPath
      attr_accessor :max_hit_count

      # Possible values:
      # true    - allPaths
      # :simple - allSimplePaths
      attr_accessor :find_all

      protected

      def attach_pipe(end_pipe)
        p = Pipe.new build_algo
        p.setStarts end_pipe
        p
      end

      def inspect_string
        "path_to(#{ target.inspect })"
      end

      private

      def has_cost?
        cost_evaluator or cost_property or cost_block
      end

      def has_estimate?
        estimate_evaluator or (lat_property and long_property) or estimate_block
      end

      def build_algo
        if has_cost?
          if has_estimate?
            GraphAlgoFactory.aStar expander, build_cost, build_estimate
          else
            GraphAlgoFactory.aStar expander, build_cost
          end
        elsif length
          GraphAlgoFactory.pathsWithLength expander, length
        elsif find_all == :simple and max_depth
          GraphAlgoFactory.allSimplePaths expander, max_depth
        elsif find_all and max_depth
          GraphAlgoFactory.allPaths expander, max_depth
        elsif max_depth
          if max_hit_count
            GraphAlgoFactory.shortestPath expander, max_depth, max_hit_count
          else
            GraphAlgoFactory.shortestPath expander, max_depth
          end
        end
      end

      def expander
        if path_expander
          path_expander
        else
          e = Traversal.emptyExpander
          [*out_e].each do |label|
            e.add DynamicRelationshipType.withName(label), Direction::OUTGOING
          end
          [*in_e].each do |label|
            e.add DynamicRelationshipType.withName(label), Direction::INCOMING
          end
          [*both_e].each do |label|
            e.add DynamicRelationshipType.withName(label), Direction::BOTH
          end
          e
        end
      end

      def build_cost
        if cost_evaluator
          cost_evaluator
        elsif cost_property
          if cost_default
            CommonEvaluators.doubleCostEvaluator cost_property.to_s, cost_default.to_f
          else
            CommonEvaluators.doubleCostEvaluator cost_property.to_s
          end
        elsif cost_block
          fail 'not done yet'
        end
      end

      def build_estimate
        if estimate_evaluator
          estimate_evaluator
        elsif lat_property and long_property
          CommonEvaluators.geoEstimateEvaluator lat_property.to_s, long_property.to_s
        elsif estimate_block
          fail 'not done yet'
        end
      end

      class Pipe < Pacer::Pipes::RubyPipe
        attr_reader :algo

        def initialize(algo)
          super()
          @algo = algo
        end

        def processNextStart

        end
      end
    end
  end
end
