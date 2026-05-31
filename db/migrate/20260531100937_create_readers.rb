class CreateReaders < ActiveRecord::Migration[8.1]
  def change
    create_table :readers do |t|
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email
      t.string :name
      t.string :avatar_url

      t.timestamps
    end

    # Natural key: a person is identified by (provider, uid), never by email
    # (the same email can sign in through multiple providers).
    add_index :readers, [ :provider, :uid ], unique: true
  end
end
