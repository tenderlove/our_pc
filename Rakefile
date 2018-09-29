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

task "examples/lib/helloworld_pb.rb"

task :default => :test
