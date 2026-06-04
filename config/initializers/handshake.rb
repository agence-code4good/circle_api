# frozen_string_literal: true

# Code de cette instance tel qu'il doit apparaître chez le partenaire (X-Partner-Code sortant).
# Surchargeable via HANDSHAKE_INSTANCE_CODE ; sinon linkage_code_remote sur la connexion.
Rails.application.config.handshake_instance_code = ENV.fetch("HANDSHAKE_INSTANCE_CODE", "circle")
