# Exemples pour l'API Circle

Ce dossier contient des exemples de données et des clients d'exemple pour l'API Circle.

## Structure

```
specs/examples/
├── README.md                          # Ce fichier
└── clients_ruby/                      # Clients Ruby d'exemple
    ├── README.md                      # Documentation des clients Ruby
    ├── INSTALLATION.md                # Guide d'installation
    ├── test_all_clients.rb            # Script de test global
    ├── validation_client.rb           # Client pour validation
    ├── orders_client.rb               # Client pour orders
    ├── products_client.rb             # Client pour products
    └── circle_values_client.rb        # Client pour circle values
```

## Clients d'exemple Ruby

Voir [`clients_ruby/README.md`](clients_ruby/README.md) pour la documentation complète.

**Test rapide :**
```bash
cd specs/examples/clients_ruby
ruby test_all_clients.rb
```

## Utilisation

Ces clients d'exemple peuvent être utilisés pour :
- Tester l'API
- Comprendre comment consommer les endpoints
- Développer des clients dans d'autres langages
- Valider l'implémentation

## Ajouter d'autres exemples

Pour ajouter des clients dans d'autres langages :

```
specs/examples/
├── clients_ruby/      # ✅ Disponible
├── clients_python/    # À venir
├── clients_js/        # À venir
└── ...
```
