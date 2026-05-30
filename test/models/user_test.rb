require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email before validation" do
    user = User.new(
      email: "  PERSON@EXAMPLE.COM ",
      name: "Person",
      password: "password12345",
      admin: true
    )

    assert user.valid?
    assert_equal "person@example.com", user.email
  end

  test "hashes passwords with argon2" do
    user = User.new(
      email: "person@example.com",
      name: "Person",
      password: "password12345",
      admin: true
    )

    assert user.valid?
    assert user.argon2_password?
    assert user.password_digest.start_with?("$argon2")
    assert_not_equal "password12345", user.password_digest
  end

  test "authenticates with argon2 password hash" do
    user = users(:admin)

    assert_equal user, user.authenticate("password12345")
    assert_not user.authenticate("wrong-password")
  end
end
