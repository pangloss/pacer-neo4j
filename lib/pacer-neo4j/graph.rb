require 'set'

module Pacer
  module Neo4j
    class Graph < PacerGraph
      JDate = java.util.Date
      import java.text.SimpleDateFormat

      # I'm not sure exactly what this impacts but if it is false, many Pacer tests fail.
      #
      # Presumably Neo4j is faster with it set to false.
      def safe_transactions=(b)
        blueprints_graph.setCheckElementsInTransaction b
      end

      def safe_transactions
        blueprints_graph.getCheckElementsInTransaction
      end

      def allow_auto_tx=(b)
        blueprints_graph.allow_auto_tx = b
      end

      def allow_auto_tx
        blueprints_graph.allow_auto_tx
      end

      def transaction(*args, &block)
        blueprints_graph.transaction do
          super
        end
      end

      def cypher(query)
        [query].to_route(element_type: :string, graph: self).cypher
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

      # This is actually only called if the commit fails and then it internally tries to
      # rollback. It seems that it's actually possible for it to fail to rollback here, too...
      #
      # An exception in before_commit can definitely trigger this.
      #
      # Regular rollbacks do not get seen by the transaction system and no callback happens.
      def on_commit_failed(&block)
        return unless block
        TransactionEventHandler.new(self).tap do |h|
          h.on_commit_failed = block
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

      def lucene_set(k, v)
        statements = v.map { |x| "#{k}:#{lucene_value(x)}" }
        "(#{ statements.join(' OR ') })"
      end

      def lucene_range(k, v)
        if v.min and v.max
          encoded = encode_property(v.min)
          if encoded.is_a? JDate
            "#{k}:[#{lucene_value v.min} TO #{lucene_value v.max}]"
          else
            "#{k}:[#{lucene_value v.min} TO #{lucene_value v.max}]"
          end
        end
      end

      def build_query(type, filters)
        indexed = index_properties type, filters
        if indexed.any?
          indexed.map do |k, v|
            k = k.to_s.gsub '/', '\\/'
            if v.is_a? Range
              lucene_range(k, v)
            elsif v.class.name == 'RangeSet'
              s = v.ranges.map { |r| lucene_range(k, r) }.join " OR "
              "(#{s})"
            elsif v.is_a? Set
              lucene_set(k, v)
            else
              "#{k}:#{lucene_value v}"
            end
          end.compact.join " AND "
        else
          nil
        end
      end

      def lucene_value(v)
        s = encode_property(v)
        if s.is_a? JDate
          f = SimpleDateFormat.new 'yyyyMMddHHmmssSSS'
          f.format s
        elsif s
          if s.is_a? String
            s.inspect
          else s
            s
          end
        else
          'NULL'
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
