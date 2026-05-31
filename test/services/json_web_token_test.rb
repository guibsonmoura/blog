require "test_helper"

class JsonWebTokenTest < ActiveSupport::TestCase
  test "encodes and decodes claims" do
    token = JsonWebToken.encode(sub: users(:admin).id)
    payload = JsonWebToken.decode(token)

    assert_equal users(:admin).id, payload[:sub]
  end

  test "all payload claims survive round-trip" do
    token = JsonWebToken.encode(sub: 42, role: "admin")
    payload = JsonWebToken.decode(token)

    assert_equal 42, payload[:sub]
    assert_equal "admin", payload[:role]
  end

  test "returns nil for an invalid token string" do
    assert_nil JsonWebToken.decode("not-a-token")
  end

  test "returns nil for an expired token" do
    token = JsonWebToken.encode({ sub: users(:admin).id }, expires_at: 1.second.ago)

    assert_nil JsonWebToken.decode(token)
  end

  test "returns nil for a token signed with a different secret" do
    token = JWT.encode({ sub: 1, exp: 1.hour.from_now.to_i, iss: "blog-admin" }, "wrong-secret", "HS256")

    assert_nil JsonWebToken.decode(token)
  end

  test "returns nil for a token with a wrong issuer" do
    secret = Rails.application.secret_key_base
    token = JWT.encode({ sub: 1, exp: 1.hour.from_now.to_i, iss: "impostor" }, secret, "HS256")

    assert_nil JsonWebToken.decode(token)
  end

  test "a token issued for one audience is rejected by the other" do
    reader_token = JsonWebToken.encode({ sub: 7 }, issuer: "blog-reader")

    # The admin decoder (default issuer) must not accept a reader token.
    assert_nil JsonWebToken.decode(reader_token)
    # But the reader decoder does.
    assert_equal 7, JsonWebToken.decode(reader_token, issuer: "blog-reader")[:sub]

    # And the reverse: an admin token is rejected by the reader decoder.
    admin_token = JsonWebToken.encode(sub: 9)
    assert_nil JsonWebToken.decode(admin_token, issuer: "blog-reader")
  end
end
