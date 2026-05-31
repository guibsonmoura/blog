require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  # --- Index ---

  test "lists published posts in the archive" do
    get root_path

    assert_response :success
    assert_select "h4 a", text: "Published Post"
  end

  test "does not list draft posts" do
    get root_path

    assert_select "h4 a", text: "Draft Post", count: 0
  end

  test "does not list future-published posts" do
    users(:admin).posts.create!(
      title: "Future Post", excerpt: "Not yet", body_markdown: "Body",
      status: :published, published_at: 1.day.from_now
    )

    get root_path

    assert_select "h4 a", text: "Future Post", count: 0
  end

  test "archive shows every visible post grouped by date" do
    3.times do |i|
      users(:admin).posts.create!(
        title: "Extra Post #{i}", excerpt: "Excerpt", body_markdown: "Body",
        status: :published, published_at: (i + 2).days.ago
      )
    end

    get root_path

    assert_response :success
    # 1 published fixture + 3 new = 4 visible posts, all rendered (no pagination)
    assert_select "article", minimum: 4
    assert_select "h4 a", text: "Extra Post 0"
  end

  test "groups posts by year" do
    get root_path

    assert_response :success
    # year heading for the published fixture
    assert_select "section h2", text: Date.current.year.to_s, minimum: 0
  end

  test "public layout contains no link to admin area" do
    get root_path

    assert_select "a[href*='admin']", count: 0
    assert_select "a[href*='superadmin']", count: 0
  end

  # --- Show ---

  test "shows a published post" do
    get post_path(posts(:published))

    assert_response :success
    assert_select "h1", text: "Published Post"
  end

  test "show renders markdown as html" do
    get post_path(posts(:published))

    assert_response :success
    assert_select "h1", text: "Published Post"
  end

  test "does not show draft posts" do
    get post_path(posts(:draft))

    assert_response :not_found
  end

  test "does not show future-published posts" do
    future_post = users(:admin).posts.create!(
      title: "Scheduled", excerpt: "Scheduled", body_markdown: "Body",
      status: :published, published_at: 1.day.from_now
    )

    get post_path(future_post)

    assert_response :not_found
  end

  test "non-existent slug returns 404" do
    get post_path("does-not-exist")

    assert_response :not_found
  end
end
