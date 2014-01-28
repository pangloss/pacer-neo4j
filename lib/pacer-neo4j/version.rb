module Pacer
  module Neo4j
    VERSION = "3.0.0.pre"
    JAR = "pacer-neo4j-#{ VERSION }-standalone.jar"
    JAR_PATH = "lib/#{ JAR }"
    BLUEPRINTS_VERSION = "2.5.0-SNAPSHOT"
    PIPES_VERSION = "2.5.0-SNAPSHOT"
    PACER_REQ = ">= 1.5.0.pre"
  end
end
