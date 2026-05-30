require "test_helper"

class AdminSessionsControllerTest < ActionDispatch::IntegrationTest
  test "login page renders" do
    get superadmin_login_path

    assert_response :success
  end

  test "already authenticated admin is redirected to admin panel" do
    sign_in_as users(:admin)
    get superadmin_login_path

    assert_redirected_to admin_root_path
  end

  test "admin can sign in with valid credentials" do
    post superadmin_login_path, params: { email: users(:admin).email, password: "password12345" }

    assert_redirected_to admin_root_path
  end

  test "sign in sets an http-only encrypted cookie" do
    post superadmin_login_path, params: { email: users(:admin).email, password: "password12345" }

    cookie_header = response.headers["Set-Cookie"]
    assert_match "admin_token", cookie_header
    assert_match(/HttpOnly/i, cookie_header)
  end

  test "sign in rejects wrong password" do
    post superadmin_login_path, params: { email: users(:admin).email, password: "wrongpassword" }

    assert_response :unprocessable_entity
  end

  test "sign in rejects non-admin user" do
    post superadmin_login_path, params: { email: users(:writer).email, password: "password12345" }

    assert_response :unprocessable_entity
  end

  test "sign in rejects blank email" do
    post superadmin_login_path, params: { email: "", password: "password12345" }

    assert_response :unprocessable_entity
  end

  test "sign in rejects unknown email" do
    post superadmin_login_path, params: { email: "nobody@example.com", password: "password12345" }

    assert_response :unprocessable_entity
  end

  test "sign out clears cookie and redirects to login" do
    sign_in_as users(:admin)
    delete superadmin_logout_path

    assert_redirected_to superadmin_login_path
  end

  test "after sign out admin posts redirects to login" do
    sign_in_as users(:admin)
    delete superadmin_logout_path
    get admin_posts_path

    assert_redirected_to superadmin_login_path
  end
end
