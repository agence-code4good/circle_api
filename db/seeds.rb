# code4good user

puts "Création de l'utilisateur admin..."

User.destroy_all

user = User.create!(admin: true, email: "dev@langagecircle.fr", password: 'LangageCircle2026!', password_confirmation: 'LangageCircle2026!')

puts "Utilisateur admin créé"

puts "Suppression des logs et commandes..."

ApiLog.destroy_all
Order.destroy_all

puts "Logs et commandes supprimés"

# partners

puts "Création des partenaires..."

BrokerMandate.destroy_all
PartnerAlias.destroy_all
Partner.destroy_all

buyer_demo = Partner.create!(name: "BuyerDemo", code: "buyer_demo", auth_token_for_set: "BuyerDemoToken2026!")
user.update!(partner: buyer_demo)

seller_demo = Partner.create!(name: "SellerDemo", code: "seller_demo", auth_token_for_set: "SellerDemoToken2026!")
broker_demo = Partner.create!(name: "BrokerDemo", code: "broker_demo", auth_token_for_set: "BrokerDemoToken2026!")

puts "Partenaires créés avec tokens"

# partner aliases (code4good en tant que partenaire émetteur)
puts "Création des aliases partenaires..."

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

BrokerMandate.destroy_all
BrokerMandate.create!(broker_partner: broker_demo, buyer_partner: buyer_demo, active: true)

puts "Mandats courtier créés"

# circle products

puts "Création des produits Circle..."

file_path = Rails.root.join("specs", "examples", "circle_data_example.json")

unless File.exist?(file_path)
  puts "❌ Fichier circle_data_example.json non trouvé"
  exit
end

data = JSON.parse(File.read(file_path))

CircleProduct.destroy_all
puts "Anciens produits supprimés"

# Créer les produits
data.each_with_index do |product_data, index|
  product = CircleProduct.new

  product_data.each do |code, value|
    product.circle_codes.build(
      code: code,
      value: value
    )
  end

  if product.save
    puts "Produit #{index + 1} créé (#{product.circle_codes.count} codes)"
  else
    puts "Erreur création produit #{index + 1}: #{product.errors.full_messages.join(', ')}"
  end
end
