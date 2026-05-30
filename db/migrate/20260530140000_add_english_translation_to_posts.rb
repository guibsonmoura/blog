class AddEnglishTranslationToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :title_en,           :string
    add_column :posts, :excerpt_en,         :string
    add_column :posts, :body_markdown_en,   :text
    add_column :posts, :translation_status, :string, default: "pending"
  end
end
