require "test_helper"

class AdminPostsControllerTest < ActionDispatch::IntegrationTest
  test "redirects anonymous users to sign in" do
    get admin_posts_path

    assert_redirected_to new_admin_session_path
  end

  test "admin can list posts" do
    sign_in_as users(:admin)

    get admin_posts_path

    assert_response :success
    assert_select "td p", text: "published-post"
  end

  test "admin can create a draft post" do
    sign_in_as users(:admin)

    assert_difference "Post.count", 1 do
      post admin_posts_path, params: {
        post: {
          title: "New Draft",
          excerpt: "Draft excerpt",
          body_markdown: "Draft body",
          status: "draft"
        }
      }
    end

    assert_redirected_to admin_post_path(Post.order(:created_at).last)
  end
end
