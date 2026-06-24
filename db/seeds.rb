# frozen_string_literal: true

puts "=== Seed Circle API ==="

ApiLog.update_all(order_id: nil, partner_id: nil)
Order.destroy_all
puts "Commandes supprimées"

if Handshake::IdentityService.current
  puts "Identité instance (key_version=#{Handshake::IdentityService.current.key_version}) — GET /api/identity"
elsif ENV["PUBLIC_KEY"].present? && ENV["PRIVATE_KEY"].present?
  identity = Handshake::IdentityService.import!(
    public_key: ENV.fetch("PUBLIC_KEY"),
    private_key: ENV.fetch("PRIVATE_KEY"),
    key_version: ENV.fetch("KEY_VERSION", "1").to_i
  )
  puts "Identité instance importée (key_version=#{identity.key_version})"
else
  puts "Identité instance absente — importer via CircUI (handshake:import_identity)"
end

PartnerAlias.destroy_all
User.update_all(partner_id: nil)
Partner.destroy_all

code4good = Partner.create!(
  name: "Code4Good",
  code: "code4good",
  remote_base_url: "http://localhost:3001",
  handshake_status: "pending"
)
circle = Partner.create!(
  name: "Circle",
  code: "circle",
  remote_base_url: "http://localhost:3000",
  handshake_status: "pending"
)
chateau_gazin = Partner.create!(
  name: "Château Gazin",
  code: "chateau_gazin",
  remote_base_url: "http://chateau-gazin.circle.local",
  handshake_status: "pending"
)
la_cave_a_part = Partner.create!(
  name: "La Cave à Part",
  code: "la_cave_a_part",
  remote_base_url: "http://la-cave-a-part.circle.local",
  handshake_status: "pending"
)

User.destroy_all
user = User.create!(
  admin: true,
  email: "dev@langagecircle.fr",
  password: "LangageCircle2026!",
  password_confirmation: "LangageCircle2026!"
)
user.update!(partner: circle)
puts "Admin : #{user.email}"

PartnerAlias.create!(partner: code4good, external_id: "ext_code4good", partner_code: "code4good")
PartnerAlias.create!(partner: code4good, external_id: "ext_circle", partner_code: "circle")
PartnerAlias.create!(partner: code4good, external_id: "ext_chateau_gazin", partner_code: "chateau_gazin")
PartnerAlias.create!(partner: code4good, external_id: "ext_la_cave_a_part", partner_code: "la_cave_a_part")

PartnerAlias.create!(partner: circle, external_id: "ext_code4good", partner_code: "code4good")
PartnerAlias.create!(partner: circle, external_id: "ext_circle", partner_code: "circle")
PartnerAlias.create!(partner: circle, external_id: "ext_chateau_gazin", partner_code: "chateau_gazin")
PartnerAlias.create!(partner: circle, external_id: "ext_la_cave_a_part", partner_code: "la_cave_a_part")

PartnerAlias.create!(partner: chateau_gazin, external_id: "ext_code4good", partner_code: "code4good")
PartnerAlias.create!(partner: chateau_gazin, external_id: "ext_chateau_gazin", partner_code: "chateau_gazin")

puts "Aliases partenaires créés"
puts "Tokens générés à la création — voir admin Partners pour les transmettre hors bande"

file_path = Rails.root.join("specs", "examples", "circle_data_example.json")
if File.exist?(file_path)
  data = JSON.parse(File.read(file_path))
  CircleProduct.destroy_all
  data.each_with_index do |product_data, index|
    product = CircleProduct.new
    product_data.each do |code, value|
      product.circle_codes.build(code: code, value: value)
    end
    puts "Erreur produit #{index + 1}: #{product.errors.full_messages.join(', ')}" unless product.save
  end
  puts "#{CircleProduct.count} produit(s) Circle"
else
  puts "Fichier circle_data_example.json absent — produits ignorés"
end

puts "Handshake : configurer clés publiques + challenges dans admin Partners"
puts "=== Fin seed ==="
