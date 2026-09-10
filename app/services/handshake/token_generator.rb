# frozen_string_literal: true

require "securerandom"

module Handshake
  class TokenGenerator
    TOKEN_BYTES = 32

    class << self
      def generate
        SecureRandom.urlsafe_base64(TOKEN_BYTES)
      end
    end
  end
end
