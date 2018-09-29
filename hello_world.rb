require "our_pc/client"
require "helloworld_pb"
require "benchmark/ips"

include Helloworld

class HelloWorld < OurPC::Client
  service "helloworld.Greeter" do |rpc|
    rpc.method "SayHello", HelloRequest, HelloReply
  end
end

client = HelloWorld.new "localhost:50051"
client.connect

Benchmark.ips do |x|
  x.report("say hello") do
    res = client.say_hello HelloRequest.new(name: "world")
    res.message
  end
end
