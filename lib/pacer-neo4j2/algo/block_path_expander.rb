module Pacer
  module Neo4j2
    module Algo
      class BlockPathExpander
        import org.neo4j.graphdb.PathExpander
        import com.tinkerpop.pipes.Pipe

        include PathExpander
        attr_reader :block, :rev, :graph, :max_depth

        def initialize(block, rev, graph, max_depth)
          @block = block
          @rev = rev
          @graph = graph
          @max_depth = max_depth
        end

        def expand(path, state)
          path = PathWrapper.new(path, graph)
          if max_depth and path.length >= max_depth
            result = []
          else
            result = block.call path, state
          end
          pipe = Pacer::Pipes::NakedPipe.new
          pipe.set_starts result_to_enumerable(result)
          pipe
        end

        def reverse
          BlockPathExpander.new rev, block, graph, max_depth
        end

        def result_to_enumerable(result)
          case result
          when PathWrapper
            fail "Don't just return the arguments in your expander, return edges!"
          when Pacer::Route
            if result.element_type == :edge
              result.pipe.starts
            else
              fail "Expander must return edges"
            end
          when Pacer::Wrappers::EdgeWrapper
            Pacer::Pipes::EnumerablePipe.new [result]
          when Pacer::Pipes::WrappingPipe
            result.starts
          when Pipe
            result
          when Enumerable
            Pacer::Pipes::EnumerablePipe.new result
          when nil
            Pacer::Pipes::EnumerablePipe.new []
          else
            fail "Can't figure out what to do with #{ result.class }"
          end
        end
      end
    end
  end
end
