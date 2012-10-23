module Pacer
  module Core::Graph
    module VerticesRoute
      def path_to(to_v, opts = {})
        route = self
        route = make_pairs(to_v) if to_v.is_a? Enumerable
        route.chain_route({transform: :path_finder, element_type: :path, max_hits: 1, target: to_v}.merge opts)
      end

      def paths_to(to_v, opts = {})
        route = self
        route = make_pairs(to_v) if to_v.is_a? Enumerable
        route.chain_route({transform: :path_finder, element_type: :path, target: to_v}.merge opts)
      end
    end

    module PathRoute
      def expand(opts = {})
        chain_route({transform: :path_finder, element_type: :path}.merge opts)
      end
    end
  end


  module Transform
    module PathFinder
      import org.neo4j.graphalgo.CommonEvaluators
      import org.neo4j.graphalgo.GraphAlgoFactory
      import org.neo4j.graphdb.Direction
      import org.neo4j.kernel.Traversal
      import org.neo4j.graphdb.DynamicRelationshipType
      include Pacer::Neo4j::Algo

      attr_accessor :target

      # specify one or many edge labels that the path may take in the given direction
      attr_accessor :in_labels, :out_labels, :both_labels

      # note that expander procs *must* return edge(s) that are connected to the end_v of the given path
      #
      # expander yields: { |path, state| path.is_a? Pacer::Neo4j::Algo::TraversalBranchWrapper }
      attr_accessor :expander, :forward, :reverse

      # use dijkstra unless the below estimate properties are set
      #
      # note that cost proc must return a Numeric unless cost_default is set
      #
      # cost yields: { |edge, direction| [:in, :out, :both].include? direction }
      attr_accessor :cost, :cost_property, :cost_default

      def set_cost(property = nil, default = nil, &block)
        self.cost_property = property
        self.cost_default = default
        self.cost = block
        self
      end

      # use the aStar algorithm
      #
      # note that estimate proc must return a Numeric unless estimate_default is set
      #
      # estimate yields: { |vertex, goal_vertex| }
      attr_accessor :estimate, :lat_property, :long_property, :estimate_default

      def set_estimate(lat = nil, long = nil, &block)
        self.lat_property = lat
        self.long_property = long
        self.estimate = block
        self
      end

      # use pathsWithLength
      #
      # Return only paths of the given length
      attr_accessor :length

      # default to shortest_path unless find_all is set
      attr_writer :max_depth
      def max_depth
        @max_depth || 5
      end

      # use shortestPath
      attr_accessor :max_hits

      # Possible values:
      # true    - allPaths
      # :simple - allSimplePaths
      attr_accessor :find_all

      protected

      def attach_pipe(end_pipe)
        if back.element_type == :path
          p = PathFromPathPipe.new build_algo, graph, max_hits
        else
          p = PathPipe.new build_algo, graph, target, max_hits
        end
        p.setStarts end_pipe
        attach_length_filter(p) if length and method != :with_length
        p
      end

      def attach_length_filter(end_pipe)
        pipe = Pacer::Pipes::BlockFilterPipe.new(self, proc { |p| p.length == length }, false)
        pipe.set_starts end_pipe if end_pipe
        pipe
      end

      def inspect_string
        if back.element_type == :path
          "expand[#{method}](max_depth: #{ max_depth })"
        else
          "paths_to[#{method}](#{ target.inspect }, max_depth: #{ max_depth })"
        end
      end

      def method
        if has_cost?
          if has_estimate?
            :aStar
          else
            :dijkstra
          end
        elsif find_all == :all and max_depth
          :all
        elsif find_all and max_depth
          :all_simple
        elsif length
          :with_length
        elsif max_depth
          if max_hits
            :shortest_with_max_hits
          else
            :shortest
          end
        end
      end

      private

      def has_cost?
        cost or cost_property or cost_default
      end

      def has_estimate?
        estimate or (lat_property and long_property) or estimate_default
      end

      def build_algo
        case method
        when :aStar
          GraphAlgoFactory.aStar build_expander, build_cost, build_estimate
        when :dijkstra
          GraphAlgoFactory.dijkstra build_expander, build_cost
        when :with_length
          GraphAlgoFactory.pathsWithLength build_expander, length
        when :all
          GraphAlgoFactory.allPaths build_expander, max_depth
        when :all_simple
          GraphAlgoFactory.allSimplePaths build_expander, max_depth
        when :shortest_with_max_hits
          GraphAlgoFactory.shortestPath build_expander, max_depth, max_hits
        when :shortest
          GraphAlgoFactory.shortestPath build_expander, max_depth
        when nil
          fail Pacer::ClientError, "Could not choose a path algorithm"
        else
          fail Pacer::LogicError, "Unable to build algo for #{ method }"
        end
      end

      def build_expander
        if forward.is_a? Proc and reverse.is_a? Proc
          BlockPathExpander.new forward, reverse, graph, max_depth
        elsif expander.is_a? Proc
          BlockPathExpander.new expander, expander, graph, max_depth
        elsif expander
          expander
        else
          e = Traversal.emptyExpander
          [*out_labels].each do |label|
            e.add DynamicRelationshipType.withName(label.to_s), Direction::OUTGOING
          end
          [*in_labels].each do |label|
            e.add DynamicRelationshipType.withName(label.to_s), Direction::INCOMING
          end
          [*both_labels].each do |label|
            e.add DynamicRelationshipType.withName(label.to_s), Direction::BOTH
          end
          e
        end
      end

      def build_cost
        if cost.is_a? Proc
          BlockCostEvaluator.new cost, graph, cost_default
        elsif cost
          cost
        elsif cost_property
          if cost_default
            CommonEvaluators.doubleCostEvaluator cost_property.to_s, cost_default.to_f
          else
            CommonEvaluators.doubleCostEvaluator cost_property.to_s
          end
        elsif cost_default
          CommonEvaluators.doubleCostEvaluator ' not a property ', cost_default.to_f
        else
          fail Pacer::LogicError, "could not build cost"
        end
      end

      def build_estimate
        if estimate.is_a? Proc
          BlockEstimateEvaluator.new estimate, graph, estimate_default
        elsif estimate
          estimate
        elsif lat_property and long_property
          CommonEvaluators.geoEstimateEvaluator lat_property.to_s, long_property.to_s
        elsif estimate_default
          BlockEstimateEvaluator.new proc { estimate_default }, graph, estimate_default
        else
          fail Pacer::LogicError, "could not build estimate"
        end
      end
    end
  end
end
