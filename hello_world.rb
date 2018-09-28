require "our_pc/client"
require "helloworld_pb"

include Helloworld

class HelloWorld < OurPC::Client
  service "helloworld.Greeter" do |rpc|
    rpc.method "SayHello", HelloRequest, HelloReply
  end
end

client = HelloWorld.new "localhost:50051"
client.connect

20_000.times do
  res = client.say_hello HelloRequest.new(name: "world")
  res.message
end
