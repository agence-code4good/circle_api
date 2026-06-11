# Handshake v2 — Spécification des signatures

## Algorithme

- **Ed25519** pour toutes les signatures asymétriques.
- Clés publiques et signatures encodées en **Base64 strict** (sans retours à la ligne).

## En-têtes HTTP (échanges API métier)

| En-tête | Obligatoire | Description |
|---------|-------------|-------------|
| `Authorization` | Oui | `Bearer {inbound_token}` — secret que le partenaire utilise pour nous appeler |
| `X-Partner-Code` | Oui | Code local du partenaire émetteur (inchangé v1) |
| `X-Handshake-Nonce` | Oui | UUID v4 |
| `X-Handshake-Timestamp` | Oui | Unix timestamp entier (secondes UTC) |
| `X-Handshake-Signature` | Oui | Signature Ed25519 du message canonique, Base64 |

### Fenêtre temporelle

Le timestamp doit être à ± **300 secondes** de l’heure serveur. Sinon : `401` avec `{ "error": "timestamp_expired" }`.

### Anti-rejeu (nonce à usage unique)

Le `X-Handshake-Nonce` est **à usage unique par connexion**. Le récepteur enregistre chaque nonce consommé (après vérification de la signature) et rejette toute requête réutilisant un nonce déjà vu : `401` avec `{ "error": "nonce_replayed" }`.

Les nonces sont conservés au moins aussi longtemps que la fenêtre temporelle (300 s + marge), puis purgés. Un nonce expiré ne peut pas être rejoué car son timestamp d’origine est alors hors fenêtre.

## Message canonique (échanges API)

```
{METHOD}\n{PATH}\n{BODY_SHA256}\n{NONCE}\n{TIMESTAMP}
```

- `METHOD` : verbe HTTP en majuscules (`GET`, `POST`, …)
- `PATH` : chemin uniquement, sans query string (ex. `/api/v1/orders`)
- `BODY_SHA256` : empreinte SHA256 hexadécale du corps brut ; chaîne vide si corps absent
- `NONCE` : valeur de `X-Handshake-Nonce`
- `TIMESTAMP` : valeur de `X-Handshake-Timestamp` (chaîne décimale)

La signature est `Ed25519_Sign(private_key, canonical_message)`.

### Vérification côté récepteur

1. Résoudre la `PartnerConnection` active via `X-Partner-Code`.
2. Vérifier le Bearer (token inbound, comparaison en temps constant).
3. Vérifier le timestamp.
4. Reconstruire le message canonique et vérifier la signature avec `pinned_public_key`.
5. En cas d’échec : `401` avec `{ "error": "invalid_signature" }` ou code dédié.

## POST /api/challenge

### Requête

```json
{
  "nonce": "uuid-v4",
  "signature": "base64-ed25519-signature-of-nonce"
}
```

- `signature` = `Ed25519_Sign(caller_private_key, nonce)` où `nonce` est la chaîne UTF-8 exacte du champ JSON.
- `Authorization: Bearer {inbound_token}`
- `X-Partner-Code: {code}`

### Réponse (200)

```json
{
  "nonce": "same-nonce",
  "signature": "base64-ed25519-signature-of-nonce-by-receiver"
}
```

La signature réponse est produite avec la **clé privée de l’instance réceptrice** sur la même chaîne `nonce`.

### Erreurs

| Code HTTP | `error` | Cas |
|-----------|---------|-----|
| 401 | `unauthorized` | Token ou partenaire invalide |
| 401 | `invalid_signature` | Signature appelant invalide |
| 401 | `nonce_replayed` | Nonce déjà utilisé pour cette connexion |
| 403 | `connection_suspended` | Relation non active |
| 403 | `key_mismatch` | Clé publique épinglée incompatible |
| 403 | `missing_public_key` | Aucune clé publique épinglée pour la connexion |
| 422 | `missing_nonce` | Corps invalide |

## GET /api/identity

Sans authentification.

```json
{
  "algorithm": "Ed25519",
  "public_key": "base64...",
  "key_version": 1
}
```

## Challenge mutuel (configuration symétrique)

Une `PartnerConnection` passe en `active` uniquement si :

1. **Challenge entrant** : le partenaire a appelé notre `POST /api/challenge` avec succès (`inbound_challenge_verified_at` renseigné).
2. **Challenge sortant** : notre instance a appelé le `POST /api/challenge` du partenaire avec succès (`outbound_challenge_verified_at` renseigné).

## Rotation de clé

Si `GET /api/identity` du partenaire retourne une clé dont l’empreinte diffère de `pinned_public_key` :

- `status` → `key_mismatch`
- Tous les échanges refusés jusqu’à action admin **Ré-approuver la clé** (nouveau pin TOFU + challenges mutuels).
