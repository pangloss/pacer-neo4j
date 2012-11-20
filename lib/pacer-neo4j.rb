require 'pacer' unless defined? Pacer

lib_path = File.expand_path(File.join(File.dirname(__FILE__), '../lib'))
$:.unshift lib_path unless $:.any? { |path| path == lib_path }

require 'pacer-neo4j/version'

require Pacer::Neo4j::JAR

require 'pacer-neo4j/graph'
require 'pacer-neo4j/algo/wrapping'
require 'pacer-neo4j/algo/path_pipe'
require 'pacer-neo4j/algo/block_cost_evaluator'
require 'pacer-neo4j/algo/block_estimate_evaluator'
require 'pacer-neo4j/algo/block_path_expander'
require 'pacer-neo4j/algo/path_wrapper'
require 'pacer-neo4j/algo/traversal_branch_wrapper'
require 'pacer-neo4j/algo'
require 'pacer-neo4j/raw_vertex_wrapping_pipe'
require 'pacer-neo4j/lucene_filter'
require 'pacer-neo4j/transaction_event_handler'
require 'pacer-neo4j/tx_data_wrapper'

Pacer::FunctionResolver.clear_cache

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
      bp_neo_class = com.tinkerpop.blueprints.impls.neo4j.Neo4jGraph
      if path_or_graph.is_a? String
        path = File.expand_path(path_or_graph)
        open = proc do
          graph = Pacer.open_graphs[path]
          unless graph
            if args
              graph = bp_neo_class.new(path, args.to_hash_map)
            else
              graph = bp_neo_class.new(path)
            end
            Pacer.open_graphs[path] = graph
            graph.setCheckElementsInTransaction true
          end
          graph
        end
        shutdown = proc do |g|
          g.blueprints_graph.shutdown
          Pacer.open_graphs.delete path
        end
        Neo4j::Graph.new(Pacer::YamlEncoder, open, shutdown)
      else
        # Don't register the new graph so that it won't be automatically closed.
        Neo4j::Graph.new Pacer::YamlEncoder, proc { bp_neo_class.new(path_or_graph) }
      end
    end

    def neo_batch(path)
      bp_neo_class = com.tinkerpop.blueprints.impls.neo4jbatch.Neo4jBatchGraph
      path = File.expand_path(path)
      open = proc do
        graph = bp_neo_class.new(path)
        Pacer.open_graphs[path] = :open_batch_graph
        graph
      end
      shutdown = proc do |g|
        g.blueprints_graph.shutdown
        Pacer.open_graphs.delete path
      end
      g = PacerGraph.new(Pacer::YamlEncoder, open, shutdown)
      g.disable_transactions = true
      g
    end
  end
end
