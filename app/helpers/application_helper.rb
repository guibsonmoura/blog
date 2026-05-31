module ApplicationHelper
  def page_title(title)
    content_for(:title) { "#{title} - Blog" }
  end

  def display_date(time)
    return I18n.t("dates.unpublished") if time.blank?

    I18n.l(time.to_date, format: :long)
  end
end
