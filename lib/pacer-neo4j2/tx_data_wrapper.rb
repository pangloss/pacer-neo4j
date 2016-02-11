module Pacer
  module Neo4j2
    # Uses the interface defined here:
    # http://api.neo4j.org/1.8/org/neo4j/graphdb/Path.html
    #
    # Note that I have removed methods that I didn't understand, assuming they are internal.
    class TxDataWrapper
      include Algo::Wrapping

      attr_reader :graph, :tx, :type_property

      def initialize(tx, graph, type_property)
        @tx = tx
        @graph = graph
        @type_property = type_property
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
        if type_property
          tx.createdNodes.map do |n|
            if n.hasProperty(type_property)
              type = n.getProperty(type_property)
            end
            [n.getId, type]
          end
        else
          tx.createdNodes.map { |n| [n.getId] }
        end
      end

      def deleted_v_ids
        tx.deletedNodes.map { |n| n.getId }
      end

      def created_e_ids
        tx.createdRelationships.map { |n| [n.getId, n.getType.name, n.getStartNode.getId, n.getEndNode.getId] }
      end

      def deleted_e_ids
        tx.deletedRelationships.map { |n| n.getId }
      end

      def deleted?(e)
        tx.is_deleted e.element.rawElement
      end

      def assigned_v
        tx.assignedNodeProperties.map do |p|
          [p.entity.getId, p.key, graph.decode_property(p.value)]
        end
      end

      def cleared_v
        tx.removedNodeProperties.map do |p|
          [p.entity.getId, p.key]
        end
      end

      def assigned_e
        tx.assignedRelationshipProperties.map do |p|
          [p.entity.getId, p.key, graph.decode_property(p.value)]
        end
      end

      def cleared_e
        tx.removedRelationshipProperties.map do |p|
          [p.entity.getId, p.key]
        end
      end

      def each_v_change(&blk)
        assigned_v.each(&blk)
        cleared_v.each(&blk)
      end

      def each_e_change(&blk)
        assigned_e.each(&blk)
        cleared_e.each(&blk)
      end

      def summary
        { created_v: created_v_ids,
          deleted_v: deleted_v_ids,
          created_e: created_e_ids,
          deleted_e: deleted_e_ids,
          assigned_v: assigned_v,
          cleared_v: cleared_v,
          assigned_e: assigned_e,
          cleared_e: cleared_e }
      end

      def data
        TxCachedData.new summary
      end

      def as_json(options = nil)
        data.as_json(options)
      end
    end

    class TxCachedData
      attr_reader :summary

      def initialize(summary)
        @summary = summary
      end

      def created_v_ids
        summary[:created_v]
      end

      def deleted_v_ids
        summary[:deleted_v]
      end

      def created_e_ids
        summary[:created_e]
      end

      def deleted_e_ids
        summary[:deleted_e]
      end

      def assigned_v
        summary[:assigned_v]
      end

      def cleared_v
        summary[:cleared_v]
      end

      def assigned_e
        summary[:assigned_e]
      end

      def cleared_e
        summary[:cleared_e]
      end

      def each_v_change(&blk)
        assigned_v.each(&blk)
        cleared_v.each(&blk)
      end

      def each_e_change(&blk)
        assigned_e.each(&blk)
        cleared_e.each(&blk)
      end

      def as_json(options = nil)
        summary.as_json(options)
      end
    end
  end
end
