require "test_helper"

class AdminPostsControllerTest < ActionDispatch::IntegrationTest
  # --- Authentication guards ---

  test "redirects anonymous user from index" do
    get admin_posts_path

    assert_redirected_to superadmin_login_path
  end

  test "redirects anonymous user from new post form" do
    get new_admin_post_path

    assert_redirected_to superadmin_login_path
  end

  test "redirects anonymous user from edit form" do
    get edit_admin_post_path(posts(:published))

    assert_redirected_to superadmin_login_path
  end

  test "expired jwt cookie redirects to login" do
    expired_token = JsonWebToken.encode({ sub: users(:admin).id }, expires_at: 1.second.ago)
    cookies.encrypted[:admin_token] = expired_token

    get admin_posts_path

    assert_redirected_to superadmin_login_path
  end

  # --- Listing ---

  test "admin can list posts including drafts" do
    sign_in_as users(:admin)
    get admin_posts_path

    assert_response :success
    assert_select "td p", text: "published-post"
    assert_select "td p", text: "draft-post"
  end

  # --- Show ---

  test "admin can view a single post" do
    sign_in_as users(:admin)
    get admin_post_path(posts(:published))

    assert_response :success
    assert_select "h1", text: "Published Post"
  end

  # --- New / Create ---

  test "admin can reach the new post form" do
    sign_in_as users(:admin)
    get new_admin_post_path

    assert_response :success
  end

  test "admin can create a draft post" do
    sign_in_as users(:admin)

    assert_difference "Post.count", 1 do
      post admin_posts_path, params: {
        post: { title: "New Draft", excerpt: "Draft excerpt", body_markdown: "Draft body", status: "draft" }
      }
    end

    assert_redirected_to admin_post_path(Post.order(:created_at).last)
  end

  test "admin can create a post with a custom slug" do
    sign_in_as users(:admin)

    post admin_posts_path, params: {
      post: { title: "Custom Slug Post", slug: "my-custom-slug", excerpt: "Excerpt", body_markdown: "Body", status: "draft" }
    }

    assert_equal "my-custom-slug", Post.order(:created_at).last.slug
  end

  test "post creation with blank title returns 422" do
    sign_in_as users(:admin)

    assert_no_difference "Post.count" do
      post admin_posts_path, params: {
        post: { title: "", excerpt: "Excerpt", body_markdown: "Body", status: "draft" }
      }
    end

    assert_response :unprocessable_entity
  end

  # --- Edit / Update ---

  test "admin can reach the edit form" do
    sign_in_as users(:admin)
    get edit_admin_post_path(posts(:draft))

    assert_response :success
  end

  test "admin can update a post" do
    sign_in_as users(:admin)
    patch admin_post_path(posts(:draft)), params: {
      post: { title: "Updated Title", excerpt: posts(:draft).excerpt, body_markdown: posts(:draft).body_markdown }
    }

    assert_redirected_to admin_post_path(posts(:draft))
    assert_equal "Updated Title", posts(:draft).reload.title
  end

  test "update with blank title returns 422" do
    sign_in_as users(:admin)
    patch admin_post_path(posts(:draft)), params: {
      post: { title: "", excerpt: posts(:draft).excerpt, body_markdown: posts(:draft).body_markdown }
    }

    assert_response :unprocessable_entity
  end

  test "publishing a draft post sets published_at" do
    sign_in_as users(:admin)
    patch admin_post_path(posts(:draft)), params: {
      post: { title: posts(:draft).title, excerpt: posts(:draft).excerpt, body_markdown: posts(:draft).body_markdown, status: "published" }
    }

    posts(:draft).reload
    assert posts(:draft).published?
    assert_not_nil posts(:draft).published_at
    assert_in_delta Time.current, posts(:draft).published_at, 5.seconds
  end

  # --- Destroy ---

  test "admin can delete a post" do
    sign_in_as users(:admin)

    assert_difference "Post.count", -1 do
      delete admin_post_path(posts(:draft))
    end

    assert_redirected_to admin_posts_path
  end
end
