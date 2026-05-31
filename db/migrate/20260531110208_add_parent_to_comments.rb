class AddParentToComments < ActiveRecord::Migration[8.1]
  def change
    # Self-reference for one-level replies. Top-level comments have parent_id
    # NULL; deleting a parent cascades to its replies.
    add_reference :comments, :parent, null: true,
                  foreign_key: { to_table: :comments, on_delete: :cascade }
  end
end
