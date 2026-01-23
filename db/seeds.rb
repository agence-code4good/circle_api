# # code4good user

puts "Création de l'utilisateur admin..."

User.destroy_all

User.create!(admin: true, email: "dev@langagecircle.fr", password: 'LangageCircle2026!', password_confirmation: 'macpass')

puts "Utilisateur admin créé"

puts "Suppression des commandes..."

Order.destroy_all

puts "Commandes supprimées"

# partners

puts "Création des partenaires..."

Partner.destroy_all

Partner.create!(name: "Code4Good", code: "code4good")
Partner.create!(name: "Circle", code: "circle")
Partner.create!(name: "Château Gazin", code: "chateau_gazin")
Partner.create!(name: "La Cave à Part", code: "la_cave_a_part")

puts "Partenaires créés"

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
