module Pacer
  module Neo4j
    VERSION = "2.3.2.pre"
    PACER_REQ = ">= 2.0.4.pre"
    if defined? Pacer::JARFILES
      Pacer::JARFILES << File.join(File.dirname(__FILE__), "../..", "Jarfile")
    end
  end
end
