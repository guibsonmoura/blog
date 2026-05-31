require "test_helper"

class AdminPostsControllerTest < ActionDispatch::IntegrationTest
  # Helper: build markdown following the pattern the form requires
  def markdown(title: "Test Post", excerpt: "The excerpt.", body: "Content here.")
    "# #{title}\n\n#{excerpt}\n\n---\n\n#{body}"
  end

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

  test "invalid jwt cookie redirects to login" do
    cookies[:admin_token] = "garbage-token-that-cannot-be-decoded"

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

  test "new post form has no title or excerpt fields" do
    sign_in_as users(:admin)
    get new_admin_post_path

    assert_select "input[name='post[title]']", count: 0
    assert_select "textarea[name='post[excerpt]']", count: 0
    assert_select "input[name='post[slug]']", count: 0
  end

  test "new post form has a body_markdown textarea" do
    sign_in_as users(:admin)
    get new_admin_post_path

    assert_select "textarea[name='post[body_markdown]']"
  end

  test "creating a post extracts title and excerpt from markdown" do
    sign_in_as users(:admin)

    assert_difference "Post.count", 1 do
      post admin_posts_path, params: {
        post: {
          body_markdown: markdown(title: "My New Post", excerpt: "This is the excerpt."),
          status: "draft"
        }
      }
    end

    created = Post.order(:created_at).last
    assert_equal "My New Post", created.title
    assert_equal "This is the excerpt.", created.excerpt
    assert_equal "my-new-post", created.slug
    assert_redirected_to admin_post_path(created)
  end

  test "creating a draft post does not set published_at" do
    sign_in_as users(:admin)

    post admin_posts_path, params: {
      post: { body_markdown: markdown, status: "draft" }
    }

    assert_nil Post.order(:created_at).last.published_at
  end

  test "creating a published post sets published_at automatically" do
    sign_in_as users(:admin)

    post admin_posts_path, params: {
      post: { body_markdown: markdown(title: "Published Now"), status: "published" }
    }

    created = Post.order(:created_at).last
    assert created.published?
    assert_not_nil created.published_at
    assert_in_delta Time.current, created.published_at, 5.seconds
  end

  test "title slug excerpt params submitted directly are ignored" do
    sign_in_as users(:admin)

    post admin_posts_path, params: {
      post: {
        title: "Injected Title",
        slug: "injected-slug",
        excerpt: "Injected excerpt",
        body_markdown: markdown(title: "Real Title", excerpt: "Real excerpt."),
        status: "draft"
      }
    }

    created = Post.order(:created_at).last
    assert_equal "Real Title", created.title
    assert_equal "real-title", created.slug
    assert_equal "Real excerpt.", created.excerpt
  end

  test "markdown without h1 heading fails and returns 422" do
    sign_in_as users(:admin)

    assert_no_difference "Post.count" do
      post admin_posts_path, params: {
        post: { body_markdown: "No heading here.", status: "draft" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "markdown without excerpt paragraph fails and returns 422" do
    sign_in_as users(:admin)
    md = "# Title Only\n\n## A subheading\n\n---\n\nBody."

    assert_no_difference "Post.count" do
      post admin_posts_path, params: {
        post: { body_markdown: md, status: "draft" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "blank body_markdown fails and returns 422" do
    sign_in_as users(:admin)

    assert_no_difference "Post.count" do
      post admin_posts_path, params: {
        post: { body_markdown: "", status: "draft" }
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

  test "edit form pre-fills body_markdown" do
    sign_in_as users(:admin)
    get edit_admin_post_path(posts(:draft))

    assert_select "textarea[name='post[body_markdown]']", text: /Draft Post/
  end

  test "updating body_markdown re-extracts title and excerpt" do
    sign_in_as users(:admin)
    new_md = markdown(title: "Revised Title", excerpt: "Revised excerpt.")

    patch admin_post_path(posts(:draft)), params: {
      post: { body_markdown: new_md }
    }

    posts(:draft).reload
    assert_equal "Revised Title", posts(:draft).title
    assert_equal "Revised excerpt.", posts(:draft).excerpt
    assert_redirected_to admin_post_path(posts(:draft))
  end

  test "updating with markdown missing h1 heading preserves existing title" do
    sign_in_as users(:admin)
    original_title = posts(:draft).title

    patch admin_post_path(posts(:draft)), params: {
      post: { body_markdown: "No heading — title stays from before." }
    }

    assert_redirected_to admin_post_path(posts(:draft))
    assert_equal original_title, posts(:draft).reload.title
  end

  test "publishing a draft post sets published_at" do
    sign_in_as users(:admin)

    patch admin_post_path(posts(:draft)), params: {
      post: { body_markdown: posts(:draft).body_markdown, status: "published" }
    }

    posts(:draft).reload
    assert posts(:draft).published?
    assert_not_nil posts(:draft).published_at
    assert_in_delta Time.current, posts(:draft).published_at, 5.seconds
  end

  test "reverting a published post to draft clears published_at" do
    sign_in_as users(:admin)

    patch admin_post_path(posts(:published)), params: {
      post: { body_markdown: posts(:published).body_markdown, status: "draft" }
    }

    assert_nil posts(:published).reload.published_at
  end

  # --- Destroy ---

  test "admin can delete a post" do
    sign_in_as users(:admin)

    assert_difference "Post.count", -1 do
      delete admin_post_path(posts(:draft))
    end

    assert_redirected_to admin_posts_path
  end

  # --- Retranslate ---

  test "retranslate re-queues the job for a published post" do
    sign_in_as users(:admin)
    posts(:published).update_column(:translation_status, "failed")

    assert_enqueued_with(job: TranslatePostJob, args: [ posts(:published).id ]) do
      post retranslate_admin_post_path(posts(:published))
    end

    assert_equal "pending", posts(:published).reload.translation_status
    assert_redirected_to admin_post_path(posts(:published))
  end

  test "retranslate is rejected for a draft post" do
    sign_in_as users(:admin)

    assert_no_enqueued_jobs(only: TranslatePostJob) do
      post retranslate_admin_post_path(posts(:draft))
    end

    assert_redirected_to admin_post_path(posts(:draft))
  end

  test "retranslate requires admin authentication" do
    post retranslate_admin_post_path(posts(:published))

    assert_redirected_to superadmin_login_path
  end

  test "retry button shows on show page for a failed published post" do
    sign_in_as users(:admin)
    posts(:published).update_column(:translation_status, "failed")

    get admin_post_path(posts(:published))

    assert_response :success
    assert_select "form[action=?]", retranslate_admin_post_path(posts(:published))
  end

  test "retry button hidden when translation is done" do
    sign_in_as users(:admin)
    posts(:published).update_column(:translation_status, "done")

    get admin_post_path(posts(:published))

    assert_select "form[action=?]", retranslate_admin_post_path(posts(:published)), count: 0
  end
end
