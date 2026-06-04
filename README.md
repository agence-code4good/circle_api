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

Chaque déploiement possède une identité Ed25519 (`GET /api/identity`). Les échanges API passent par une **PartnerConnection** (URL distante, tokens inbound/outbound échangés hors-bande, clé publique épinglée TOFU).

### Première installation

```bash
docker compose exec app bin/rails handshake:generate_identity
```

Le seed appelle déjà `ensure!` si aucune identité n’existe ; cette tâche sert à forcer une génération ou une rotation (`ROTATE=1`).

### Configurer un partenaire (ActiveAdmin)

1. Créer une **Partner connection** : URL HTTPS (ou HTTP en dev) du partenaire, token inbound (généré chez vous) et token outbound (fourni par le partenaire).
2. **Récupérer clé publique** (fetch TOFU).
3. **Challenge sortant** ; le partenaire exécute le sien vers votre instance.
4. Statut **active** lorsque les deux challenges sont validés.

Tâche utilitaire si une même URL distante s’applique à plusieurs partenaires en dev :

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
| `HANDSHAKE_OUTBOUND_REWRITE` | Réécriture des URL `localhost` pour appels sortants depuis Docker (`true` / `false`) |
| `HANDSHAKE_OUTBOUND_URL_3000` | Cible de réécriture pour `localhost:3000` (ex. URL publique de l’instance) |

En production, renseignez directement l’URL réelle du partenaire dans **remote base URL** plutôt que `localhost`.

### Fichiers de dev local (non versionnés)

Le dépôt ignore les outils utilisés pour simuler **deux instances** sur la même machine (`script/`, `docker-compose.handshake.yml`, `db/seeds/instance_*.rb`, `lib/tasks/seed_instances.rake`, etc.). Ils peuvent rester en local pour vos tests sans être poussés sur le remote.
