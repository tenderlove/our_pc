require "helper"
require "google/protobuf"

class DSLTest < OurPC::Test
  class HelloWorldService < OurPC::RPC
  end

  def test_omg
    assert true
  end
end
