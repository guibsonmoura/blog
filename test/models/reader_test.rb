require "test_helper"

class ReaderTest < ActiveSupport::TestCase
  def auth_hash(provider: "google_oauth2", uid: "new-uid", email: "new@example.com", name: "New Reader", image: "https://example.test/new.png")
    OmniAuth::AuthHash.new(provider: provider, uid: uid, info: { email: email, name: name, image: image })
  end

  test "from_omniauth creates a reader on first sight" do
    assert_difference -> { Reader.count }, 1 do
      reader = Reader.from_omniauth(auth_hash)
      assert reader.persisted?
      assert_equal "google_oauth2", reader.provider
      assert_equal "new-uid", reader.uid
      assert_equal "new@example.com", reader.email
      assert_equal "New Reader", reader.name
      assert_equal "https://example.test/new.png", reader.avatar_url
    end
  end

  test "from_omniauth updates the existing reader on repeat sign-in" do
    existing = readers(:existing_google)

    assert_no_difference -> { Reader.count } do
      reader = Reader.from_omniauth(
        auth_hash(uid: existing.uid, email: "updated@example.com", name: "Updated Name", image: "https://example.test/updated.png")
      )
      assert_equal existing.id, reader.id
      assert_equal "updated@example.com", reader.email
      assert_equal "Updated Name", reader.name
      assert_equal "https://example.test/updated.png", reader.avatar_url
    end
  end

  test "uid uniqueness is scoped to provider" do
    existing = readers(:existing_google)

    # Same uid under a different provider is allowed.
    other = Reader.new(provider: "entra_id", uid: existing.uid)
    assert other.valid?

    # Same uid under the same provider is rejected.
    dup = Reader.new(provider: existing.provider, uid: existing.uid)
    assert_not dup.valid?
    assert_includes dup.errors[:uid], "has already been taken"
  end

  test "from_omniauth tolerates a missing name and email (e.g. minimal profile)" do
    reader = Reader.from_omniauth(auth_hash(uid: "no-name", email: "only@example.com", name: nil, image: nil))
    assert reader.persisted?
    # Falls back to the email local-part when no name is provided.
    assert_equal "only", reader.name
  end

  test "from_omniauth registers a Facebook reader" do
    reader = Reader.from_omniauth(auth_hash(provider: "facebook", uid: "fb-1", email: "fb@example.com", name: "FB User"))
    assert reader.persisted?
    assert_equal "facebook", reader.provider
    assert_equal "fb@example.com", reader.email
  end

  test "from_omniauth registers an X (twitter) reader without an email" do
    reader = Reader.from_omniauth(auth_hash(provider: "twitter", uid: "x-1", email: nil, name: "X User"))
    assert reader.persisted?
    assert_equal "twitter", reader.provider
    assert_nil reader.email
    assert_equal "X User", reader.name
  end

  test "requires provider and uid" do
    reader = Reader.new
    assert_not reader.valid?
    assert_includes reader.errors[:provider], "can't be blank"
    assert_includes reader.errors[:uid], "can't be blank"
  end
end
