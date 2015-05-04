module Pacer
  module Neo4j2
    class Graph
      def lucene(query, opts = {})
        opts = { back: self, element_type: :vertex }.merge opts
        chain_route(opts.merge(query: query,
                               filter: :lucene,
                               index: choose_index(opts)))
      end

      private

      def choose_index(opts)
        read_transaction do
          et = opts[:element_type]
          idx = opts[:index]
          case idx
          when String, Symbol
            index(idx, et).index.raw_index
          when Pacer::Wrappers::IndexWrapper
            idx.index.raw_index
          when com.tinkerpop.blueprints.Index
            idx.raw_index
          else
            lucene_auto_index(et)
          end
        end
      end
    end
  end


  module Filter
    module LuceneFilter
      import org.neo4j.index.lucene.QueryContext

      attr_accessor :index, :query, :sort_by, :reverse_numeric, :sort_numeric, :sort_by_score, :top, :fast

      def count(max = nil)
        iter = query_result
        c = iter.count
        if c >= 0
          c
        elsif max
          iter.inject(0) do |n, _|
            if n == max
              return :max
            else
              n + 1
            end
          end
        else
          iter.inject(0) { |n, _| n + 1 }
        end
      ensure
        iter.close
      end

      def sort_by_score!
        self.sort_by_score = true
        self
      end

      def sort(*keys)
        self.sort_by = keys
        self
      end

      def top_hits(n)
        self.top = n
        self
      end

      def fast!
        self.fast = true
        self
      end

      protected

      def build_query
        qc = QueryContext.new(query)
        qc = qc.tradeCorrectnessForSpeed if fast
        qc = qc.top(top) if top
        if sort_by_score
          qc.sortByScore
        elsif sort_by
          qc.sort(*[*sort_by].map(&:to_s))
        elsif sort_numeric
          qc.sortNumeric(sort_numeric, false)
        elsif reverse_numeric
          qc.sortNumeric(reverse_numeric, true)
        else
          qc
        end
      end

      def query_result
        graph.read_transaction do
          index.query build_query
        end
      end

      def source_iterator
        pipe = Pacer::Neo4j2::RawVertexWrappingPipe.new graph
        pipe.setStarts query_result
        pipe.enablePath(true)
        pipe
      end

      def inspect_string
        graph.read_transaction do
          "#{ inspect_class_name }(#{ query }) ~ #{ query_result.count }"
        end
      end
    end
  end
end
