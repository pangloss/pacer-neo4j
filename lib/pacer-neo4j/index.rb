require 'yaml'

module Pacer
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jIndex
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jAutomaticIndex

  class Neo4jIndex
    include IndexMixin
    JVertex = com.tinkerpop.blueprints.pgm.Vertex.java_class.to_java
    JEdge = com.tinkerpop.blueprints.pgm.Edge.java_class.to_java
    JNeo4jVertex = com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jVertex.java_class.to_java
    JNeo4jEdge = com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jEdge.java_class.to_java

    def index_class
      et = getIndexClass
      if et == JVertex
        JNeo4jVertex
      elsif et == JEdge
        JNeo4jEdge
      else
        et
      end
    end
  end


  class Neo4jAutomaticIndex
    include IndexMixin
    JVertex = com.tinkerpop.blueprints.pgm.Vertex.java_class.to_java
    JEdge = com.tinkerpop.blueprints.pgm.Edge.java_class.to_java
    JNeo4jVertex = com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jVertex.java_class.to_java
    JNeo4jEdge = com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jEdge.java_class.to_java

    def index_class
      et = getIndexClass
      if et == JVertex
        JNeo4jVertex
      elsif et == JEdge
        JNeo4jEdge
      else
        et
      end
    end
  end
end
