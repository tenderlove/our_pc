require "benchmark/ips"

## This part is equivalent the generated RPC stubs from the gRPC gem

require "our_pc/client"
require "helloworld_pb"

include Helloworld

class HelloWorld < OurPC::Client
  service "helloworld.Greeter" do |rpc|
    rpc.method "SayHello", HelloRequest, HelloReply
  end
end

# This is the client part.  The stub part in OurPC looks nice so I didn't
# bother putting it in a different file.

client = HelloWorld.new "localhost:50051"
client.connect

Benchmark.ips do |x|
  x.report("say hello") do
    res = client.say_hello HelloRequest.new(name: "world")
    res.message
  end
end
