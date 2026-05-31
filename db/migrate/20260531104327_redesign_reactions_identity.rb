class RedesignReactionsIdentity < ActiveRecord::Migration[8.1]
  def up
    # Logged-in readers own their reactions; anonymous visitors keep using the
    # durable signed-cookie session_id.
    add_reference :reactions, :reader, null: true, foreign_key: { on_delete: :cascade }
    change_column_null :reactions, :session_id, true

    # Collapse any pre-existing stacked reactions to a single row per anonymous
    # identity per post (keep the earliest), so the new unique index can apply.
    execute <<~SQL.squish
      DELETE FROM reactions a USING reactions b
      WHERE a.reader_id IS NULL AND b.reader_id IS NULL
        AND a.post_id = b.post_id AND a.session_id = b.session_id
        AND a.id > b.id
    SQL

    remove_index :reactions, name: "index_reactions_on_post_id_and_session_id_and_reaction_type"

    # One reaction per identity per post (single choice).
    add_index :reactions, [ :post_id, :reader_id ], unique: true,
              where: "reader_id IS NOT NULL", name: "index_reactions_on_post_and_reader"
    add_index :reactions, [ :post_id, :session_id ], unique: true,
              where: "reader_id IS NULL", name: "index_reactions_on_post_and_session"
  end

  def down
    remove_index :reactions, name: "index_reactions_on_post_and_session"
    remove_index :reactions, name: "index_reactions_on_post_and_reader"
    add_index :reactions, [ :post_id, :session_id, :reaction_type ], unique: true,
              name: "index_reactions_on_post_id_and_session_id_and_reaction_type"
    change_column_null :reactions, :session_id, false
    remove_reference :reactions, :reader, foreign_key: true
  end
end
