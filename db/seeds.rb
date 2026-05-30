admin = User.find_or_initialize_by(email: ENV.fetch("ADMIN_EMAIL", "admin@example.com"))
admin.name = ENV.fetch("ADMIN_NAME", "Admin")
admin.admin = true
admin_password = ENV["ADMIN_PASSWORD"].presence || ("password12345" unless Rails.env.production?)

if admin.password_digest.blank? || (!admin.argon2_password? && admin_password.present?)
  admin.password = admin_password
end

if admin.password_digest.blank?
  raise "Set ADMIN_PASSWORD to create or migrate the seed admin password."
end

admin.save!

Post.find_or_create_by!(slug: "welcome") do |post|
  post.user = admin
  post.title = "Welcome"
  post.excerpt = "A first published post for the Rails blog."
  post.body_markdown = <<~MARKDOWN
    ## Hello

    This is the first post in the blog. Edit it from the admin panel.
  MARKDOWN
  post.status = :published
  post.published_at = Time.current
end
