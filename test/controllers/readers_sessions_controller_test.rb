require "test_helper"

class ReadersSessionsControllerTest < ActionDispatch::IntegrationTest
  test "successful callback creates a reader and sets the reader_token cookie" do
    assert_difference -> { Reader.count }, 1 do
      sign_in_reader(uid: "brand-new", email: "fresh@example.com", name: "Fresh Reader")
    end

    assert_response :redirect
    assert cookies[:reader_token].present?, "expected an encrypted reader_token cookie to be set"

    reader = Reader.find_by(provider: "google_oauth2", uid: "brand-new")
    assert_equal "fresh@example.com", reader.email
  end

  test "repeat sign-in reuses the existing reader" do
    existing = readers(:existing_google)

    assert_no_difference -> { Reader.count } do
      sign_in_reader(provider: existing.provider, uid: existing.uid, email: existing.email, name: existing.name)
    end
  end

  test "sign out clears the reader_token cookie" do
    sign_in_reader
    assert cookies[:reader_token].present?

    delete reader_logout_path

    assert_response :redirect
    assert cookies[:reader_token].blank?, "expected reader_token cookie to be cleared"
  end

  test "auth failure redirects to root with an alert" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

    post "/auth/google_oauth2"
    follow_redirect! # provider strategy redirects to /auth/failure

    assert_redirected_to root_path
    follow_redirect!
    assert_match I18n.t("auth.sign_in_failed"), response.body
  end

  test "GET to the provider request path is not a valid way to start auth" do
    # allowed_request_methods is POST only; a GET is not intercepted by the
    # OmniAuth middleware and has no matching route (sign-in must be a
    # CSRF-protected POST), so it 404s and never authenticates.
    get "/auth/google_oauth2"

    assert_response :not_found
    assert cookies[:reader_token].blank?
  end
end
