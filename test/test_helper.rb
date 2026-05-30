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

module AdminAuthenticationHelper
  def sign_in_as(user, password: "password12345")
    post superadmin_login_path, params: { email: user.email, password: password }
  end
end

class ActionDispatch::IntegrationTest
  include AdminAuthenticationHelper
end
