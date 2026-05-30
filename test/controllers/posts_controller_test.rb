require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "lists published posts" do
    get root_path

    assert_response :success
    assert_select "h2", text: "Published Post"
    assert_select "h2", text: "Draft Post", count: 0
  end

  test "shows a published post" do
    get post_path(posts(:published))

    assert_response :success
    assert_select "h1", text: "Published Post"
  end

  test "does not show draft posts publicly" do
    get post_path(posts(:draft))

    assert_response :not_found
  end
end
