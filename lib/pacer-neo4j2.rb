require 'pacer' unless defined? Pacer

lib_path = File.expand_path(File.join(File.dirname(__FILE__), '../lib'))
$:.unshift lib_path unless $:.any? { |path| path == lib_path }

require 'pacer-neo4j2/version'

require 'pacer-neo4j2/graph'
require 'pacer-neo4j2/algo/wrapping'
require 'pacer-neo4j2/algo/path_pipe'
require 'pacer-neo4j2/algo/block_cost_evaluator'
require 'pacer-neo4j2/algo/block_estimate_evaluator'
require 'pacer-neo4j2/algo/block_path_expander'
require 'pacer-neo4j2/algo/path_wrapper'
require 'pacer-neo4j2/algo/traversal_branch_wrapper'
require 'pacer-neo4j2/algo/cypher_transform'
require 'pacer-neo4j2/algo'
require 'pacer-neo4j2/raw_vertex_wrapping_pipe'
require 'pacer-neo4j2/lucene_filter'
require 'pacer-neo4j2/transaction_event_handler'
require 'pacer-neo4j2/tx_data_wrapper'
require 'pacer-neo4j2/blueprints_graph'

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
    #
    # It is recommended that *in production* the `allow_auto_tx` and
    # `allow_auto_read_tx` options be set to `false` to prevent hard-to-debug
    # errors caused by Blueprints' automatically starting transactions which it
    # never automatically commits or rolls back. When working in the console,
    # however, reenabling automatic read transactons is generally recommended,
    # together with periodic use of `rollback_implicit_transaction`
    def neo4j2(path_or_graph, args = nil)
      if path_or_graph.is_a? String
        path = File.expand_path(path_or_graph)
        open = proc do
          raw_graph = Pacer.open_graphs[path]
          if raw_graph
            graph = Pacer::Neo4j2::BlueprintsGraph.new(raw_graph)
          else
            if args
              graph = Pacer::Neo4j2::BlueprintsGraph.new(path, args.to_hash_map)
            else
              graph = Pacer::Neo4j2::BlueprintsGraph.new(path)
            end
            graph.allow_auto_tx = false
            graph.allow_auto_read_tx = false
            Pacer.open_graphs[path] = graph.raw_graph
            graph.setCheckElementsInTransaction true
          end
          graph
        end
        shutdown = proc do |g|
          g.blueprints_graph.shutdown
          Pacer.open_graphs.delete path
        end
        Neo4j2::Graph.new(Pacer::YamlEncoder, open, shutdown)
      else
        # Don't register the new graph so that it won't be automatically closed.
        Neo4j2::Graph.new Pacer::YamlEncoder, proc { Pacer::Neo4j2::BlueprintsGraph.new(path_or_graph) }
      end
    end

    def neo2_batch(path)
      bp_neo_class = com.tinkerpop.blueprints.impls.neo4jbatch.Neo4j2BatchGraph
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
