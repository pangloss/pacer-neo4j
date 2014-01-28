module Pacer
  module Neo4j
    class BlueprintsGraph < com.tinkerpop.blueprints.impls.neo4j2.Neo4j2Graph
      attr_accessor :allow_auto_tx

      # Threadlocal tx_depth is set in Pacer's graph_transaction_mixin.rb
      def tx_depth
        graphs = Thread.current[:graphs] ||= {}
        tgi = graphs[object_id] ||= {}
        tgi[:tx_depth] || 0
      end

      def autoStartTransaction
        if allow_auto_tx or tx_depth != 0
          super
        else
          raise Pacer::TransactionError, "Can't mutate the graph outside a transaction block"
        end
      end
    end
  end
end
