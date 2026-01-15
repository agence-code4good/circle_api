#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'uri'

# Configuration
BASE_URL = 'http://localhost:3000'
AUTH_TOKEN = 'Cs32ogGNFoUbY5rDEhMM4kdm'

# Helpers HTTP
def post_json(path, body)
  uri = URI.join(BASE_URL, path)
  request = Net::HTTP::Post.new(uri)
  request['Authorization'] = "Bearer #{AUTH_TOKEN}"
  request['Content-Type'] = 'application/json'
  request.body = body.to_json

  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  
  # Gérer les réponses non-JSON (HTML, etc.)
  begin
    body = JSON.parse(response.body)
  rescue JSON::ParserError
    body = { error: "HTML response received (status: #{response.code})" }
  end
  
  { status: response.code.to_i, body: body }
rescue => e
  puts "Erreur: #{e.message}"
  nil
end

def patch_json(path, body)
  uri = URI.join(BASE_URL, path)
  request = Net::HTTP::Patch.new(uri)
  request['Authorization'] = "Bearer #{AUTH_TOKEN}"
  request['Content-Type'] = 'application/json'
  request.body = body.to_json

  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  
  # Gérer les réponses non-JSON (HTML, etc.)
  begin
    body = JSON.parse(response.body)
  rescue JSON::ParserError
    body = { error: "HTML response received (status: #{response.code})" }
  end
  
  { status: response.code.to_i, body: body }
rescue => e
  puts "Erreur: #{e.message}"
  nil
end

def get_json(path)
  uri = URI.join(BASE_URL, path)
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{AUTH_TOKEN}"

  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  
  # Gérer les réponses non-JSON (HTML, etc.)
  begin
    body = JSON.parse(response.body)
  rescue JSON::ParserError
    body = { error: "HTML response received (status: #{response.code})" }
  end
  
  { status: response.code.to_i, body: body }
rescue => e
  puts "Erreur: #{e.message}"
  nil
end

# ===========================
# Exemple 1: Créer une commande
# ===========================
puts "=== Créer une commande ==="

order_reference = "ORD-#{Time.now.to_i}"

order_data = {
  order: {
    order_reference: order_reference,
    buyer_id: "code4good",  # Code du partner, pas l'ID numérique
    seller_id: "circle",     # Code d'un autre partner
    status: "nouvelle_commande",
    note: "Commande test depuis le client Ruby",
    order_lines_attributes: [
      {
        circle_code: {
          "C0" => "11",
          "CLE" => "038",  # Clé Circle valide pour ces valeurs
          "C1" => "A0",
          "C2" => "6",
          "C10" => "5238A0",
          "C11" => "2017"
        }
      }
    ]
  }
}

result = post_json('/api/v1/orders', order_data)

if result && result[:status] == 201
  order = result[:body]['order']
  puts "✓ Commande créée!"
  puts "  Référence: #{order['order_reference']}"
  puts "  Statut: #{order['status']}"
  puts "  Lignes: #{order['order_lines']&.count || 0}"
elsif result
  puts "✗ Erreur: #{result[:body]['errors'] || result[:body]['error']}"
end

# ===========================
# Exemple 2: Récupérer une commande
# ===========================
puts "\n=== Récupérer une commande ==="

result = get_json("/api/v1/orders/#{order_reference}")

if result && result[:status] == 200
  if result[:body]['error']
    puts "⚠ Endpoint non implémenté (manque la vue jbuilder)"
  else
    order = result[:body]['order']
    puts "✓ Commande trouvée:"
    puts "  Référence: #{order['order_reference']}"
    puts "  Statut: #{order['status']}"
  end
elsif result && result[:status] == 404
  puts "✗ Commande non trouvée"
end

# ===========================
# Exemple 3: Mettre à jour une commande
# ===========================
puts "\n=== Mettre à jour une commande ==="

# Utiliser un statut valide selon l'enum Order
# Si le buyer veut passer à un statut, il doit utiliser un statut autorisé
# Depuis "nouvelle_commande", le buyer peut aller vers "annulee_acheteur"
update_data = {
  order: {
    status: "en_attente_demande_de_mise",  # Statut accessible par le seller
    note: "Commande en attente"
  }
}

result = patch_json("/api/v1/orders/#{order_reference}", update_data)

if result && result[:status] == 200
  order = result[:body]['order']
  puts "✓ Commande mise à jour!"
  puts "  Nouveau statut: #{order['status']}"
elsif result
  puts "✗ Erreur: #{result[:body]['error'] || result[:body]['errors']}"
end

# ===========================
# Exemple 4: Lister les commandes
# ===========================
puts "\n=== Lister les commandes ==="

result = get_json('/api/v1/orders')

if result && result[:status] == 200
  if result[:body]['error']
    puts "⚠ Endpoint non implémenté (manque la vue jbuilder)"
  else
    orders = result[:body]['orders'] || []
    puts "✓ #{orders.count} commande(s) trouvée(s)"
    
    orders.first(3).each do |order|
      puts "  - #{order['order_reference']}: #{order['status']}"
    end
  end
end
