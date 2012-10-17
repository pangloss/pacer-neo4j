module Pacer
  module Core::Graph::VerticesRoute
    def path_to(to_v, opts = {})
      chain_route({transform: :path_finder, element_type: :path, target: to_v}.merge opts)
    end
    def paths_to(to_v, opts = { find_all: true })
      chain_route({transform: :path_finder, element_type: :path, target: to_v}.merge opts)
    end
  end

  module Transform
    module PathFinder
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
      attr_writer :max_depth
      def max_depth
        @max_depth || 5
      end

      # use shortestPath
      attr_accessor :max_hit_count

      # Possible values:
      # true    - allPaths
      # :simple - allSimplePaths
      attr_accessor :find_all

      protected

      def attach_pipe(end_pipe)
        p = Pipe.new build_algo, graph, target
        p.setStarts end_pipe
        p
      end

      def inspect_string
        "paths_to[#{method}](#{ target.inspect }, max_depth: #{ max_depth })"
      end

      def method
        if has_cost?
          if has_estimate?
            :aStar
          else
            :dijkstra
          end
        elsif length
          :with_length
        elsif find_all == :all and max_depth
          :all
        elsif find_all and max_depth
          :all_simple
        elsif max_depth
          if max_hit_count
            :shortest_with_max_hits
          else
            :shortest
          end
        end
      end

      private

      def has_cost?
        cost_evaluator or cost_property or cost_block
      end

      def has_estimate?
        estimate_evaluator or (lat_property and long_property) or estimate_block
      end

      def build_algo
        case method
        when :aStar
          GraphAlgoFactory.aStar expander, build_cost, build_estimate
        when :dijkstra
          GraphAlgoFactory.dijkstra expander, build_cost
        when :with_length
          GraphAlgoFactory.pathsWithLength expander, length
        when :all_paths
          GraphAlgoFactory.allPaths expander, max_depth
        when :simple_paths
          GraphAlgoFactory.allSimplePaths expander, max_depth
        when :shortest_with_max_hits
          GraphAlgoFactory.shortestPath expander, max_depth, max_hit_count
        when :shortest
          GraphAlgoFactory.shortestPath expander, max_depth
        when nil
          fail Pacer::ClientError, "Could not choose a path algorithm"
        else
          fail Pacer::LogicError, "Unable to build algo for #{ method }"
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
        import org.neo4j.graphdb::Node
        import org.neo4j.graphdb::Relationship
        import com.tinkerpop.blueprints.impls.neo4j.Neo4jVertex
        import com.tinkerpop.blueprints.impls.neo4j.Neo4jEdge

        attr_reader :algo, :target, :graph
        attr_accessor :current_paths

        def initialize(algo, graph, target)
          super()
          @algo = algo
          @graph = graph.blueprints_graph
          @target = target.element.raw_element
        end

        def processNextStart
          next_raw_path.map do |e|
            if e.is_a? Node
              Neo4jVertex.new e, graph
            elsif e.is_a? Relationship
              Neo4jEdge.new e, graph
            else
              e
            end
          end
        end

        def next_raw_path
          loop do
            if current_paths
              if current_paths.hasNext
                return current_paths.next
              else
                self.current_paths = nil
              end
            else
              self.current_paths = @algo.findAllPaths(next_raw, target).iterator
            end
          end
        end

        def next_raw
          c = starts.next
          if c.respond_to? :element
            c.element.raw_element
          else
            c.raw_element
          end
        end
      end
    end
  end
end
