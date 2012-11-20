module Pacer
  module Neo4j
    class BlueprintsGraph < com.tinkerpop.blueprints.impls.neo4j.Neo4jGraph
      attr_accessor :allow_auto_tx

      def transaction
        @allow_auto_tx = true
        yield
      ensure
        @allow_auto_tx = false
      end

      def autoStartTransaction
        if allow_auto_tx
          super
        else
          raise Pacer::TransactionError, "Can't mutate the graph outside a transaction block"
        end
      end
    end
  end
end
