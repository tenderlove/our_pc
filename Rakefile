require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
  t.warning = true
end

def source_for_proto file
  "examples/src/helloworld.proto"
end

rule "_pb.rb" => ->(f) { source_for_proto(f) } do |t|
  sh "protoc --proto_path=examples/src --ruby_out=examples/lib #{t.source}"
end

task :deps do
  begin
    require 'ds9'
    require 'google/protobuf'
    require 'benchmark/ips'
  rescue LoadError
    Gem.install 'ds9'
    Gem.install 'google-protobuf'
    Gem.install 'benchmark-ips'
    retry
  end
end

task "examples/lib/helloworld_pb.rb"

task :server => ["examples/lib/helloworld_pb.rb", :deps] do
  sh "ruby -I lib:examples/lib hello_world_server.rb"
end

task :client => ["examples/lib/helloworld_pb.rb", :deps] do
  sh "ruby -I lib:examples/lib hello_world.rb"
end

task :default => [:deps, :test]
