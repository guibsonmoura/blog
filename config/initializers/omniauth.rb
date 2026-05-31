# Public reader authentication (Google + Microsoft) via OmniAuth.
#
# Credentials are read from ENV first (this app is configured entirely through
# env vars — see .devcontainer/docker-compose.yml), falling back to Rails
# encrypted credentials. Placeholder defaults keep the middleware buildable in
# every environment; real sign-in obviously needs real values. In test the
# strategies are short-circuited by OmniAuth.config.test_mode + mock_auth.

OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.silence_get_warning = true

# Render our own failure handling instead of raising. Resolved lazily so the
# controller is not autoloaded at initialization time.
OmniAuth.config.on_failure = proc do |env|
  Readers::SessionsController.action(:failure).call(env)
end

secret = lambda do |env_key, *credentials_path, default|
  ENV[env_key].presence ||
    Rails.application.credentials.dig(*credentials_path).presence ||
    default
end

# A provider is "configured" only when a real value (not the placeholder) is
# present. The UI shows buttons only for configured providers, so unconfigured
# ones never 401.
configured = lambda do |env_key, *credentials_path|
  (ENV[env_key].presence || Rails.application.credentials.dig(*credentials_path).presence).present?
end

available = []
available << :google_oauth2 if configured.call("GOOGLE_CLIENT_ID", :google, :client_id)
available << :entra_id      if configured.call("MICROSOFT_CLIENT_ID", :microsoft, :client_id)
available << :facebook      if configured.call("FACEBOOK_CLIENT_ID", :facebook, :app_id)
available << :twitter       if configured.call("TWITTER_API_KEY", :twitter, :api_key)
# Local password-free sign-in for development only — never enable in production.
available << :developer if Rails.env.development?

Rails.application.config.x.reader_oauth_providers = available

Rails.application.config.middleware.use OmniAuth::Builder do
  # Development-only: a simple local form (name + email) that signs you in
  # without any external provider, so the comment flow is testable immediately.
  if Rails.env.development?
    provider :developer, fields: [ :name, :email ], uid_field: :email
  end

  provider :google_oauth2,
           secret.call("GOOGLE_CLIENT_ID", :google, :client_id, "google-client-id-not-set"),
           secret.call("GOOGLE_CLIENT_SECRET", :google, :client_secret, "google-client-secret-not-set"),
           scope: "email,profile",
           prompt: "select_account"

  # prompt: "select_account" forces Microsoft's account chooser too.
  provider :entra_id,
           client_id: secret.call("MICROSOFT_CLIENT_ID", :microsoft, :client_id, "microsoft-client-id-not-set"),
           client_secret: secret.call("MICROSOFT_CLIENT_SECRET", :microsoft, :client_secret, "microsoft-client-secret-not-set"),
           tenant_id: secret.call("MICROSOFT_TENANT_ID", :microsoft, :tenant_id, "common"),
           prompt: "select_account"

  # auth_type: "reauthenticate" makes Facebook re-prompt instead of silently
  # reusing the active session.
  provider :facebook,
           secret.call("FACEBOOK_CLIENT_ID", :facebook, :app_id, "facebook-app-id-not-set"),
           secret.call("FACEBOOK_CLIENT_SECRET", :facebook, :app_secret, "facebook-app-secret-not-set"),
           scope: "email",
           info_fields: "name,email,picture",
           auth_type: "reauthenticate"

  # "Sign in with X" via OAuth 1.0a. X does not return an email — Reader treats
  # email as optional and falls back to the profile name. force_login shows the
  # account/login screen instead of silently reusing the X session.
  provider :twitter,
           secret.call("TWITTER_API_KEY", :twitter, :api_key, "twitter-api-key-not-set"),
           secret.call("TWITTER_API_SECRET", :twitter, :api_secret, "twitter-api-secret-not-set"),
           { authorize_params: { force_login: "true" } }
end
