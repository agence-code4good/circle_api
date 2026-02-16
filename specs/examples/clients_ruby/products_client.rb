#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'uri'

# Configuration
BASE_URL = 'http://localhost:3000'
AUTH_TOKEN = 'Cs32ogGNFoUbY5rDEhMM4kdm'

# Helper HTTP
def get_json(path)
  uri = URI.join(BASE_URL, path)
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{AUTH_TOKEN}"

  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  
  # Gérer les réponses non-JSON (HTML, etc.)
  begin
    body = JSON.parse(response.body)
  rescue JSON::ParserError
    body = response.body
  end
  
  { status: response.code.to_i, body: body }
rescue => e
  puts "Erreur: #{e.message}"
  nil
end

# ===========================
# Exemple 1: Lister tous les produits
# ===========================
puts "=== Lister tous les produits ==="

result = get_json('/api/v1/products')

if result && result[:status] == 200
  products = result[:body]
  puts "✓ #{products.count} produit(s) trouvé(s)"
  
  products.first(10).each do |product|
    puts "  - #{product['c10']}: #{product['label']}"
  end
end

# ===========================
# Exemple 2: Récupérer un produit spécifique
# ===========================
puts "\n=== Récupérer un produit spécifique ==="

c10_code = "5238A0"

result = get_json("/api/v1/products/#{c10_code}")

if result && result[:status] == 200
  product = result[:body]['product']  # La réponse est wrappée dans 'product'
  puts "✓ Produit trouvé:"
  puts "  C10: #{product['c10']}"
  puts "  Label: #{product['label']}"
  puts "  Nom: #{product['name']}" if product['name']
  puts "  Couleur: #{product['color']}" if product['color']
elsif result && result[:status] == 404
  puts "✗ Produit non trouvé"
end

# ===========================
# Exemple 3: Produit inexistant
# ===========================
puts "\n=== Test produit inexistant ==="

result = get_json("/api/v1/products/XXXXX")

if result
  if result[:status] == 200 && result[:body]['product'].nil?
    puts "✗ Produit non trouvé (produit nil retourné)"
  elsif result[:status] == 404
    puts "✗ Produit non trouvé (404)"
  elsif result[:status] == 200
    puts "⚠ Requête réussie mais produit vide"
  else
    puts "✗ Statut inattendu: #{result[:status]}"
  end
end
