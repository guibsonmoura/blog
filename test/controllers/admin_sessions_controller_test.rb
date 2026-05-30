require "test_helper"

class AdminSessionsControllerTest < ActionDispatch::IntegrationTest
  test "admin can sign in" do
    post admin_session_path, params: { email: users(:admin).email, password: "password12345" }

    assert_redirected_to admin_root_path
  end

  test "non admin cannot sign in" do
    post admin_session_path, params: { email: users(:writer).email, password: "password12345" }

    assert_response :unprocessable_entity
  end
end
