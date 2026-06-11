# frozen_string_literal: true

# Dispatch vers un profil d'instance dédié pour les tests handshake à deux instances.
# SEED_INSTANCE=circle    → db/seeds/instance_circle.rb    (A, port 3000, catalogue)
# SEED_INSTANCE=code4good → db/seeds/instance_code4good.rb (B, port 3001, pair Circle)
seed_instance = ENV["SEED_INSTANCE"].to_s.strip
if seed_instance.present?
  profile = Rails.root.join("db/seeds/instance_#{seed_instance}.rb")
  if File.exist?(profile)
    load profile
    return
  else
    abort "SEED_INSTANCE=#{seed_instance} mais #{profile} introuvable"
  end
end

puts "=== Seed Circle API ==="

ApiLog.update_all(order_id: nil, partner_id: nil, partner_connection_id: nil)
Order.destroy_all
puts "Commandes supprimées"

identity = Handshake::IdentityService.ensure!
puts "Identité instance (key_version=#{identity.key_version}) — GET /api/identity"

PartnerConnection.destroy_all
PartnerAlias.destroy_all
User.update_all(partner_id: nil)
Partner.destroy_all

code4good = Partner.create!(name: "Code4Good", code: "code4good")
circle = Partner.create!(name: "Circle", code: "circle")
chateau_gazin = Partner.create!(name: "Château Gazin", code: "chateau_gazin")
la_cave_a_part = Partner.create!(name: "La Cave à Part", code: "la_cave_a_part")

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

puts "Connexions inter-partenaires : à configurer dans ActiveAdmin (Partner connections)"
puts "=== Fin seed ==="
