module Pacer

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
      neo = com.tinkerpop.blueprints.impls.neo4j.Neo4jGraph
      if path_or_graph.is_a? String
        path = File.expand_path(path_or_graph)
        open = proc do
          graph = Pacer.open_graphs[path]
          unless graph
            if args
              graph = neo.new(path, args.to_hash_map)
            else
              graph = neo.new(path)
            end
            Pacer.open_graphs[path] = graph
            graph.setCheckElementsInTransaction true
          end
          graph
        end
        shutdown = proc do |g|
          g.blueprints_graph.shutdown
          Pacer.open_graphs.delete path
        end
        Neo4j::Graph.new(Pacer::YamlEncoder, open, shutdown)
      else
        # Don't register the new graph so that it won't be automatically closed.
        Neo4j::Graph.new Pacer::YamlEncoder, proc { neo.new(path_or_graph) }
      end
    end
  end

  module Neo4j

    class Graph < PacerGraph
      private

      def build_query(type, filters)
        indexed = filters.properties.select { |k, v| key_indices(type).include? k }
        if indexed.any?
          indexed.map do |k, v|
            if v.is_a? Numeric
              "#{k}:#{v}"
            else
              s = encode_property(v)
              if s.is_a? String and s =~ /\s/
                %{#{k}:"#{s}"}
              else
                "#{k}:#{s}"
              end
            end
          end.join " AND "
        else
          nil
        end
      end

      def neo_graph
        blueprints_graph.raw_graph
      end

      def lucene_auto_index(type)
        if type == :vertex
          neo_graph.index.getNodeAutoIndexer.getIndexInternal
        elsif type == :edge
          neo_graph.index.getRelationshipAutoIndexer.getIndexInternal
        end
      end

      def indexed_route(element_type, filters, block)
        if search_manual_indices
          super
        else
          query = build_query(element_type, filters)
          if query
            route = chain_route back: self, element_type: element_type,
              filter: :lucene, index: lucene_auto_index(element_type), query: query
          elsif filters.route_modules.any?
            mod = filters.route_modules.shift
            Pacer::Route.property_filter(mod.route(self), filters, block)
          end
        end
      end
    end
  end
end
