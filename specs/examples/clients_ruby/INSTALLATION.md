# Installation et utilisation des clients Ruby

## Structure des fichiers

```
specs/examples/clients_ruby/
├── README.md                      # Documentation complète
├── INSTALLATION.md                # Ce fichier
├── test_all_clients.rb            # Script de test global
├── validation_client.rb           # Client pour l'endpoint validation
├── orders_client.rb               # Client pour les endpoints orders (CRUD)
├── products_client.rb             # Client pour les endpoints products
└── circle_values_client.rb        # Client pour l'endpoint search_circle_values
```

## Prérequis

- Ruby 2.7 ou supérieur
- Le serveur API Circle doit être en cours d'exécution sur `http://localhost:3000`
- Un token d'authentification valide

## Configuration

### 1. Obtenir un token d'authentification

Dans le terminal, depuis la racine du projet :

```bash
bin/rails runner "puts Partner.first.auth_token"
```

### 2. Configurer les clients

Ouvrez chaque fichier client et modifiez les constantes en haut :

```ruby
BASE_URL = 'http://localhost:3000'  # URL de votre serveur
AUTH_TOKEN = 'votre_token_ici'      # Token obtenu à l'étape 1
```

## Test rapide

### Démarrer le serveur

```bash
bin/dev
```

### Tester les clients

```bash
# Depuis le dossier specs/examples/clients_ruby/

# Test global de tous les clients
ruby test_all_clients.rb

# Test du catalogue produits (le plus simple)
ruby products_client.rb

# Test de la validation de circle codes
ruby validation_client.rb

# Test de la recherche de circle values
ruby circle_values_client.rb

# Test des commandes (CRUD)
ruby orders_client.rb
```

## Résultats attendus

### products_client.rb
```
=== Lister tous les produits ===
✓ 9487 produit(s) trouvé(s)
  - 1111A0: CHATEAU ROC DU BARRAIL, BORDEAUX SUPERIEUR, ROUGE
  ...

=== Récupérer un produit spécifique ===
✓ Produit trouvé:
  C10: 5238A0
  Label: CHATEAU GAZIN, POMEROL, ROUGE
  ...
```

### orders_client.rb
```
=== Créer une commande ===
✓ Commande créée!
  Référence: ORD-1768491091
  Statut: nouvelle_commande
  ...
```

### validation_client.rb
Affiche les résultats de validation avec les erreurs éventuelles.

### circle_values_client.rb
Affiche les résultats de recherche ou les erreurs de dépendances manquantes.

## Personnalisation

### Modifier les données d'exemple

Vous pouvez modifier les données d'exemple dans chaque fichier client :

- **Circle codes** : Modifiez les valeurs dans les hashs `circle_values`
- **Références de commandes** : Modifiez `order_reference`
- **Partners** : Modifiez `buyer_id` et `seller_id` (codes des partners, pas les IDs)

### Obtenir une liste des partners disponibles

```bash
bin/rails runner "Partner.all.each { |p| puts \"Code: #{p.code}, Name: #{p.name}\" }"
```

## Dépannage

### Erreur "Connection refused"
- Vérifiez que le serveur Rails est démarré : `bin/dev`
- Vérifiez l'URL dans `BASE_URL`

### Erreur "401 Unauthorized"
- Vérifiez que le token dans `AUTH_TOKEN` est valide
- Générez un nouveau token si nécessaire

### Erreur "HTML response received"
- Certains endpoints (show/index pour orders) ne sont pas encore implémentés côté serveur
- C'est normal, les clients gèrent ce cas gracieusement

### Erreurs de validation
- Les données d'exemple utilisent des valeurs qui peuvent ne pas correspondre exactement à votre base de données
- C'est normal, cela permet de tester la gestion d'erreurs
- Pour des données valides, consultez la base de données ou utilisez le calculateur de clé Circle

## Support

Pour toute question, consultez :
- La documentation OpenAPI : `specs/openapi.yaml`
- Le README principal : `README.md`
- Les règles de validation : `specs/circle_validation_rules.json`
