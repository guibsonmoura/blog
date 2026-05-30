class CreateReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :reactions do |t|
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.integer :reaction_type, null: false
      t.string :session_id, null: false

      t.datetime :created_at, null: false
    end

    add_index :reactions, [ :post_id, :session_id, :reaction_type ], unique: true
  end
end
