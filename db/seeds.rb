# frozen_string_literal: true

puts "=== Seed Circle API ==="

ApiLog.update_all(order_id: nil, partner_id: nil)
Order.destroy_all
puts "Commandes supprimées"

if Handshake::IdentityService.current
  puts "Identité instance (key_version=#{Handshake::IdentityService.current.key_version}) — GET /api/identity"
else
  puts "Identité instance absente — importer via CircUI (POST /api/admin/identity)"
end

BrokerMandate.destroy_all
PartnerAlias.destroy_all
User.update_all(partner_id: nil)
Partner.destroy_all

# Partenaires : chaque partenaire est une instance joignable (handshake v2),
# d'où remote_base_url + handshake_status obligatoires.
circle = Partner.create!(
  name: "Circle",
  code: "circle",
  remote_base_url: "http://localhost:3000",
  handshake_status: "pending"
)
buyer_demo = Partner.create!(
  name: "BuyerDemo",
  code: "buyer_demo",
  remote_base_url: "http://buyer-demo.circle.local",
  handshake_status: "pending",
  auth_token_for_set: "BuyerDemoToken2026!"
)
seller_demo = Partner.create!(
  name: "SellerDemo",
  code: "seller_demo",
  remote_base_url: "http://seller-demo.circle.local",
  handshake_status: "pending",
  auth_token_for_set: "SellerDemoToken2026!"
)
broker_demo = Partner.create!(
  name: "BrokerDemo",
  code: "broker_demo",
  remote_base_url: "http://broker-demo.circle.local",
  handshake_status: "pending",
  auth_token_for_set: "BrokerDemoToken2026!"
)

puts "Partenaires créés avec tokens"

User.destroy_all
user = User.create!(
  admin: true,
  email: "dev@langagecircle.fr",
  password: "LangageCircle2026!",
  password_confirmation: "LangageCircle2026!"
)
user.update!(partner: circle)
puts "Admin : #{user.email}"

# partner aliases
puts "Création des aliases partenaires..."

# Aliases quand BuyerDemo est l'émetteur (buyer)
PartnerAlias.create!(partner: buyer_demo, external_id: "ext_buyer_demo", partner_code: "buyer_demo")
PartnerAlias.create!(partner: buyer_demo, external_id: "ext_seller_demo", partner_code: "seller_demo")

# Aliases quand SellerDemo est l'émetteur (seller)
PartnerAlias.create!(partner: seller_demo, external_id: "ext_buyer_demo", partner_code: "buyer_demo")
PartnerAlias.create!(partner: seller_demo, external_id: "ext_seller_demo", partner_code: "seller_demo")

# Aliases quand le Courtier Demo est l'émetteur (broker)
# Les external_id sont "chez le broker" et sont résolus via PartnerAlias(partner_id = broker_demo.id)
PartnerAlias.create!(partner: broker_demo, external_id: "ext_broker_demo_buyer", partner_code: "buyer_demo")
PartnerAlias.create!(partner: broker_demo, external_id: "ext_broker_demo_seller", partner_code: "seller_demo")

puts "Aliases partenaires créés"

# broker mandates (courtier -> buyer)
puts "Création des mandats courtier..."

BrokerMandate.create!(broker_partner: broker_demo, buyer_partner: buyer_demo, active: true)

puts "Mandats courtier créés"

# circle products
puts "Création des produits Circle..."

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
puts "Tokens : à saisir dans admin Partners (colonne Token → Non défini)"
puts "=== Fin seed ==="
