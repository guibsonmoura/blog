require "test_helper"

class JsonWebTokenTest < ActiveSupport::TestCase
  test "encodes and decodes claims" do
    token = JsonWebToken.encode(sub: users(:admin).id)
    payload = JsonWebToken.decode(token)

    assert_equal users(:admin).id, payload[:sub]
  end

  test "returns nil for invalid tokens" do
    assert_nil JsonWebToken.decode("not-a-token")
  end
end
