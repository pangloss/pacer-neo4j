module Pacer
  module Neo4j2
    VERSION = "2.1.6.pre"
    PACER_REQ = ">= 2.0.4.pre"
    if defined? Pacer::JARFILES
      Pacer::JARFILES << File.join(File.dirname(__FILE__), "../..", "Jarfile")
    end
  end
end
