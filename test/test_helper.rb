ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

# All translation tests stub HTTP via WebMock and never call the real translator.
# If you write a test that does need the live service, use this helper instead of
# relying on container startup order:
#
#   class MyLiveTranslationTest < ActiveSupport::TestCase
#     include TranslatorAvailabilityHelper
#     setup { wait_for_translator! }
#     ...
#   end
#
module TranslatorAvailabilityHelper
  TRANSLATOR_URL = ENV.fetch("TRANSLATION_SERVICE_URL", "http://localhost:8000")
  TIMEOUT_SECONDS = 120

  def wait_for_translator!
    deadline = Time.now + TIMEOUT_SECONDS
    loop do
      Net::HTTP.get_response(URI("#{TRANSLATOR_URL}/health")).tap do |r|
        return if r.is_a?(Net::HTTPSuccess)
      end
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError
      # not yet up
    end
    sleep 2
    skip "Translator service unavailable after #{TIMEOUT_SECONDS}s — skipping live test" if Time.now > deadline
  end
end

module AdminAuthenticationHelper
  def sign_in_as(user, password: "password12345")
    post superadmin_login_path, params: { email: user.email, password: password }
  end
end

# Drives the OmniAuth flow with a mocked provider response (no live OAuth call).
module ReaderAuthenticationHelper
  def sign_in_reader(provider: "google_oauth2", uid: "google-oauth-uid", email: "reader@example.com", name: "Reader One", image: "https://example.test/avatar.png")
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[provider.to_sym] = OmniAuth::AuthHash.new(
      provider: provider,
      uid: uid,
      info: { email: email, name: name, image: image }
    )
    post "/auth/#{provider}"   # request phase -> redirects to the callback
    follow_redirect!           # callback -> Readers::SessionsController#create
  end

  def reset_reader_oauth_mocks
    OmniAuth.config.mock_auth.clear
    OmniAuth.config.test_mode = false
  end
end

class ActionDispatch::IntegrationTest
  include AdminAuthenticationHelper
  include ReaderAuthenticationHelper

  teardown { reset_reader_oauth_mocks }
end
