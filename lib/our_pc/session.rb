require "ds9"

module OurPC
  module IOEvents
    def initialize reader, writer
      super()

      @reader = reader
      @writer = writer
    end

    def recv_event length
      case data = @reader.read_nonblock(length, nil, exception: false)
      when :wait_readable then DS9::ERR_WOULDBLOCK
      when nil            then
        if want_read?
          DS9::ERR_EOF
        else
          ''
        end
      else
        data
      end
    end

    def run
      while want_read? || want_write?
        return if done?
        if want_write?
          send
        end
        if want_read?
          @reader.wait_readable
          return if @reader.eof?
          receive
        end
      end
    rescue Errno::ECONNRESET
      # done!
    end

    def send_event string
      @writer.write string
    end

    def done?
      false
    end
  end

  class Client
    class Session < ::DS9::Client
      include IOEvents

      def initialize sock
        super(sock, sock)
        @in_flight = {}
        @blocks    = {}
        @responses = {}
      end

      def on_stream_close id, errcode
        response_buffer = @in_flight.delete id

        @responses[id] = if @blocks.key? id
                           @blocks.delete(id).call response_buffer
                         else
                           response_buffer
                         end
      end

      def on_data_chunk_recv id, data, flags
        @in_flight[id] << data
      end

      def consume_response id
        while !@responses.key?(id) && (want_read? || want_write?)
          receive
          send
        end

        @responses.delete(id) do
          raise MissingResponse, "No response with id #{id}"
        end
      end

      def submit_request headers, body, &block
        id = super
        @blocks[id] = block if block_given?
        id
      end

      def on_begin_headers frame
        if frame.headers?
          @in_flight[frame.stream_id] ||= ''.dup
        end
      end

      def done?
        return if @blocks.length == 0
      end
    end
  end

  class Server
    class Request
      attr_accessor :protobuf

      def initialize
        @headers = {}
        @in_flight = nil
        @protobuf = nil
      end

      def []= k, v
        @headers[k] = v
      end

      def [] k
        @headers[k]
      end

      def << x
        if @in_flight
          raise "no implemented yet"
        else
          _, len, buf = x.unpack('CNa*')

          if len == buf.length
            @protobuf = buf
          else
            @in_flight = [len, buf]
            @protobuf = nil
          end
        end
      end

      def post?
        self[":method"] == "POST"
      end

      def path
        self[":path"]
      end
    end

    class Session < DS9::Server
      include IOEvents

      def initialize sock, handler
        super(sock, sock)
        @write_streams = {}
        @in_flight     = {}
        @blocks        = {}
        @responses     = {}
        @handler   = handler
      end

      def on_stream_close id, errcode
        @in_flight.delete id
      end

      def on_begin_headers frame
        if @in_flight[frame.stream_id]
          # trailers
        else
          @in_flight[frame.stream_id] = Request.new
        end
      end

      def on_data_chunk_recv id, data, flags
        @in_flight[id] << data
      end

      def on_frame_recv frame
        request = @in_flight[frame.stream_id]

        if frame.headers?
          _, service, method = request.path.split("\/", 3)

          if @handler.can_handle?(service, method)
          else
            @write_streams[frame.stream_id] = StringIO.new("Not Found\n")

            submit_response(frame.stream_id, {
              ":status"              => '404',
              "content-type"         => "application/grpc",
              "grpc-accept-encoding" => "identity,deflate,gzip",
              "accept-encoding"      => "identity,gzip",
            })
          end
        elsif frame.data? && request.protobuf
          _, service, method = request.path.split("\/", 3)

          protobuf = @handler.execute(service, method, request.protobuf)
          buf = [0, protobuf.length, protobuf].pack("CNa*")
          request.protobuf = nil
          @write_streams[frame.stream_id] = StringIO.new(buf)

          submit_response(frame.stream_id, {
            ":status"              => '200',
            "content-type"         => "application/grpc",
            "grpc-accept-encoding" => "identity,deflate,gzip",
            "accept-encoding"      => "identity,gzip",
          })
        end

        true
      end


      def on_data_source_read stream_id, length
        x = @write_streams[stream_id].read(length)
        if x.nil?
          submit_trailer(stream_id, {
            "grpc-status" => "0",
            "grpc-message" => "OK",
          })
          false
        else
          x
        end
      end

      def on_header name, value, frame, flags
        @in_flight[frame.stream_id][name] = value
      end
    end
  end
end
