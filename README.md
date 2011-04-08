# Neo4J Graph Database Adapter for Pacer

[Pacer](https://github.com/pangloss/pacer) is a
[JRuby](http://jruby.org) graph traversal framework built on the
[Tinkerpop](http://www.tinkerpop.com) stack.

This plugin enables full [Neo4J](http://neo4j.org) graph support in Pacer.


## Usage

Here is how you open a Neo4J graph in Pacer.

  require 'pacer'
  require 'pacer-neo4j'

  # Graph will be created if it doesn't exist
  graph = Pacer.neo4j 'path/to/graph'

All other operations are identical across graph implementations (except
where certain features are not supported). See Pacer's documentation for
more information.

