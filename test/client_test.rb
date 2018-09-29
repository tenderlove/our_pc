require "helper"
require 'our_pc/server'
require "google/protobuf"

class DSLTest < OurPC::Test
  class HelloWorldService < OurPC::Server
  end

  def test_lol
    assert true
  end
end
