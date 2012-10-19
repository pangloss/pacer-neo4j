module Pacer
  module Neo4j
    module Algo
      class PathPipe < Pacer::Pipes::RubyPipe
        import org.neo4j.graphdb::Node
        import org.neo4j.graphdb::Relationship
        import com.tinkerpop.blueprints.impls.neo4j.Neo4jVertex
        import com.tinkerpop.blueprints.impls.neo4j.Neo4jEdge

        attr_reader :algo, :target, :graph, :max_hits
        attr_accessor :current_paths, :hits

        def initialize(algo, graph, target, max_hits)
          super()
          @algo = algo
          @max_hits = max_hits || -1
          @graph = graph.blueprints_graph
          @target = target.element.raw_element
        end

        def processNextStart
          next_raw_path.map do |e|
            if e.is_a? Node
              Neo4jVertex.new e, graph
            elsif e.is_a? Relationship
              Neo4jEdge.new e, graph
            else
              e
            end
          end
        end

        def next_raw_path
          loop do
            if current_paths
              if hits == 0
                self.current_paths = nil
              elsif current_paths.hasNext
                self.hits -= 1
                return current_paths.next
              else
                self.current_paths = nil
              end
            else
              self.hits = max_hits
              self.current_paths = @algo.findAllPaths(next_raw, target).iterator
            end
          end
        end

        def next_raw
          element = starts.next
          if element.respond_to? :element
            element.element.raw_element
          else
            element.raw_element
          end
        end
      end
    end
  end
end
