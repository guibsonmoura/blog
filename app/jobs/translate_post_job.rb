class TranslatePostJob < ApplicationJob
  queue_as :default

  retry_on TranslationService::UnavailableError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post&.published?

    post.update_columns(translation_status: "translating")

    title_en   = TranslationService.translate(post.title)
    excerpt_en = TranslationService.translate(post.excerpt)
    body_en    = TranslationService.translate(post.body_markdown)

    post.update_columns(
      title_en:           title_en,
      excerpt_en:         excerpt_en,
      body_markdown_en:   reconstruct_markdown(title_en, excerpt_en, body_en),
      translation_status: "done"
    )
  rescue => e
    post&.update_columns(translation_status: "failed")
    raise
  end

  private

  def reconstruct_markdown(title, excerpt, translated_body)
    body_content = strip_header_and_excerpt(translated_body)
    "# #{title}\n\n#{excerpt}\n\n---\n\n#{body_content}"
  end

  def strip_header_and_excerpt(markdown)
    lines = markdown.lines
    # Skip leading # heading
    lines = lines.drop_while { |l| l.match?(/\A#\s+/) || l.strip.empty? }
    # Skip first paragraph (excerpt)
    lines = lines.drop_while { |l| l.strip.present? }
    lines = lines.drop_while { |l| l.strip.empty? }
    # Skip --- separator if present
    lines = lines.drop(1) if lines.first&.strip == "---"
    lines.join.lstrip
  end
end
