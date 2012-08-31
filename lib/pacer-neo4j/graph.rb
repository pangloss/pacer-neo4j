require 'yaml'

module Pacer

  # Add 'static methods' to the Pacer namespace.
  class << self
    # Return a graph for the given path. Will create a graph if none exists at
    # that location. (The graph is only created if data is actually added to it).
    #
    # If the graph is opened from a path, it will be registered to be closed by
    # Ruby's at_exit callback, but if an already open graph is given, it will
    # not.
    #
    # Please note that Pacer turns on Neo4j's checkElementsInTransaction
    # feature by default. For some sort of performance improvement at
    # the expense of an odd consistency model within transactions that
    # require considerable more complexity in client code, you can use
    # `graph.setCheckElementsInTransaction(false)` to disable the
    # feature.
    def neo4j(path_or_graph, args = nil)
      neo = com.tinkerpop.blueprints.impls.neo4j.Neo4jGraph
      if path_or_graph.is_a? String
        open = proc do
          path = File.expand_path(path_or_graph)
          graph = Pacer.open_graphs[path]
          unless graph
            if args
              graph = neo.new(path, args.to_hash_map)
            else
              graph = neo.new(path)
            end
            Pacer.open_graphs[path] = graph
            graph.setCheckElementsInTransaction true
          end
          graph
        end
        shutdown = proc do
          graph.shutdown
          Pacer.open_graphs[path] = nil
        end
        PacerGraph.new(Pacer::YamlEncoder, open, shutdown)
      else
        # Don't register the new graph so that it won't be automatically closed.
        PacerGraph.new Pacer::YamlEncoder, proc { graph.neo.new(path_or_graph) }
      end
    end
  end


end
