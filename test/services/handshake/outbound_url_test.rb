# frozen_string_literal: true

require "test_helper"

class Handshake::OutboundUrlTest < ActiveSupport::TestCase
  setup do
    @previous_rewrite = ENV["HANDSHAKE_OUTBOUND_REWRITE"]
    ENV["HANDSHAKE_OUTBOUND_REWRITE"] = "true"
  end

  teardown do
    if @previous_rewrite.nil?
      ENV.delete("HANDSHAKE_OUTBOUND_REWRITE")
    else
      ENV["HANDSHAKE_OUTBOUND_REWRITE"] = @previous_rewrite
    end
  end

  test "leaves unknown hosts unchanged" do
    assert_equal "http://example.com", Handshake::OutboundUrl.resolve("http://example.com")
  end

  test "rewrites localhost:3000 for docker outbound calls" do
    ENV["HANDSHAKE_OUTBOUND_URL_3000"] = "http://app"
    assert_equal "http://app", Handshake::OutboundUrl.resolve("http://localhost:3000")
  end

  test "rewrites localhost:3001 to peer service" do
    ENV["HANDSHAKE_OUTBOUND_URL_3001"] = "http://app_b"
    assert_equal "http://app_b", Handshake::OutboundUrl.resolve("http://localhost:3001/")
  end

  test "does not rewrite when disabled" do
    ENV["HANDSHAKE_OUTBOUND_REWRITE"] = "false"
    assert_equal "http://localhost:3000", Handshake::OutboundUrl.resolve("http://localhost:3000")
  end
end
