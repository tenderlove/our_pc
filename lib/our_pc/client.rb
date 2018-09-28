require "socket"
require "io/wait"
require "our_pc/session"

module OurPC
  class Client
    def initialize address
      @host, @port = address.split ':'
      @scheme    = 'http'
      @authority = address
      @socket    = nil
    end

    def connect
      @socket = make_connection
      @session = Session.new @socket
      @session.submit_settings []
    end

    def submit_request path, request, &block
      # Encode the request for gRPC
      request = [0, request.length, request].pack('CNa*')
      @session.submit_request({
        ':scheme'              => @scheme,
        ':method'              => 'POST',
        ':authority'           => @authority,
        ':path'                => path,
        'te'                   => 'trailers',
        'content-type'         => 'application/grpc',
        'user-agent'           => 'test',
        'grpc-accept-encoding' => 'identity,deflate,gzip',
        'accept-encoding'      => 'identity,gzip',
      }, request, &block)
    end

    def consume_response id
      data = @session.consume_response(id)
      compression, len, msg = data.unpack('CNa*')

      if msg.length == len
        if compression == 1
          raise NotImplmentedError
        else
          msg
        end
      else
        raise NotImplmentedError, "no streaming support yet"
      end
    end

    def send_and_receive path, encoder, decoder, request, metadata: nil
      req = encoder.encode request
      msg = consume_response submit_request(path, req)
      #@session.terminate_session DS9::NO_ERROR
      decoder.decode(msg)
    end

    private

    def make_connection
      socket = TCPSocket.new @host, @port
      socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      socket
    end

    class Builder
      def initialize service_name, mod
        @service_name = service_name
        @mod          = mod
      end

      def method name, encoder, decoder
        path = "/" + @service_name + "/" + name
        @mod.define_method underscore(name) do |request, metadata: nil|
          send_and_receive path, encoder, decoder, request, metadata: metadata
        end
      end

      private

      def underscore name
        name.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end
    end

    def self.service service_name
      mod = Module.new
      yield Builder.new(service_name, mod)
      include mod
    end
  end
end
