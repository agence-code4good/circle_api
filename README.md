## Installation de Circle API avec Docker Compose

### 1. Cloner le projet

```bash
git clone git@github.com:agence-code4good/circle_api.git
cd circle_api
```

### 2. Build l'image Docker

```bash
docker compose build
```

L'image utilise le stage **development** (gems natives précompilées, dont `bcrypt`).  
Ne pas lancer `bundle install` dans le conteneur sauf après modification du `Gemfile` — si besoin, le stage dev inclut `build-essential`.

### 4. Générer la master key (première fois uniquement)

```bash
docker compose run --rm app bin/rails credentials:edit
```

### 5. Lancer l'application

```bash
docker compose up -d
```

Les migrations sont lancées automatiquement au démarrage.

### 6. Lancer les seeds (optionnel)

```bash
docker compose exec app bin/rails db:seed
```

Peuple l’admin, les partenaires, les aliases et le catalogue produits. Les **connexions handshake** se configurent ensuite dans ActiveAdmin (voir ci-dessous).

### 7. Vérifier que l'application fonctionne

L'application est accessible sur : **http://localhost:3000**

Voir les logs :
```bash
docker compose logs -f app
```

## Commandes utiles

```bash
# Arrêter l'application
docker compose down

# Console Rails
docker compose exec app bin/rails console

# Shell du conteneur
docker compose exec app bash

# Migrations manuelles (normalement automatiques)
docker compose exec app bin/rails db:migrate

# Seeds
docker compose exec app bin/rails db:seed

# Rebuild après modification du code
docker compose build --no-cache app
docker compose up -d
```

## Handshake v2 (connexion inter-partenaires)

Chaque **Partner** est une CircleAPI distante du réseau. Chaque déploiement expose son identité Ed25519 (`GET /api/identity`). Les appels sortants signés sont faits par **CircUI** (ou le SI intégrateur) ; CircleAPI vérifie les requêtes entrantes.

### Première installation

À l’installation, **CircUI** (ou le SI intégrateur) génère la paire de clés Ed25519 et l’enregistre dans CircleAPI via :

```http
POST /api/admin/identity
Authorization: Bearer <HANDSHAKE_IDENTITY_IMPORT_TOKEN>
Content-Type: application/json

{
  "public_key": "base64...",
  "private_key": "base64...",
  "key_version": 1
}
```

`key_version` est optionnel (défaut `1` ; incrémenter pour une rotation). La clé privée ne quitte pas le périmètre de l’intégrateur ; CircleAPI expose uniquement la clé publique via `GET /api/identity`.

Sans CircUI (dev local uniquement), une identité de test peut être créée avec `bin/rails handshake:generate_identity`.

### Configurer un partenaire (ActiveAdmin → Partners)

1. Créer le partenaire : **URL** de sa CircleAPI + **token** (bcrypt, généré chez vous — à transmettre hors bande au pair).
2. **Récupérer clé publique** (fetch TOFU) ou la coller manuellement.
3. CircUI exécute les **challenges** vers le pair et vers votre instance ; en admin : **Challenge émis (Circuit)** après le challenge sortant.
4. Statut **active** lorsque les deux challenges sont enregistrés.

Le token que le pair utilise pour vous appeler est stocké sur le **Partner** (`auth_token_digest`). Le token pour appeler le pair vit côté **CircUI** (outbound).

Tâche utilitaire pour renseigner une URL sur des partenaires sans URL :

```bash
REMOTE_BASE_URL=https://partenaire.example.com docker compose exec app bin/rails handshake:migrate_partners
```

### Spécification et exemples

- Protocole : `specs/handshake_v2_signing.md`
- Client Ruby exemple : `specs/examples/clients_ruby/handshake_client.rb`

### Variables d'environnement (optionnel)

| Variable | Description |
|----------|-------------|
| `HANDSHAKE_INSTANCE_CODE` | Code de cette instance chez les partenaires (défaut : `circle`) |
| `HANDSHAKE_IDENTITY_IMPORT_TOKEN` | Bearer token pour `POST /api/admin/identity` (CircUI) |
| `HANDSHAKE_OUTBOUND_REWRITE` | Réécriture des URL `localhost` pour appels sortants depuis Docker (`true` / `false`) |
| `HANDSHAKE_OUTBOUND_URL_3000` | Cible de réécriture pour `localhost:3000` (ex. URL publique de l’instance) |

En production, renseignez directement l’URL réelle du partenaire dans **remote base URL** plutôt que `localhost`.

### Fichiers de dev local (non versionnés)

Le dépôt ignore les outils utilisés pour simuler **deux instances** sur la même machine (`script/`, `docker-compose.handshake.yml`, `db/seeds/instance_*.rb`, `lib/tasks/seed_instances.rake`, etc.). Ils peuvent rester en local pour vos tests sans être poussés sur le remote.
