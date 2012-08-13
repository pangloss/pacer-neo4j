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
        path = File.expand_path(path_or_graph)
        graph = Pacer.starting_graph(self, path) do
          if args
            neo.new(path, args.to_hash_map)
          else
            neo.new(path)
          end
        end
      else
        # Don't register the new graph so that it won't be automatically closed.
        graph.neo.new(path_or_graph)
      end
      graph.setCheckElementsInTransaction true
      PacerGraph.new graph, Pacer::YamlEncoder
    end
  end


end
