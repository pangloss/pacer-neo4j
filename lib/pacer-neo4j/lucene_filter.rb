module Pacer
  module Filter
    module LuceneFilter
      attr_accessor :index, :query

      def count(max = nil)
        iter = result
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

      protected

      def result
        index.query query
      end

      def source_iterator
        pipe = Pacer::Neo4j::RawVertexWrappingPipe.new graph
        pipe.setStarts result
        pipe
      end

      def inspect_string
        "#{ inspect_class_name }(#{ query }) ~ #{ result.count }"
      end
    end
  end
end
