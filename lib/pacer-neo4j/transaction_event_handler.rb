module Pacer
  module Neo4j
    class TransactionEventHandler
      include org.neo4j.graphdb.event.TransactionEventHandler

      attr_reader :graph
      attr_accessor :on_commit, :on_rollback, :before_commit

      def initialize(graph)
        @graph = graph
      end

      private

      # Return value is passed to afterCommit or afterRollback, but some values can cause crashes.
      def beforeCommit(data)
        before_commit.call TxDataWrapper.new data, graph if before_commit
        nil
      end

      def afterCommit(data, ignore)
        on_commit.call TxDataWrapper.new data, graph if on_commit
      end

      def afterRollback(data, ignore)
        on_rollback.call TxDataWrapper.new data, graph if on_commit
      end
    end
  end
end
