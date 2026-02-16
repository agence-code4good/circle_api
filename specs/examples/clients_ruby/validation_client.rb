#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'uri'

# Configuration
BASE_URL = 'http://localhost:3000'
AUTH_TOKEN = 'Cs32ogGNFoUbY5rDEhMM4kdm'

# Fonction helper pour faire des requêtes POST
def post_json(path, body)
  uri = URI.join(BASE_URL, path)
  request = Net::HTTP::Post.new(uri)
  request['Authorization'] = "Bearer #{AUTH_TOKEN}"
  request['Content-Type'] = 'application/json'
  request.body = body.to_json

  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  
  {
    status: response.code.to_i,
    body: JSON.parse(response.body)
  }
rescue => e
  puts "Erreur: #{e.message}"
  nil
end

# ===========================
# Exemple 1: Validation réussie
# ===========================
puts "=== Validation réussie ==="

circle_values = {
  "C0" => "11",
  "CLE" => "038",
  "C1" => "A0",
  "C2" => "6",
  "C3" => "A1",
  "C4" => "A0",
  "C5" => "00",
  "C6" => "9500",
  "C10" => "5238A0",
  "C11" => "2017",
  "C13" => "A7"
}

result = post_json('/api/v1/validation', { version: "11", circle_values: circle_values })

if result
  if result[:status] == 200 && result[:body]['circle_key']
    puts "✓ Validation réussie!"
    puts "Circle Key: #{result[:body]['circle_key']}"
    puts "Codes validés: #{result[:body]['circle_code'].count}"
  elsif result[:body]['errors']
    puts "✗ Codes en erreur: #{result[:body]['errors'].join(', ')}"
  end
end

# ===========================
# Exemple 2: Validation avec erreurs
# ===========================
puts "\n=== Validation avec erreurs ==="

invalid_values = {
  "C0" => "99",  # Invalide
  "C1" => "XX"   # Invalide
}

result = post_json('/api/v1/validation', { circle_values: invalid_values })

if result && result[:body]['errors']
  puts "✗ Codes invalides: #{result[:body]['errors'].join(', ')}"
  
  result[:body]['circle_code'].each do |code_result|
    next if code_result['valid']
    puts "  - #{code_result['circle_code']}: #{code_result['errors'].join(', ')}"
  end
end

# ===========================
# Exemple 3: Token invalide
# ===========================
puts "\n=== Test avec token invalide ==="

# Sauvegarder le token original
auth_token_backup = AUTH_TOKEN
Object.send(:remove_const, :AUTH_TOKEN)
AUTH_TOKEN = 'INVALID_TOKEN'

def post_json_with_invalid_token(path, body, token)
  uri = URI.join(BASE_URL, path)
  request = Net::HTTP::Post.new(uri)
  request['Authorization'] = "Bearer #{token}"
  request['Content-Type'] = 'application/json'
  request.body = body.to_json

  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  
  {
    status: response.code.to_i,
    body: response.body
  }
rescue => e
  puts "Erreur: #{e.message}"
  nil
end

result = post_json_with_invalid_token('/api/v1/validation', { circle_values: { "C0" => "11" } }, 'INVALID_TOKEN')

if result && result[:status] == 401
  puts "✗ Authentification échouée (attendu)"
end
