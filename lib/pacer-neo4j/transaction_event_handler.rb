module Pacer
  module Neo4j
    class TransactionEventHandler
      include org.neo4j.graphdb.event.TransactionEventHandler

      attr_reader :graph, :enable_cache
      attr_accessor :on_commit         , :on_commit_failed         , :before_commit
      attr_accessor :on_commit_wrapper , :on_commit_failed_wrapper , :before_commit_wrapper
      attr_accessor :type_property

      def initialize(graph)
        @graph = graph
        @on_commit_wrapper = @on_commit_failed_wrapper = @before_commit_wrapper = TxDataWrapper
      end

      def unregister!
        graph.drop_handler self
      end

      def enable_cache!
        @enable_cache = true
      end

      private

      # Return value is passed to afterCommit or afterRollback, but some values can cause crashes.
      def beforeCommit(data)
        if before_commit_wrapper and (before_commit or enable_cache)
          wrapped = before_commit_wrapper.new data, graph, type_property
        end
        if before_commit
          if before_commit_wrapper
            before_commit.call wrapped
          else
            before_commit.call
          end
        end
        if enable_cache
          wrapped.data
        end
      rescue Exception => e
        p e.message
        pp e.backtrace
        throw
      end

      def afterCommit(data, cache)
        if on_commit
          if cache
            on_commit.call cache
          elsif on_commit_wrapper
            on_commit.call on_commit_wrapper.new data, graph
          else
            on_commit.call
          end
        end
      rescue Exception => e
        p e.message
        pp e.backtrace
        throw
      end

      # This is actually only called if the commit fails and then it internally tries to
      # rollback. It seems that it's actually possible for it to fail to rollback here, too...
      #
      # An exception in beforeCommit can definitely trigger this.
      #
      # Regular rollbacks do not get seen by the transaction system and no callback happens.
      def afterRollback(data, cache)
        if on_commit_failed
          if cache
            on_commit_failed.call cache
          elsif on_commit_failed_wrapper
            on_commit_failed.call on_commit_failed_wrapper.new data, graph
          else
            on_commit_failed.call
          end
        end
      rescue Exception => e
        p e.message
        pp e.backtrace
        throw
      end
    end
  end
end
