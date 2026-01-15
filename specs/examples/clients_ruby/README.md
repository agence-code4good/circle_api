# Clients Ruby pour l'API Circle

Clients d'exemple simples pour consommer les 4 endpoints de l'API Circle.

**Emplacement :** `specs/examples/clients_ruby/`

## Prérequis

- Ruby 2.7+
- Serveur API Circle en cours d'exécution sur `http://localhost:3000`
- Token d'authentification valide

## Configuration

Modifiez les constantes en haut de chaque fichier :

```ruby
BASE_URL = 'http://localhost:3000'
AUTH_TOKEN = 'votre_token_ici'
```

## Utilisation

Chaque fichier est un script Ruby autonome :

```bash
# Validation de circle codes
ruby validation_client.rb

# Gestion des commandes (CRUD)
ruby orders_client.rb

# Consultation du catalogue produits
ruby products_client.rb

# Recherche de circle values
ruby circle_values_client.rb
```

## Endpoints couverts

### 1. Validations (`validation_client.rb`)
- `POST /api/v1/validation` - Valider des circle codes

### 2. Orders (`orders_client.rb`)
- `POST /api/v1/orders` - Créer une commande
- `GET /api/v1/orders/:order_reference` - Récupérer une commande
- `PATCH /api/v1/orders/:order_reference` - Mettre à jour une commande
- `GET /api/v1/orders` - Lister les commandes

### 3. Products (`products_client.rb`)
- `GET /api/v1/products` - Lister tous les produits
- `GET /api/v1/products/:c10` - Récupérer un produit

### 4. Circle Values (`circle_values_client.rb`)
- `POST /api/v1/search_circle_values` - Rechercher des circle values

## Gestion des erreurs

Les scripts affichent simplement les erreurs HTTP retournées par l'API :
- `200` - Succès
- `201` - Création réussie
- `400` - Requête invalide
- `401` - Non authentifié
- `403` - Accès interdit
- `404` - Ressource non trouvée
- `422` - Erreur de validation

## Format des réponses

Chaque helper retourne :

```ruby
{
  status: 200,           # Code HTTP
  body: { ... }          # JSON parsé
}
```

En cas d'erreur réseau, `nil` est retourné.

## Exemples d'utilisation

### Validation

```ruby
require 'net/http'
require 'json'
require 'uri'

BASE_URL = 'http://localhost:3000'
AUTH_TOKEN = 'votre_token'

def post_json(path, body)
  uri = URI.join(BASE_URL, path)
  request = Net::HTTP::Post.new(uri)
  request['Authorization'] = "Bearer #{AUTH_TOKEN}"
  request['Content-Type'] = 'application/json'
  request.body = body.to_json

  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  { status: response.code.to_i, body: JSON.parse(response.body) }
end

result = post_json('/api/v1/validation', {
  circle_values: { "C0" => "11", "C1" => "A0" }
})

puts result[:body]['circle_key'] if result[:status] == 200
```

### Commandes

```ruby
# Créer
result = post_json('/api/v1/orders', {
  order: {
    order_reference: "ORD-123",
    buyer_id: 1,
    seller_id: 2,
    status: "nouvelle_commande"
  }
})

# Récupérer
result = get_json('/api/v1/orders/ORD-123')

# Mettre à jour
result = patch_json('/api/v1/orders/ORD-123', {
  order: { status: "confirmee" }
})
```

### Produits

```ruby
# Lister
result = get_json('/api/v1/products')

# Récupérer un produit
result = get_json('/api/v1/products/5238A0')
```

### Circle Values

```ruby
result = post_json('/api/v1/search_circle_values', {
  input_values: {
    "C0" => "11",
    "CLE" => "038",
    "C10" => "5238A0",
    "C11" => "2017"
  },
  searched_values: ["C6", "C7"]
})
```
