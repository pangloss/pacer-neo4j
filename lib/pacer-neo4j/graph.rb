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

      attr_accessor :keep_deleted_vertex_stubs

      # This method accepts only an unwrapped Blueprints Vertex
      def remove_vertex(vertex)
        g = blueprints_graph
        if keep_deleted_vertex_stubs
          vertex.getPropertyKeys.each do |key|
            vertex.removeProperty(key)
          end
          vertex.getEdges(Pacer::Pipes::BOTH).each do |edge|
            g.removeEdge edge
          end
          vertex.setProperty '*deleted*', true
          nil
        else
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

      # When a Neo4J graph is restarted, the ids of any elements that were deleted
      # will be reused. Running this code immediately after starting the graph
      # prevents Neo4J from reusing those IDs.
      #
      # DEPRECATED: Set keep_deleted_vertex_stubs = true
      def prevent_id_reuse!
        {
          edges: prevent_edge_id_reuse!,
          vertices: prevent_vertex_id_reuse!
        }
      end

      # This works by simply creating IDs until the ID of a new element is greater than
      # either the max existing ID, or the min_new_id argument.
      #
      # DEPRECATED: Set keep_deleted_vertex_stubs = true
      def prevent_vertex_id_reuse!(min_new_id = nil)
        min_new_id ||= v.element_ids.max
        return unless min_new_id
        g = blueprints_graph
        n = 0
        transaction do |_, rollback|
          begin
            n += 1
            v = g.addVertex(nil)
          end while v.getId < min_new_id
          rollback.call
        end
        n
      end

      def prevent_edge_id_reuse!(min_new_id = nil)
        min_new_id ||= e.element_ids.max
        return unless min_new_id
        g = blueprints_graph
        n = 0
        transaction do |_, rollback|
          v1 = g.addVertex nil
          v2 = g.addVertex nil
          begin
            n += 1
            e = g.addEdge(nil, v1, v2, "temp")
          end while e.getId < min_new_id
          rollback.call
        end
        n
      end

      def neo_graph
        blueprints_graph.raw_graph
      end

      def transaction_event_handler
        unless @teh
          @teh = TransactionEventHandler.new(self, wrapper)
          neo_graph.registerTransactionEventHandler @teh
        end
        @teh
      end

      def before_commit(wrapper = nil, &block)
        return unless block
        wrapper = false if block.arity == 0
        transaction_event_handler.before_commit_wrapper = wrapper unless wrapper.nil?
        transaction_event_handler.before_commit = block
        nil
      end

      def on_commit(wrapper = nil, &block)
        return unless block
        wrapper = false if block.arity == 0
        transaction_event_handler.on_commit_wrapper = wrapper unless wrapper.nil?
        transaction_event_handler.on_commit = block
        nil
      end

      # This is actually only called if the commit fails and then it internally tries to
      # rollback. It seems that it's actually possible for it to fail to rollback here, too...
      #
      # An exception in before_commit can definitely trigger this.
      #
      # Regular rollbacks do not get seen by the transaction system and no callback happens.
      def on_commit_failed(wrapper = nil, &block)
        return unless block
        wrapper = false if block.arity == 0
        transaction_event_handler.on_commit_failed_wrapper = wrapper unless wrapper.nil?
        transaction_event_handler.on_commit_failed = block
        nil
      end

      def drop_handler(h)
        neo_graph.unregisterTransactionEventHandler h
      end

      # Creates a Blueprints key index without doing a rebuild.
      def create_key_index_fast(name, type = :vertex)
        raise "Invalid index type #{ type }" unless [:vertex, :edge].include? type
        keys = (key_indices(type) + [name.to_s]).to_a
        neo_settings = neo_graph.getNodeManager.getGraphProperties
        iz = neo_graph.index.getNodeAutoIndexer
        prop = ((type == :vertex) ? "Vertex:indexed_keys" : "Edge:indexed_keys")
        transaction do
          create_vertex.delete! # this forces Blueprints to actually start the transaction
          neo_settings.setProperty prop, keys.to_java(:string)
          keys.each do |key|
            iz.startAutoIndexingProperty key
          end
        end
      end


      private

      def index_properties(type, filters)
        filters.properties.select { |k, v| v and key_indices(type).include?(k) }
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
        empty = false
        indexed = index_properties type, filters
        q = if indexed.any?
              indexed.map do |k, v|
                k = k.to_s.gsub '/', '\\/'
                if v.is_a? Range
                  lucene_range(k, v)
                elsif v.class.name == 'RangeSet'
                  s = v.ranges.map { |r| lucene_range(k, r) }.join " OR "
                  "(#{s})"
                elsif v.is_a? Set
                  empty = true if v.empty?
                  lucene_set(k, v)
                else
                  "#{k}:#{lucene_value v}"
                end
              end.compact.join " AND "
            else
              nil
            end
        [empty, q]
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
          filters.graph = self
          filters.use_lookup!
          empty, query = build_query(element_type, filters)
          if query
            route = lucene query, element_type: element_type, extensions: filters.extensions, wrapper: filters.wrapper
            filters.remove_property_keys key_indices(element_type)
            if filters.any?
              route = Pacer::Route.property_filter(route, filters, block)
            end
          elsif filters.route_modules.any?
            mod = filters.route_modules.shift
            route = Pacer::Route.property_filter(mod.route(self), filters, block)
          end
          if empty
            [].to_route based_on: route
          else
            route
          end
        end
      end
    end
  end
end
