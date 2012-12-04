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

      def after_initialize
        fail Pacer::ClientError, 'graph must be neo4j' unless graph.vendor == 'neo4j'
      end

      def help(opt = nil)
        case opt
when nil
  puts <<HELP
Finds paths between pairs of vertices. The algorithm used depends on the
options specified. All supported path finding algorithms including in Neo4j 1.8
are included, and all of their documented usages are possible.

USAGE:

vertices.path_to(targets, options = {})
    Find the first path from each vertex to each target vertex

vertices.paths_to(targets, options = {})
    Find multiple paths from each vertex to each target vertex

paths.expand(options = {})
    Find multiple paths from the first vertex in each path to the last vertex
    in each path.

All options are optional!

These methods only work on Neo4j graphs.

More details:

help :options      for simple path algorithms and other options
  find_all, cyclical, length, max_depth, max_hits

help :cost         for Dijkstra and aStar
  cost, cost_property, cost_default

help :estimate     for aStar
  estimate, estimate_default, lat_property, long_property

help :expansion    customize how any path is expanded
  in_labels, out_labels, both_labels, expander, forward, reverse

HELP
when :path
  puts <<HELP
Details for path:         expander: proc { |path, state| edges }

#end_v        Returns the end vertex of this path.
#start_v      Returns the start vertex of this path.
#length       Returns the length of this path.
#path         Iterates through both the vertices and edges of this path in
              order.
#end_e        Returns the last edge in this path.
#v            Returns all the vertices in this path starting from the start
              vertex going forward towards the end vertex.
#e            Returns all the edges in between the vertices which this path
              consists of.
#reverse_v    Like #v but reversed.
#reverse_e    Like #e but reversed.

The following methods all proxy to the vertex returned by #end_v: and behave
exactly like standard Pacer Vertex methods.

The iterators can be combined with the + operator.

Fast edge iterators:
  #out_edges(*args)
  #in_edges(*args)
  #both_edges(*args)

Fast vertex iterators:
  #out_vertices(*args)
  #in_vertices(*args)
  #both_vertices(*args)

Edge routes:
  #out_e(*args)
  #in_e(*args)
  #both_e(*args)

Vertex routes:
  #out(*args)
  #in(*args)
  #both(*args)

HELP
when :expansion
  puts <<HELP
Path expansion options:

  By default, all edges will be followed. By specifying expansion rules you can
  limit which paths are attempted. All algorithms use the same expanders so
  these options do not effect the algorithm selection.

  in_labels: label | [labels]    only follow : in edges  : with the given label(s)
  out_labels:                                : out edges :
  both_labels:                               : edges     :
      These options can be combined.

  Expanders search forward from the start vertex and backwards from the target
  vertex. Either expander

  expander: Proc | PathExpander   Custom rule for forward search
      If no reverse is specified, will be used for reverse too.
  forward:                        synonym for the expander option
  reverse:  Proc | PathExpander   Custom rule for the reverse search

      proc { |path, state| edges }:
        path is a Pacer::Neo4j::Algo::PathWrapper - help(:path) for details
        The proc must simply return an Enumerable of edges that the

HELP
when :options
  puts <<HELP
Simple options:

  find_all: Boolean    Find all non-cyclical paths.
      Algorithm: allSimplePaths

  cyclical: Boolean    Find all paths including cyclical ones.
      Algorithm: allPaths

  length: Number       Number of edges that the path contains.
      Algorithm: pathsWithLength
      Returns only paths of the specified length.

  max_depth: Number    Number of edges to search in a potential path.
      Default: 5
      Limits how many edges will be traversed searching for a path. Higher
      numbers can take exponentially longer, I think.  Does not apply to aStar,
      Dijkstra, or pathsWithLength algorithms.

      Required for find_all, cyclical, and shortest path algorithms.

  max_hits: Number     Maximum number of paths to find for each pair of vertices.
      #path_to defaults this to 1. All algorithms use this but only
      some support it natively in Neo4j's implementations.


HELP
when :cost
  puts <<HELP
Cost options:

  Specifying these chooses the Dijkstra algorithm unless an estimate is also
  specified.

  cost: Proc | CostEvaluator   Calculate the cost for this edge.
      Must return a Numeric unless cost_default is set.
      proc { |edge, direction| Float }:
        direction is either :in or :out.

  cost_property: String        get the cost from the given edge property
  cost_default: Float          default if the property isn't there

HELP
when :estimate
  puts <<HELP
Estimate options
  Specifying these together with cost chooses the a* / aStar algorithm.

  estimate:
      Must return a Numeric unless estimate_default is set.
      proc { |vertex, goal_vertex| Float }

  estimate_default: Float   only works with the proc estimate

  lat_property: String      latitude property name
  long_property: String     longitude property name
      Use latitude and longitude if all estimated vertices have the necessary
      properties.

HELP
else
  super
end
        description
      end

      def method
        if has_cost?
          if has_estimate?
            :aStar
          else
            :dijkstra
          end
        elsif cyclical and max_depth
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

      attr_accessor :target

      # specify one or many edge labels that the path may take in the given direction
      attr_accessor :in_labels, :out_labels, :both_labels

      # note that expander procs *must* return edge(s) that are connected to the end_v of the given path
      #
      # expander yields: { |path, state| path.is_a? Pacer::Neo4j::Algo::PathWrapper }
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
      attr_accessor :find_all
      attr_accessor :cyclical

      protected

      def attach_pipe(end_pipe)
        if back and back.element_type == :path
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
        if back and back.element_type == :path
          "expand[#{method}](max_depth: #{ max_depth })"
        else
          "paths_to[#{method}](#{ target.inspect }, max_depth: #{ max_depth })"
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
