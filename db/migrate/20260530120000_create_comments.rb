class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.string :author_name, null: false
      t.string :author_email
      t.text :body, null: false

      t.timestamps
    end
  end
end
