class RSpec::GraphRunner
  module Neo4j2
    def all(usage_style = :read_write, indices = true, &block)
      super
      neo4j2(usage_style, indices, &block)
    end

    def neo4j2(usage_style = :read_write, indices = true, &block)
      for_graph('neo4j2', usage_style, indices, true, neo2_graph, neo2_graph2, neo2_graph_no_indices, block)
    end

    protected

    def neo2_graph
      return @neo_graph if @neo_graph
      path1 = File.expand_path('tmp/spec.neo4j2')
      dir = Pathname.new(path1)
      dir.rmtree if dir.exist?
      @neo_graph = Pacer.neo4j2(path1)
    end

    def neo2_graph2
      return @neo_graph2 if @neo_graph2
      path2 = File.expand_path('tmp/spec.neo4j2.2')
      dir = Pathname.new(path2)
      dir.rmtree if dir.exist?
      @neo_graph2 = Pacer.neo4j2(path2)
    end

    def neo2_graph_no_indices
      return @neo_graph_no_indices if @neo_graph_no_indices
      path3 = File.expand_path('tmp/spec_no_indices.neo4j2')
      dir = Pathname.new(path3)
      dir.rmtree if dir.exist?
      @neo_graph_no_indices = Pacer.neo4j2(path3)
      @neo_graph_no_indices
    end
  end
end
