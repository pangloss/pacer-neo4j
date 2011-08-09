require 'bundler'
Bundler::GemHelper.install_tasks

file 'pom.xml' => 'lib/pacer-neo4j/version.rb' do
  pom = File.read 'pom.xml'
  when_writing('Update pom.xml version number') do
    updated = false
    open 'pom.xml', 'w' do |f|
      pom.each_line do |line|
        if not updated and line =~ %r{<version>.*</version>}
          f << line.sub(%r{<version>.*</version>}, "<version>#{ Pacer::Neo4j::VERSION }</version>")
          updated = true
        else
          f << line
        end
      end
    end
  end
end

file Pacer::Neo4j::JAR_PATH => 'pom.xml' do
  when_writing("Execute 'mvn package' task") do
    system('mvn clean package')
  end
end

task :note do
  puts "NOTE: touch lib/pacer-neo4j/version.rb to force everything to rebuild"
end

task :build => [:note, Pacer::Neo4j::JAR_PATH]
task :install => [:note, Pacer::Neo4j::JAR_PATH]
