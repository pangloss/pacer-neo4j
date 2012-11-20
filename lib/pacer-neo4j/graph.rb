module Pacer
  module Neo4j
    class Graph < PacerGraph
      # I'm not sure exactly what this impacts but if it is false, many Pacer tests fail.
      #
      # Presumably Neo4j is faster with it set to false.
      def safe_transactions=(b)
        blueprints_graph.setCheckElementsInTransaction b
      end

      def safe_transactions
        blueprints_graph.getCheckElementsInTransaction
      end

      def key_index_cache(type, name, size = :undefined)
        indexer = lucene_auto_index(type)
        if size == :undefined
          indexer.getCacheCapacity name
        else
          indexer.setCacheCapacity name, size
        end
      end

      def neo_graph
        blueprints_graph.raw_graph
      end

      def on_commit(&block)
        return unless block
        TransactionEventHandler.new(self).tap do |h|
          h.on_commit = block
          neo_graph.registerTransactionEventHandler h
        end
      end

      def on_rollback(&block)
        return unless block
        TransactionEventHandler.new(self).tap do |h|
          h.on_rollback = block
          neo_graph.registerTransactionEventHandler h
        end
      end

      def before_commit(&block)
        return unless block
        TransactionEventHandler.new(self).tap do |h|
          h.before_commit = block
          neo_graph.registerTransactionEventHandler h
        end
      end

      def drop_handler(h)
        neo_graph.unregisterTransactionEventHandler h
      end

      private

      def index_properties(type, filters)
        filters.properties.select { |k, v| key_indices(type).include?(k) and not v.nil? }
      end

      def build_query(type, filters)
        indexed = index_properties type, filters
        if indexed.any?
          indexed.map do |k, v|
            k = k.to_s.gsub '/', '\\/'
            if v.is_a? Numeric
              "#{k}:#{v}"
            else
              s = encode_property(v)
              if s.is_a? String and s =~ /[\t :"']/
                %{#{k}:#{s.inspect}}
              else
                "#{k}:#{s}"
              end
            end
          end.join " AND "
        else
          nil
        end
      end

      def lucene_auto_index(type)
        if type == :vertex
          indexer = neo_graph.index.getNodeAutoIndexer
        elsif type == :edge
          indexer = neo_graph.index.getRelationshipAutoIndexer
        end
        indexer.getAutoIndex
      end

      def indexed_route(element_type, filters, block)
        if search_manual_indices
          super
        else
          query = build_query(element_type, filters)
          if query
            route = lucene query, element_type: element_type, extensions: filters.extensions, wrapper: filters.wrapper
            filters.remove_property_keys key_indices(element_type)
            if filters.any?
              Pacer::Route.property_filter(route, filters, block)
            else
              route
            end
          elsif filters.route_modules.any?
            mod = filters.route_modules.shift
            Pacer::Route.property_filter(mod.route(self), filters, block)
          end
        end
      end
    end
  end
end
