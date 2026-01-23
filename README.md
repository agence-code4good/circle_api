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
