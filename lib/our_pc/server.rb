require "socket"
require "io/wait"
require "our_pc/session"

module OurPC
  class Server
    def initialize socket
      @session = Session.new socket, self
      @session.submit_settings [
        [DS9::Settings::MAX_CONCURRENT_STREAMS, 100],
      ]
      super()
    end

    def execute service, method, protobuf
      signature = methods[method]
      arg = signature.decoder.decode protobuf
      ret = send methods[method].method_name, arg
      signature.encoder.encode(ret)
    end

    def run
      @session.run
    end

    Signature = Struct.new :decoder, :encoder, :name, :method_name

    class Builder
      attr_reader :methods

      def initialize service_name, mod
        @service_name = service_name
        @mod          = mod
        @methods      = {}
      end

      def method name, param_type, return_type, &block
        sig = Signature.new param_type, return_type, name, underscore(name)
        @methods[name] = sig
        @mod.define_method sig.method_name, &block
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
      mod = Module.new {
        define_method(:service_name) { service_name }

        def can_handle? service_name, method
          self.service_name == service_name && methods.key?(method)
        end
      }
      builder = Builder.new(service_name, mod)
      yield builder
      mod.define_method(:methods) { builder.methods }
      include mod
    end
  end
end
