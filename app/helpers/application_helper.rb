module ApplicationHelper
  def page_title(title)
    content_for(:title) { "#{title} - Blog" }
  end

  def display_date(time)
    return "Unpublished" if time.blank?

    time.to_date.to_fs(:long)
  end
end
