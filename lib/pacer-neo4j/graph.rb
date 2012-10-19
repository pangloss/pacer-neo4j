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
        if size == :undefined
          lucene_auto_index(type).getCacheCapacity name
        else
          lucene_auto_index(type).setCacheCapacity name, size
        end
      end

      private

      def index_properties(type, filters)
        filters.properties.select { |k, v| key_indices(type).include?(k) and not v.nil? }
      end

      def build_query(type, filters)
        indexed = index_properties type, filters
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
            route = lucene query, element_type: element_type
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
