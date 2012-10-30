module Pacer
  module Core
    module StringRoute
      def raw_cypher(opts = {})
        chain_route({element_type: :cypher, transform: Pacer::Transform::Cypher}.merge opts)
      end

      def cypher(opts = {})
        raw_cypher.paths(opts)
      end
    end

    module Graph
      module VerticesRoute
        def raw_cypher(query, elements_per_query = nil)
          reducer(element_type: :array).
            enter { [] }.
            leave { |x, a| x.nil? or (elements_per_query and a.length % elements_per_query == 0) }.
            reduce { |v, ids| ids << v.element_id }.
          map(element_type: :string) { |a| "start v=node(#{a.join(',')}) #{ query }"}.
          raw_cypher
        end

        def cypher(query, elements_per_query = nil)
          raw_cypher(query, elements_per_query).paths
        end
      end
    end

    module CypherRoute
      def paths(*columns)
        chain_route element_type: :path, transform: Pacer::Transform::CypherResults, columns: columns
      end

      def v(column = nil)
        chain_route element_type: :vertex, transform: Pacer::Transform::CypherResults, columns: [column].compact, single: true
      end

      def e(column = nil)
        chain_route element_type: :edge, transform: Pacer::Transform::CypherResults, columns: [column].compact, single: true
      end

      def results(*columns)
        chain_route element_type: :array, transform: Pacer::Transform::CypherResults, columns: columns
      end
    end
    Pacer::RouteBuilder.current.element_types[:cypher] = [CypherRoute]
  end

  module Transform
    module Cypher
      protected

      def attach_pipe(end_pipe)
        pipe = CypherPipe.new(self)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      class CypherPipe < Pacer::Pipes::RubyPipe
        import org.neo4j.cypher.javacompat.ExecutionEngine

        attr_reader :engine

        def initialize(route)
          super()
          graph = route.graph.neo_graph
          @engine = ExecutionEngine.new graph
        end

        protected

        def processNextStart
          engine.execute starts.next
        end
      end
    end

    module CypherResults
      attr_accessor :columns, :single

      protected

      def attach_pipe(end_pipe)
        pipe = ResultsPipe.new(self, columns, single)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      class ResultsPipe < Pacer::Pipes::RubyPipe
        import org.neo4j.cypher.javacompat.ExecutionEngine

        include Pacer::Neo4j::Algo::Wrapping

        attr_reader :columns, :graph, :single
        attr_accessor :current

        def initialize(route, columns, single)
          super()
          @single = single
          @graph = route.graph
          @columns = columns if columns and columns.any?
        end

        protected

        def processNextStart
          while true
            if current
              if current.first.hasNext
                if single
                  return wrap_path(current.map(&:next)).first
                else
                  return wrap_path current.map(&:next)
                end
              else
                self.current = nil
              end
            else
              results = starts.next
              cols = columns || results.columns.to_a
              self.current = cols.map { |col| results.columnAs col }
            end
          end
        end
      end
    end
  end
end
