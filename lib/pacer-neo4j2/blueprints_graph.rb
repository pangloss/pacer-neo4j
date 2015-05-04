module Pacer
  module Neo4j2
    import com.tinkerpop.blueprints.impls.neo4j2.Neo4j2Graph
    import com.tinkerpop.blueprints.impls.neo4j2.Neo4j2HaGraph

    module TxDepth
      attr_accessor :allow_auto_tx, :allow_auto_read_tx

      # Threadlocal tx_depth is set in Pacer's graph_transaction_mixin.rb
      def tx_depth
        graphs = Thread.current[:graphs] ||= {}
        tgi = graphs[object_id] ||= {}
        tgi[:tx_depth] || 0
      end

      # Threadlocal read_tx_depth is set in Pacer's graph_transaction_mixin.rb
      def read_tx_depth
        graphs = Thread.current[:graphs] ||= {}
        tgi = graphs[object_id] ||= {}
        depth = tgi[:read_tx_depth] || 0
        if depth == 0
          tgi[:tx_depth] || 0 # Reads are allowed in any type of tx.
        else
          depth
        end
      end
    end


    class BlueprintsGraph < Neo4j2Graph
      include TxDepth

      def autoStartTransaction(for_write)
        if for_write
          if allow_auto_tx or tx_depth != 0
            super
          else
            raise Pacer::TransactionError, "Can't mutate the graph outside a transaction block"
          end
        else
          if allow_auto_read_tx or read_tx_depth != 0
            super
          else
            raise Pacer::TransactionError, "Can't read the graph outside a transaction or read_transaction block"
          end
        end
      end
    end


    class BlueprintsHaGraph < Neo4j2HaGraph
      include TxDepth

      def autoStartTransaction(for_write)
        if for_write
          if allow_auto_tx or tx_depth != 0
            super
          else
            raise Pacer::TransactionError, "Can't mutate the graph outside a transaction block"
          end
        else
          if allow_auto_read_tx or read_tx_depth != 0
            super
          else
            raise Pacer::TransactionError, "Can't read the graph outside a transaction or read_transaction block"
          end
        end
      end
    end
  end
end
