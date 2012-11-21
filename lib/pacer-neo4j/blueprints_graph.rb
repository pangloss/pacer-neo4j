module Pacer
  module Neo4j
    class BlueprintsGraph < com.tinkerpop.blueprints.impls.neo4j.Neo4jGraph
      attr_accessor :allow_auto_tx
      attr_reader :tx_depth

      def initialize(*args)
        super
        @tx_depth = 0
      end

      def transaction
        @tx_depth += 1
        yield
      ensure
        @tx_depth -= 1
      end

      def autoStartTransaction
        if tx_depth != 0 or allow_auto_tx
          super
        else
          raise Pacer::TransactionError, "Can't mutate the graph outside a transaction block"
        end
      end
    end
  end
end
