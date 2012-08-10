require 'yaml'

module Pacer
  Neo4jGraph = com.tinkerpop.blueprints.impls.neo4j.Neo4jGraph
  Neo4jElement = com.tinkerpop.blueprints.impls.neo4j.Neo4jElement

  # Add 'static methods' to the Pacer namespace.
  class << self
    # Return a graph for the given path. Will create a graph if none exists at
    # that location. (The graph is only created if data is actually added to it).
    #
    # If the graph is opened from a path, it will be registered to be closed by
    # Ruby's at_exit callback, but if an already open graph is given, it will
    # not.
    #
    # Please note that Pacer turns on Neo4j's checkElementsInTransaction
    # feature by default. For some sort of performance improvement at
    # the expense of an odd consistency model within transactions that
    # require considerable more complexity in client code, you can use
    # `graph.setCheckElementsInTransaction(false)` to disable the
    # feature.
    def neo4j(path_or_graph, args = nil)
      if path_or_graph.is_a? String
        path = File.expand_path(path_or_graph)
        graph = Pacer.starting_graph(self, path) do
          if args
            Neo4jGraph.new(path, args.to_hash_map)
          else
            Neo4jGraph.new(path)
          end
        end
        graph.setCheckElementsInTransaction true
        graph
      else
        # Don't register the new graph so that it won't be automatically closed.
        Neo4jGraph.new(path_or_graph)
      end
    end
  end


  # Extend the java class imported from blueprints.
  class Neo4jGraph
    include GraphMixin
    include GraphIndicesMixin
    include GraphTransactionsMixin
    include Pacer::Core::Route
    include Pacer::Core::Graph::GraphRoute
    include Pacer::Core::Graph::GraphIndexRoute

    def element_class
      Neo4jElement
    end

    def vertex_class
      Neo4jVertex
    end

    def edge_class
      Neo4jEdge
    end

    def sanitize_properties(props)
      pairs = props.map do |name, value|
        [name, encode_property(value)]
      end
      Hash[pairs]
    end

    def encode_property(value)
      case value
      when nil
        nil
      when String
        value = value.strip
        value = nil if value == ''
        value
      when Numeric
        if value.is_a? Bignum
          value.to_yaml
        else
          value
        end
      when true, false
        value
      when Array
        if value.length == 0
          value_type = Fixnum
        else
          value_type = value.first.class
          value_type = TrueClass if value_type == FalseClass
          value.each do |v|
            if value_type != v.class or (value == true or value == false and value_type == TrueClass)
              value_type = nil
              break
            end
          end
        end
        case value_type
        when Fixnum
          value.to_java :long
        when Float
          value.to_java :double
        when TrueClass
          value.to_java :boolean
        when String
          value.to_java :string
        else
          value.to_yaml
        end
      else
        value.to_yaml
      end
    end

    if 'x'.to_yaml[0, 5] == '%YAML'
      def decode_property(value)
        if value.is_a? String and value[0, 5] == '%YAML'
          YAML.load(value)
        elsif value.is_a? ArrayJavaProxy
          value.to_a
        else
          value
        end
      end
    else
      def decode_property(value)
        if value.is_a? String and value[0, 3] == '---'
          YAML.load(value)
        elsif value.is_a? ArrayJavaProxy
          value.to_a
        else
          value
        end
      end
    end
  end
end
