require 'bundler'
Bundler::GemHelper.install_tasks

file 'pom.xml' => 'lib/pacer-neo4j2/version.rb' do
  pom = File.read 'pom.xml'
  when_writing('Update pom.xml version number') do
    open 'pom.xml', 'w' do |f|
      pom.each_line do |line|
        line.sub!(%r{<gem.version>.*</gem.version>}, "<gem.version>#{ Pacer::Neo4j2::VERSION }</gem.version>")
        line.sub!(%r{<blueprints.version>.*</blueprints.version>}, "<blueprints.version>#{ Pacer::Neo4j2::BLUEPRINTS_VERSION }</blueprints.version>")
        f << line
      end
    end
  end
end

file Pacer::Neo4j2::JAR_PATH => 'pom.xml' do
  when_writing("Execute 'mvn package' task") do
    system('mvn clean package')
  end
end

task :note do
  puts "NOTE: touch lib/pacer-neo4j2/version.rb (or rake touch) to force everything to rebuild"
end

task :build => [:note, Pacer::Neo4j2::JAR_PATH]
task :install => [:note, Pacer::Neo4j2::JAR_PATH]

desc 'Touch version.rb so that the jar rebuilds'
task :touch do
  system 'touch', 'lib/pacer-neo4j2/version.rb'
end

