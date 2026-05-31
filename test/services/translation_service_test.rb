require "test_helper"

class TranslationServiceTest < ActiveSupport::TestCase
  test "returns translated text on success" do
    stub_translation("Olá mundo", "Hello world")

    result = TranslationService.translate("Olá mundo")

    assert_equal "Hello world", result
  end

  test "raises UnavailableError on connection failure" do
    stub_translation_unavailable

    assert_raises(TranslationService::UnavailableError) do
      TranslationService.translate("Texto")
    end
  end

  test "raises UnavailableError on non-200 response" do
    stub_translation_error(503)

    assert_raises(TranslationService::UnavailableError) do
      TranslationService.translate("Texto")
    end
  end

  test "posts to the configured URL" do
    stub = stub_translation("Texto", "Text")

    TranslationService.translate("Texto")

    assert_requested stub
  end

  private

  def stub_translation(input, output)
    stub_request(:post, "#{TranslationService::URL}/translate")
      .with(body: { text: input }.to_json, headers: { "Content-Type" => "application/json" })
      .to_return(status: 200, body: { translation: output }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  def stub_translation_unavailable
    stub_request(:post, "#{TranslationService::URL}/translate")
      .to_raise(Errno::ECONNREFUSED)
  end

  def stub_translation_error(code)
    stub_request(:post, "#{TranslationService::URL}/translate")
      .to_return(status: code, body: "error")
  end
end
