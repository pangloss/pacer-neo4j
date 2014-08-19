module Pacer
  module Neo4j
    VERSION = "2.2.0"
    JAR = "pacer-neo4j-#{ VERSION }-standalone.jar"
    JAR_PATH = "lib/#{ JAR }"
    BLUEPRINTS_VERSION = "2.6.0-SNAPSHOT"
    PACER_REQ = ">= 1.5.0"
  end
end
