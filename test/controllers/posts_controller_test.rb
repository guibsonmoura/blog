require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  # --- Index ---

  test "lists published posts" do
    get root_path

    assert_response :success
    assert_select "h2", text: "Published Post"
  end

  test "does not list draft posts" do
    get root_path

    assert_select "h2", text: "Draft Post", count: 0
  end

  test "does not list future-published posts" do
    users(:admin).posts.create!(
      title: "Future Post", excerpt: "Not yet", body_markdown: "Body",
      status: :published, published_at: 1.day.from_now
    )

    get root_path

    assert_select "h2", text: "Future Post", count: 0
  end

  test "paginates at six posts per page" do
    6.times do |i|
      users(:admin).posts.create!(
        title: "Extra Post #{i}", excerpt: "Excerpt", body_markdown: "Body",
        status: :published, published_at: (i + 2).days.ago
      )
    end

    get root_path

    assert_response :success
    # existing published fixture + 6 new = 7 total; page 1 shows 6
    assert_select "article", count: 6
  end

  test "second page returns remaining posts" do
    6.times do |i|
      users(:admin).posts.create!(
        title: "Extra Post #{i}", excerpt: "Excerpt", body_markdown: "Body",
        status: :published, published_at: (i + 2).days.ago
      )
    end

    get posts_path(page: 2)

    assert_response :success
    assert_select "article", count: 1
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
    assert_select "h1", text: "Published"
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
