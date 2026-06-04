# frozen_string_literal: true

Rails.application.configure do
  config.active_record.encryption.support_unencrypted_data = true

  if Rails.env.test?
    config.active_record.encryption.primary_key = "test_primary_key_32_chars_long!!"
    config.active_record.encryption.deterministic_key = "test_deterministic_key_32!!"
    config.active_record.encryption.key_derivation_salt = "test_encryption_salt_value"
  end
end
