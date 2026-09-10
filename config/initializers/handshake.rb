# frozen_string_literal: true

# Code de cette instance tel qu'il doit apparaître chez le partenaire (X-Partner-Code sortant).
Rails.application.config.handshake_instance_code = ENV.fetch("HANDSHAKE_INSTANCE_CODE", "circle")

# Token Bearer pour POST /api/admin/identity (import CircUI).
Rails.application.config.handshake_identity_import_token = ENV["HANDSHAKE_IDENTITY_IMPORT_TOKEN"].presence
