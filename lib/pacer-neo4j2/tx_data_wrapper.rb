module Pacer
  module Neo4j2
    # Uses the interface defined here:
    # http://api.neo4j.org/1.8/org/neo4j/graphdb/Path.html
    #
    # Note that I have removed methods that I didn't understand, assuming they are internal.
    class TxDataWrapper
      include Algo::Wrapping

      attr_reader :graph, :tx

      def initialize(tx, graph)
        @tx = tx
        @graph = graph
      end

      def created_v
        tx.createdNodes.map { |n| wrap_vertex n }
      end

      def deleted_v
        tx.deletedNodes.map { |n| wrap_vertex n }
      end

      def created_e
        tx.createdRelationships.map { |n| wrap_edge n }
      end

      def deleted_e
        tx.deletedRelationships.map { |n| wrap_edge n }
      end

      def created_v_ids
        tx.createdNodes.map { |n| n.getId }
      end

      def deleted_v_ids
        tx.deletedNodes.map { |n| n.getId }
      end

      def created_e_ids
        tx.createdRelationships.map { |n| n.getId }
      end

      def deleted_e_ids
        tx.deletedRelationships.map { |n| n.getId }
      end

      def deleted?(e)
        tx.is_deleted e.element.rawElement
      end

      def changed_v
        tx.assignedNodeProperties.map do |p|
          { element_type: :vertex,
            id: p.entity.getId,
            key: p.key,
            was: graph.decode_property(p.previouslyCommitedValue),
            is: graph.decode_property(p.value) }
        end +
        tx.removedNodeProperties.map do |p|
          { element_type: :vertex,
            id: p.entity.getId,
            key: p.key,
            was: graph.decode_property(p.previouslyCommitedValue),
            is: nil }
        end
      end

      def changed_e
        tx.assignedRelationshipProperties.map do |p|
          { element_type: :edge,
            id: p.entity.getId,
            key: p.key,
            was: graph.decode_property(p.previouslyCommitedValue),
            is: graph.decode_property(p.value) }
        end +
        tx.removedRelationshipProperties.map do |p|
          { element_type: :edge,
            id: p.entity.getId,
            key: p.key,
            was: graph.decode_property(p.previouslyCommitedValue),
            is: nil }
        end
      end

      def changes
        changed_v + changed_e
      end

      def summary
        { created_v: created_v_ids,
          deleted_v: deleted_v_ids,
          created_e: created_e_ids,
          deleted_e: deleted_e_ids,
          changed_v: changed_v,
          changed_e: changed_e }
      end
    end
  end
end
