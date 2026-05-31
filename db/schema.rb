# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_31_110209) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "comment_likes", force: :cascade do |t|
    t.bigint "comment_id", null: false
    t.datetime "created_at", null: false
    t.bigint "reader_id"
    t.string "session_id"
    t.datetime "updated_at", null: false
    t.index ["comment_id", "reader_id"], name: "index_comment_likes_on_comment_and_reader", unique: true, where: "(reader_id IS NOT NULL)"
    t.index ["comment_id", "session_id"], name: "index_comment_likes_on_comment_and_session", unique: true, where: "(reader_id IS NULL)"
    t.index ["comment_id"], name: "index_comment_likes_on_comment_id"
    t.index ["reader_id"], name: "index_comment_likes_on_reader_id"
  end

  create_table "comments", force: :cascade do |t|
    t.string "author_email"
    t.string "author_name", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "parent_id"
    t.bigint "post_id", null: false
    t.bigint "reader_id"
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["reader_id"], name: "index_comments_on_reader_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text "body_markdown", null: false
    t.text "body_markdown_en"
    t.datetime "created_at", null: false
    t.text "excerpt", null: false
    t.string "excerpt_en"
    t.datetime "published_at"
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.string "title_en"
    t.string "translation_status", default: "pending"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["slug"], name: "index_posts_on_slug", unique: true
    t.index ["status", "published_at"], name: "index_posts_on_status_and_published_at"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "reactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.integer "reaction_type", null: false
    t.bigint "reader_id"
    t.string "session_id"
    t.index ["post_id", "reader_id"], name: "index_reactions_on_post_and_reader", unique: true, where: "(reader_id IS NOT NULL)"
    t.index ["post_id", "session_id"], name: "index_reactions_on_post_and_session", unique: true, where: "(reader_id IS NULL)"
    t.index ["post_id"], name: "index_reactions_on_post_id"
    t.index ["reader_id"], name: "index_reactions_on_reader_id"
  end

  create_table "readers", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_readers_on_provider_and_uid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comment_likes", "comments", on_delete: :cascade
  add_foreign_key "comment_likes", "readers", on_delete: :cascade
  add_foreign_key "comments", "comments", column: "parent_id", on_delete: :cascade
  add_foreign_key "comments", "posts", on_delete: :cascade
  add_foreign_key "comments", "readers", on_delete: :nullify
  add_foreign_key "posts", "users"
  add_foreign_key "reactions", "posts", on_delete: :cascade
  add_foreign_key "reactions", "readers", on_delete: :cascade
end
