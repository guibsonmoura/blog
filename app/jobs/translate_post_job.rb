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
    # Translate only the body content (after title/excerpt/--- separator) so
    # the --- horizontal rule is never sent to the model — it would be mangled
    # to ". . . . . . ." by opus-mt-ROMANCE-en.
    body_content_en = post.body_content.present? ? TranslationService.translate(post.body_content) : ""

    post.update_columns(
      title_en:           title_en,
      excerpt_en:         excerpt_en,
      body_markdown_en:   "# #{title_en}\n\n#{excerpt_en}\n\n---\n\n#{body_content_en}".rstrip,
      translation_status: "done"
    )
  rescue => e
    post&.update_columns(translation_status: "failed")
    raise
  end
end
