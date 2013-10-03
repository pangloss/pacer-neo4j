module Pacer::Neo4j

  # TODO: rewrite in Java
  class NeoPropertyComparator
    include java.util.Comparator

    attr_reader :property

    def initialize(prop)
      @property = prop
    end

    def compare(a, b)
      if a.hasProperty(property) and b.hasProperty(property)
        a = a.getProperty(property)
        b = b.getProperty(property)
        if a == b
          0
        elsif a > b
          1
        else
          -1
        end
      elsif a.hasProperty(property)
        1
      elsif b.hasProperty(property)
        -1
      else
        0
      end
    end
  end

  module Collections
    BaseSortedTree = org.neo4j.collections.sortedtree.SortedTree

    # Instantiate this using either
    # `graph.create_sorted_tree_vertex(key)` or
    # `graph.create_unique_sorted_tree_vertex(key)`
    #
    # Creates a sorted data structure similar to a cons list.
    #
    # O(n) insert and retrieval.
    class SortedTree < BaseSortedTree
      REL_TYPES = BaseSortedTree::RelTypes
      import org.neo4j.graphdb.Direction
      include Pacer::Neo4j::Algo::Wrapping

      attr_reader :graph

      def root_rel(n)
        n.getSingleRelationship REL_TYPES::TREE_ROOT, Direction::OUTGOING
      end

      def initialize(node_or_graph, sort_key = nil, unique = nil)
        if node_or_graph.is_a? Pacer::Vertex
          base_node = node_or_graph.element.rawElement
          rel = root_rel(base_node)
          comp = NeoPropertyComparator.new(rel.getProperty("sort_key"))
          super base_node, comp
          @graph = node_or_graph.graph
        elsif node_or_graph.is_a? Array
          base_node = node_or_graph[0].rawElement
          rel = root_rel(base_node)
          comp = NeoPropertyComparator.new(rel.getProperty("sort_key"))
          super base_node, comp
          @graph = node_or_graph[1]
        elsif node_or_graph.is_a? Pacer::Neo4j::Graph
          neo = node_or_graph.neo_graph
          tx = neo.beginTx
          super(neo, NeoPropertyComparator.new(sort_key), unique, sort_key)
          @graph = node_or_graph
          rel = root_rel(baseNode)
          rel.setProperty("sort_key", sort_key)
          rel.removeProperty("comparator_class")
          tx.success if tx
        end
      end

      def base_node(modules, wrapper = nil)
        vertex = wrap_vertex(baseNode)
        modules += [Pacer::Neo4j::SortedTree]
        if wrapper
          vertex = wrapper.new self, vertex.element
        else
          vertex = vertex.add_extensions modules
        end
        vertex
      end

      def insert(v)
        addNode v.element.rawElement
      end
      alias add_node insert

      def leaves(*exts)
        to_route.map(graph: graph, element_type: :vertex, extensions: exts) { |n| neo_vertex n }
      end
    end
  end

  module SortedTree
    def self.route(r)
      r.v.lookahead { |v| v.out_e(:TREE_ROOT) }
    end

    module Graph
      def create_unique_sorted_tree_vertex(key, *args)
        t = Pacer::Neo4j::Collections::SortedTree.new self, key.to_s, true
        _, wrapper, modules, props = id_modules_properties(args)
        vertex = t.base_node(modules, wrapper)
        props.each { |k, v| vertex[k.to_s] = v } if props
        vertex
      end

      def create_sorted_tree_vertex(key, *args)
        id, wrapper, modules, props = id_modules_properties(args)
        t = Pacer::Neo4j::Collections::SortedTree.new self, key.to_s, false
        _, wrapper, modules, props = id_modules_properties(args)
        vertex = t.base_node(modules, wrapper)
        props.each { |k, v| vertex[k.to_s] = v } if props
        vertex
      end
    end

    module Vertex
      include Pacer::Neo4j::Algo::Wrapping

      def sorted_tree_impl
        @sorted_tree ||= Pacer::Neo4j::Collections::SortedTree.new self
      end

      def leaves(*exts)
        sorted_tree_impl.leaves(*exts)
      end

      def insert(v)
        sorted_tree_impl.insert v
      end
    end

    module Route
      def leaves(*exts)
        chain_route(pipe_class: Pipe, pipe_args: [graph], wrapper: nil, extensions: exts, route_name: 'leaves')
      end

      class Pipe < Pacer::Pipes::RubyPipe
        attr_reader :graph
        attr_accessor :leaves

        def initialize(graph)
          super()
          @graph = graph
        end

        def processNextStart()
          while true
            if leaves
              begin
                return leaves.next
              rescue StopIteration
                self.leaves = nil
              end
            else
              t = Pacer::Neo4j::Collections::SortedTree.new [starts.next, graph]
              self.leaves = t.each.map { |v| neo_vertex v }
            end
          end
        end
      end
    end
  end

  class Graph
    include SortedTree::Graph
  end
end

