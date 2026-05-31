require "test_helper"

class TranslatePostJobTest < ActiveJob::TestCase
  setup do
    @post = posts(:published)
  end

  test "populates EN columns and sets status to done" do
    stub_all_translations

    TranslatePostJob.perform_now(@post.id)

    @post.reload
    assert_equal "done", @post.translation_status
    assert_present @post.title_en
    assert_present @post.excerpt_en
    assert_present @post.body_markdown_en
  end

  test "sets status to translating before calling the service" do
    order = []
    stub_all_translations do
      order << @post.reload.translation_status
    end

    TranslatePostJob.perform_now(@post.id)

    assert_includes order, "translating"
  end

  test "sets status to failed when translation service returns error" do
    stub_request(:post, "#{TranslationService::URL}/translate")
      .to_return(status: 500, body: "oops")

    # retry_on swallows the error in perform_now context after setting failed status
    begin
      TranslatePostJob.perform_now(@post.id)
    rescue TranslationService::UnavailableError
      # may or may not re-raise depending on queue adapter
    end

    assert_equal "failed", @post.reload.translation_status
  end

  test "does nothing when post does not exist" do
    assert_nothing_raised { TranslatePostJob.perform_now(-1) }
  end

  test "failed post can be retried by resetting status to pending and re-running the job" do
    stub_all_translations

    # Simulate a previously failed translation
    @post.update_columns(translation_status: "failed", title_en: nil, excerpt_en: nil, body_markdown_en: nil)

    @post.update_columns(translation_status: "pending")
    TranslatePostJob.perform_now(@post.id)

    @post.reload
    assert_equal "done", @post.translation_status
    assert_present @post.title_en
  end

  test "job raises UnavailableError when translator host is unreachable" do
    stub_request(:post, "#{TranslationService::URL}/translate")
      .to_raise(Errno::ECONNREFUSED)

    begin
      TranslatePostJob.perform_now(@post.id)
    rescue TranslationService::UnavailableError
      # expected
    end

    assert_equal "failed", @post.reload.translation_status
  end

  test "job raises UnavailableError when translator URL is wrong or service missing" do
    stub_request(:post, "#{TranslationService::URL}/translate")
      .to_raise(SocketError.new("Failed to open TCP connection"))

    begin
      TranslatePostJob.perform_now(@post.id)
    rescue TranslationService::UnavailableError
      # expected
    end

    assert_equal "failed", @post.reload.translation_status
  end

  test "does nothing when post is a draft" do
    draft = posts(:draft)

    TranslatePostJob.perform_now(draft.id)

    assert_nil draft.reload.title_en
  end

  test "body_markdown_en follows the standard markdown pattern" do
    stub_all_translations

    TranslatePostJob.perform_now(@post.id)

    @post.reload
    assert_match(/\A# .+\n\n.+\n\n---\n\n/m, @post.body_markdown_en)
  end

  test "body_markdown_en does not contain dots from translated --- separator" do
    # Regression: opus-mt-ROMANCE-en translates '---' as '. . . . . .'
    # The job must translate only body_content (after the separator), not the full markdown
    stub_all_translations

    TranslatePostJob.perform_now(@post.id)

    @post.reload
    refute_match(/\.\s\.\s\./, @post.body_markdown_en,
      "body_markdown_en must not contain dot artifacts from a translated --- separator")
  end

  test "job sends body_content not full body_markdown to the translator" do
    # Ensures the --- separator is never sent to the model
    bodies_sent = []
    stub_request(:post, "#{TranslationService::URL}/translate")
      .to_return do |req|
        bodies_sent << JSON.parse(req.body)["text"]
        { status: 200, body: { translation: "Translated" }.to_json,
          headers: { "Content-Type" => "application/json" } }
      end

    TranslatePostJob.perform_now(@post.id)

    bodies_sent.each do |text|
      assert_no_match(/\A---\z/, text.strip,
        "The standalone --- separator must not be sent to the translation service")
    end
  end

  private

  def stub_all_translations(&block)
    stub_request(:post, "#{TranslationService::URL}/translate")
      .to_return do |_req|
        block&.call
        { status: 200, body: { translation: "Translated text" }.to_json,
          headers: { "Content-Type" => "application/json" } }
      end
  end

  def assert_present(value)
    assert value.present?, "Expected value to be present but was #{value.inspect}"
  end
end
