ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "support/handshake_test_helper"

module ActiveSupport
  class TestCase
    include HandshakeTestHelper

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup do
      InstanceIdentity.delete_all
      HandshakeNonce.delete_all
      Rails.application.config.handshake_identity_import_token = "test-import-token"
      setup_handshake_identity!
    end
  end
end
