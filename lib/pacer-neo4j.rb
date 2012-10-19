require 'pacer' unless defined? Pacer

lib_path = File.expand_path(File.join(File.dirname(__FILE__), '../lib'))
$:.unshift lib_path unless $:.any? { |path| path == lib_path }

require 'pacer-neo4j/version'

require Pacer::Neo4j::JAR

require 'pacer-neo4j/graph'
require 'pacer-neo4j/algo'
require 'pacer-neo4j/raw_vertex_wrapping_pipe'
require 'pacer-neo4j/lucene_filter'

Pacer::FunctionResolver.clear_cache
