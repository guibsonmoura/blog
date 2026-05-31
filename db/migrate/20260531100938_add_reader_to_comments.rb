class AddReaderToComments < ActiveRecord::Migration[8.1]
  def change
    # Nullable so existing anonymous comments keep working. New comments are
    # always tied to a signed-in reader (see CommentsController#create).
    add_reference :comments, :reader, null: true, foreign_key: { on_delete: :nullify }
  end
end
