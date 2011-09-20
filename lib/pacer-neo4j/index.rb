require 'yaml'

module Pacer
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jIndex
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jAutomaticIndex

  class Neo4jIndex
    include IndexMixin
    import com.tinkerpop.blueprints.pgm.Vertex
    import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jVertex
    import com.tinkerpop.blueprints.pgm.Edge
    import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jEdge

    def index_class
      et = getIndexClass
      if et == Vertex.java_class.to_java or et == Neo4jVertex
        Neo4jVertex.java_class.to_java
      elsif et == Neo4jVertex.java_class.to_java
        Neo4jVertex.java_class.to_java
      elsif et == Edge.java_class.to_java or et == Neo4jEdge
        Neo4jEdge.java_class.to_java
      elsif et == Neo4jEdge.java_class.to_java
        Neo4jVertex.java_class.to_java
      else
        raise "unexpected Neo4j Index class: #{ et.to_s }"
      end
    end
  end


  class Neo4jAutomaticIndex
    include IndexMixin
    import com.tinkerpop.blueprints.pgm.Vertex
    import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jVertex
    import com.tinkerpop.blueprints.pgm.Edge
    import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jEdge

    def index_class
      et = getIndexClass
      if et == Vertex.java_class.to_java or et == Neo4jVertex
        Neo4jVertex.java_class.to_java
      elsif et == Neo4jVertex.java_class.to_java
        Neo4jVertex.java_class.to_java
      elsif et == Edge.java_class.to_java or et == Neo4jEdge
        Neo4jEdge.java_class.to_java
      elsif et == Neo4jEdge.java_class.to_java
        Neo4jVertex.java_class.to_java
      else
        raise "unexpected Neo4j Index class: #{ et.to_s }"
      end
    end
  end
end
