module Pacer
  module Neo4j2
    class TransactionEventHandler
      include org.neo4j.graphdb.event.TransactionEventHandler

      attr_reader :graph
      attr_accessor :on_commit, :on_commit_failed, :before_commit

      def initialize(graph)
        @graph = graph
      end

      def unregister!
        graph.drop_handler self
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

      # This is actually only called if the commit fails and then it internally tries to
      # rollback. It seems that it's actually possible for it to fail to rollback here, too...
      #
      # An exception in beforeCommit can definitely trigger this.
      #
      # Regular rollbacks do not get seen by the transaction system and no callback happens.
      def afterRollback(data, ignore)
        on_commit_failed.call TxDataWrapper.new data, graph if on_commit_failed
      end
    end
  end
end
