require "test_helper"

class FeedControllerTest < ActionDispatch::IntegrationTest
  test "returns 200 with xml content type" do
    get feed_path(format: :xml)

    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
  end

  test "response is valid rss 2.0" do
    get feed_path(format: :xml)

    doc = Nokogiri::XML(response.body)
    assert doc.errors.empty?, "RSS XML has parse errors: #{doc.errors.join(', ')}"
    assert_equal "2.0", doc.at_css("rss")["version"]
  end

  test "feed includes required channel elements" do
    get feed_path(format: :xml)

    doc = Nokogiri::XML(response.body)
    assert_not_nil doc.at_css("channel > title")
    assert_not_nil doc.at_css("channel > link")
    assert_not_nil doc.at_css("channel > description")
  end

  test "published posts appear in the feed" do
    get feed_path(format: :xml)

    doc = Nokogiri::XML(response.body)
    titles = doc.css("item > title").map(&:text)
    assert_includes titles, posts(:published).localized_title
  end

  test "draft posts do not appear in the feed" do
    get feed_path(format: :xml)

    doc = Nokogiri::XML(response.body)
    titles = doc.css("item > title").map(&:text)
    assert_not_includes titles, posts(:draft).title
  end

  test "future-published posts do not appear in the feed" do
    future_post = users(:admin).posts.create!(
      title: "Future Post", excerpt: "Not yet", body_markdown: "Body",
      status: :published, published_at: 1.day.from_now
    )

    get feed_path(format: :xml)

    doc = Nokogiri::XML(response.body)
    titles = doc.css("item > title").map(&:text)
    assert_not_includes titles, future_post.title
  end

  test "each item has title link guid description and pubdate" do
    get feed_path(format: :xml)

    doc = Nokogiri::XML(response.body)
    doc.css("item").each do |item|
      assert_not_nil item.at_css("title"),       "item missing <title>"
      assert_not_nil item.at_css("link"),        "item missing <link>"
      assert_not_nil item.at_css("guid"),        "item missing <guid>"
      assert_not_nil item.at_css("description"), "item missing <description>"
      assert_not_nil item.at_css("pubDate"),     "item missing <pubDate>"
    end
  end

  test "item pubdate is valid rfc2822" do
    get feed_path(format: :xml)

    doc = Nokogiri::XML(response.body)
    doc.css("item > pubDate").each do |node|
      assert Time.rfc2822(node.text), "pubDate '#{node.text}' is not valid RFC 2822"
    end
  end

  test "feed is capped at 20 items" do
    21.times do |i|
      users(:admin).posts.create!(
        title: "Bulk Post #{i}", excerpt: "Excerpt", body_markdown: "Body",
        status: :published, published_at: (i + 2).days.ago
      )
    end

    get feed_path(format: :xml)

    doc = Nokogiri::XML(response.body)
    assert_operator doc.css("item").size, :<=, 20
  end

  test "atom self link points to feed url" do
    get feed_path(format: :xml)

    doc = Nokogiri::XML(response.body)
    doc.remove_namespaces!
    self_link = doc.at_css("link[rel='self']")
    assert_not_nil self_link
    assert_match(/feed\.xml/, self_link["href"])
  end
end
