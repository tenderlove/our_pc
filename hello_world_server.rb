require 'our_pc/server'
require 'socket'
require "helloworld_pb"

include Helloworld

class HelloWorldServer < OurPC::Server
  service "helloworld.Greeter" do |rpc|
    rpc.method "SayHello", HelloRequest, HelloReply do |req|
      HelloReply.new(message: "Hello #{req.name}")
    end
  end
end

server = TCPServer.new 50051 # Server bind to port 2000

loop do
  conn = server.accept    # Wait for a client to connect
  conn.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
  puts "Got a client"
  session = HelloWorldServer.new conn
  session.run
  puts "finished"
end
