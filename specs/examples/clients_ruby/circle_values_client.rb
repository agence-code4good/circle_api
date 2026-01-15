#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'uri'

# Configuration
BASE_URL = 'http://localhost:3000'
AUTH_TOKEN = 'Cs32ogGNFoUbY5rDEhMM4kdm'

# Helper HTTP
def post_json(path, body)
  uri = URI.join(BASE_URL, path)
  request = Net::HTTP::Post.new(uri)
  request['Authorization'] = "Bearer #{AUTH_TOKEN}"
  request['Content-Type'] = 'application/json'
  request.body = body.to_json

  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  { status: response.code.to_i, body: JSON.parse(response.body) }
rescue => e
  puts "Erreur: #{e.message}"
  nil
end

# ===========================
# Exemple 1: Recherche réussie
# ===========================
puts "=== Recherche de circle values ==="

input_values = {
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
}

searched_values = ["C6", "C7", "C8", "C9"]

search_data = {
  input_values: input_values,
  searched_values: searched_values
}

result = post_json('/api/v1/search_circle_values', search_data)

if result && result[:status] == 200
  circle_values = result[:body]['circle_values']
  puts "✓ Recherche réussie! #{circle_values.keys.count} valeur(s) trouvée(s):"
  
  circle_values.each do |code, data|
    puts "  - #{code}: #{data['label']} = #{data['circle_value']} (raw: #{data['value']})"
  end
elsif result && result[:status] == 404
  puts "✗ Aucune donnée trouvée"
elsif result && result[:status] == 400
  puts "✗ Erreur: #{result[:body]['error']}"
end

# ===========================
# Exemple 2: Champs obligatoires manquants
# ===========================
puts "\n=== Test champs manquants ==="

incomplete_input = {
  "C0" => "11"
  # CLE, C10, C11 manquants
}

result = post_json('/api/v1/search_circle_values', {
  input_values: incomplete_input,
  searched_values: ["C6"]
})

if result && result[:status] == 400
  puts "✗ Erreur (attendu): #{result[:body]['error']}"
end

# ===========================
# Exemple 3: Clé Circle invalide
# ===========================
puts "\n=== Test clé invalide ==="

invalid_key_input = {
  "C0" => "11",
  "CLE" => "000",  # Clé incorrecte
  "C10" => "5238A0",
  "C11" => "2017"
}

result = post_json('/api/v1/search_circle_values', {
  input_values: invalid_key_input,
  searched_values: ["C6"]
})

if result && result[:status] == 400
  puts "✗ Erreur (attendu): #{result[:body]['error']}"
end

# ===========================
# Exemple 4: Dépendances manquantes
# ===========================
puts "\n=== Test dépendances manquantes ==="

missing_deps_input = {
  "C0" => "11",
  "CLE" => "038",
  "C10" => "5238A0",
  "C11" => "2017"
  # C1, C2, C3, C4, C5, C13 manquants (requis pour C6)
}

result = post_json('/api/v1/search_circle_values', {
  input_values: missing_deps_input,
  searched_values: ["C6"]
})

if result && result[:status] == 400
  puts "✗ Erreur (attendu): #{result[:body]['error']}"
end
