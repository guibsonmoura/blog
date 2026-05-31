class CreateCommentLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :comment_likes do |t|
      t.references :comment, null: false, foreign_key: { on_delete: :cascade }
      t.references :reader, null: true, foreign_key: { on_delete: :cascade }
      t.string :session_id

      t.timestamps
    end

    # One like per identity per comment (logged-in reader OR anonymous session),
    # same shape as the reactions indexes.
    add_index :comment_likes, [ :comment_id, :reader_id ], unique: true,
              where: "reader_id IS NOT NULL", name: "index_comment_likes_on_comment_and_reader"
    add_index :comment_likes, [ :comment_id, :session_id ], unique: true,
              where: "reader_id IS NULL", name: "index_comment_likes_on_comment_and_session"
  end
end
