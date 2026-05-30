require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email before validation" do
    user = User.new(email: "  PERSON@EXAMPLE.COM ", name: "Person", password: "password12345", admin: true)

    assert user.valid?
    assert_equal "person@example.com", user.email
  end

  test "hashes passwords with argon2" do
    user = User.new(email: "person@example.com", name: "Person", password: "password12345", admin: true)

    assert user.valid?
    assert user.argon2_password?
    assert user.password_digest.start_with?("$argon2")
    assert_not_equal "password12345", user.password_digest
  end

  test "authenticates with correct password" do
    user = users(:admin)

    assert_equal user, user.authenticate("password12345")
  end

  test "authentication fails with wrong password" do
    assert_not users(:admin).authenticate("wrong-password")
  end

  test "authentication returns false for blank password" do
    assert_not users(:admin).authenticate("")
    assert_not users(:admin).authenticate(nil)
  end

  test "password shorter than 12 characters fails validation" do
    user = User.new(email: "short@example.com", name: "Short", password: "tooshort")

    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 12 characters)"
  end

  test "blank password_digest fails validation" do
    user = User.new(email: "nopass@example.com", name: "NoPass")

    assert_not user.valid?
    assert user.errors[:password_digest].any?
  end

  test "invalid email format is rejected" do
    user = User.new(email: "not-an-email", name: "Bad Email", password: "password12345")

    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "blank email fails validation" do
    user = User.new(email: "", name: "No Email", password: "password12345")

    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "duplicate email is rejected" do
    user = User.new(email: users(:admin).email, name: "Dup", password: "password12345")

    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "blank name fails validation" do
    user = User.new(email: "noname@example.com", name: "", password: "password12345")

    assert_not user.valid?
    assert user.errors[:name].any?
  end

  test "admin flag is false by default" do
    user = User.new

    assert_not user.admin?
  end
end
