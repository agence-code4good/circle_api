#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'uri'

# Configuration
BASE_URL = 'http://localhost:3000'
AUTH_TOKEN = 'Cs32ogGNFoUbY5rDEhMM4kdm'

puts "=" * 80
puts "TEST DE TOUS LES CLIENTS RUBY DE L'API CIRCLE"
puts "=" * 80
puts "\nURL: #{BASE_URL}"
puts "Token: #{AUTH_TOKEN[0..10]}..."
puts "\n"

# Helper HTTP
def get_json(path)
  uri = URI.join(BASE_URL, path)
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{AUTH_TOKEN}"

  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  
  begin
    body = JSON.parse(response.body)
  rescue JSON::ParserError
    body = { error: "HTML response" }
  end
  
  { status: response.code.to_i, body: body }
rescue => e
  { status: 0, body: { error: e.message } }
end

def post_json(path, body)
  uri = URI.join(BASE_URL, path)
  request = Net::HTTP::Post.new(uri)
  request['Authorization'] = "Bearer #{AUTH_TOKEN}"
  request['Content-Type'] = 'application/json'
  request.body = body.to_json

  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  
  begin
    body = JSON.parse(response.body)
  rescue JSON::ParserError
    body = { error: "HTML response" }
  end
  
  { status: response.code.to_i, body: body }
rescue => e
  { status: 0, body: { error: e.message } }
end

# Test 1: Products (GET /api/v1/products)
puts "[1/4] Test du client Products..."
result = get_json('/api/v1/products')
if result[:status] == 200 && result[:body].is_a?(Array)
  puts "  ✓ GET /api/v1/products : #{result[:body].count} produits trouvés"
else
  puts "  ✗ GET /api/v1/products : ÉCHEC (status: #{result[:status]})"
end

# Test 2: Products Show (GET /api/v1/products/:c10)
result = get_json('/api/v1/products/5238A0')
if result[:status] == 200 && result[:body]['product']
  puts "  ✓ GET /api/v1/products/5238A0 : Produit trouvé"
else
  puts "  ✗ GET /api/v1/products/5238A0 : ÉCHEC (status: #{result[:status]})"
end

# Test 3: Validation (POST /api/v1/validation)
puts "\n[2/4] Test du client Validation..."
result = post_json('/api/v1/validation', {
  circle_values: {
    "C0" => "11",
    "C1" => "A0",
    "C10" => "5238A0"
  }
})
if result[:status] == 200
  if result[:body]['circle_key']
    puts "  ✓ POST /api/v1/validation : Validation réussie (circle_key: #{result[:body]['circle_key']})"
  elsif result[:body]['errors']
    puts "  ✓ POST /api/v1/validation : Erreurs détectées (#{result[:body]['errors'].count} code(s) en erreur)"
  else
    puts "  ⚠ POST /api/v1/validation : Réponse inattendue"
  end
else
  puts "  ✗ POST /api/v1/validation : ÉCHEC (status: #{result[:status]})"
end

# Test 4: Orders Create (POST /api/v1/orders)
puts "\n[3/4] Test du client Orders..."
order_reference = "TEST-#{Time.now.to_i}"
result = post_json('/api/v1/orders', {
  order: {
    order_reference: order_reference,
    buyer_id: "code4good",
    seller_id: "circle",
    status: "nouvelle_commande",
    note: "Commande de test automatique",
    order_lines_attributes: [
      {
        circle_code: {
          "C0" => "11",
          "CLE" => "038",
          "C1" => "A0",
          "C2" => "6",
          "C10" => "5238A0",
          "C11" => "2017"
        }
      }
    ]
  }
})
if result[:status] == 201
  puts "  ✓ POST /api/v1/orders : Commande créée (ref: #{order_reference})"
else
  error_msg = result[:body]['error'] || result[:body]['errors'] || 'Unknown error'
  puts "  ✗ POST /api/v1/orders : ÉCHEC (status: #{result[:status]}, error: #{error_msg})"
end

# Test 5: Circle Values Search (POST /api/v1/search_circle_values)
puts "\n[4/4] Test du client Circle Values..."
result = post_json('/api/v1/search_circle_values', {
  input_values: {
    "C0" => "11",
    "CLE" => "038",
    "C1" => "A0",
    "C2" => "6",
    "C3" => "A1",
    "C4" => "A0",
    "C5" => "00",
    "C10" => "5238A0",
    "C11" => "2017",
    "C13" => "A7"
  },
  searched_values: ["C6", "C7"]
})
if result[:status] == 200 && result[:body]['circle_values']
  puts "  ✓ POST /api/v1/search_circle_values : #{result[:body]['circle_values'].keys.count} valeur(s) trouvée(s)"
elsif result[:status] == 400
  puts "  ⚠ POST /api/v1/search_circle_values : Erreur attendue (#{result[:body]['error']})"
elsif result[:status] == 404
  puts "  ⚠ POST /api/v1/search_circle_values : Aucune donnée trouvée (normal avec données de test)"
else
  puts "  ✗ POST /api/v1/search_circle_values : ÉCHEC (status: #{result[:status]})"
end

# Résumé
puts "\n" + "=" * 80
puts "TESTS TERMINÉS"
puts "=" * 80
puts "\nPour plus de détails, exécutez les clients individuellement :"
puts "  ruby validation_client.rb"
puts "  ruby orders_client.rb"
puts "  ruby products_client.rb"
puts "  ruby circle_values_client.rb"
puts "\n"
