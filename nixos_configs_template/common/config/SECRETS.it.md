# Gestione dei segreti con sops-nix

> **Lingue disponibili**: [English](SECRETS.md) | [Italiano (corrente)](SECRETS.it.md)

Tutto ciò che scrivi in una configurazione NixOS finisce nel Nix store, che è **leggibile da ogni utente e processo della macchina** - e la tua copia di `nixos_configs` vive tipicamente in una cartella versionata, sincronizzata tra macchine o salvata in backup. Password, chiavi WiFi e token non devono quindi mai comparire in chiaro nei file `.nix`. Questo template lo risolve con [sops-nix](https://github.com/Mic92/sops-nix): **i segreti restano dentro `nixos_configs`, ma cifrati** - puoi versionarla, sincronizzarla o farne backup senza esporli; ogni host li decifra all'attivazione del sistema con una chiave derivata dalla propria chiave SSH host, e i valori decifrati compaiono solo sotto `/run/secrets*` (RAM), con proprietario e permessi corretti.

---

## Architettura

Tre pezzi, ognuno con un compito:

| File | Ruolo | Dentro `nixos_configs` |
|------|-------|----------|
| `.sops.yaml` | **Chi** può decifrare: chiavi age *pubbliche* + regole per file | In chiaro (sicuro: solo chiavi pubbliche) |
| `secrets/common.yaml` | **Cosa** contengono i segreti: valori comuni alla flotta | Cifrato (nomi visibili, valori cifrati) |
| `common/config/secrets.nix` | Il meccanismo: modulo sops-nix (pinnato), chiave host, tool di editing | Modulo normale, identico per ogni host |

I consumatori dichiarano poi i segreti che usano, esattamente dove li usano:

- `users/XYZ/user.nix` dichiara `user_hashedPassword` (con `neededForUsers = true`, decifrato prima della creazione degli utenti) e lo legge via `hashedPasswordFile`;
- `hosts/<host>/nm_configurations.nix` dichiara `wifi_env` e lo passa a `networking.networkmanager.ensureProfiles` come environment file: i profili WiFi vengono generati **direttamente dentro NetworkManager**, con le PSK riferite come variabili `$WIFI_*` - niente più file `.nmconnection` da copiare in giro.

Fisicamente, **nulla di segreto tocca mai il disco persistente in chiaro**: su disco vive solo `secrets/common.yaml` cifrato; i valori decifrati stanno in `/run/secrets*` (RAM) e i profili WiFi renderizzati in `/run/NetworkManager/system-connections/` (anch'essa RAM, permessi 0600). Allo spegnimento tutto evapora e viene rigenerato all'avvio successivo.

Poiché `user.nix` è importato da ogni host, **ogni host deve importare `common/config/secrets.nix`** (le opzioni `sops.*` devono esistere ovunque vengano riferite).

Il modello delle chiavi - la parte che vale la pena capire una volta per tutte:

- Ogni **host** decifra con la chiave age derivata matematicamente dalla sua chiave SSH host (`/etc/ssh/ssh_host_ed25519_key`). Niente da generare o distribuire: la macchina la possiede già.
- L'**amministratore** (tu) ha una coppia age personale per *editare* i segreti, in `~/.config/sops/age/keys.txt`. La privata non entra mai in `nixos_configs` (né in altri percorsi condivisi); solo la sua metà pubblica va in `.sops.yaml`.
- Le chiavi private non viaggiano mai. Aggiungere un lettore significa sempre: aggiungere la sua chiave *pubblica* a `.sops.yaml`, poi `sops updatekeys`.

---

## Setup iniziale (una volta sola)

1. **Chiave admin**:

   ```bash
   mkdir -p ~/.config/sops/age && chmod 700 ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   ```

   Annota la chiave pubblica stampata (`age1...`). Copia `keys.txt` a mano sulle altre postazioni da cui editerai i segreti - mai dentro `nixos_configs` né attraverso canali condivisi o pubblici.

2. **Regole**: rinomina `.sops.yaml.template` in `.sops.yaml` e incolla la tua chiave pubblica admin (le chiavi degli host si aggiungono dopo, vedi sotto).

3. **Primo file di segreti**:

   ```bash
   cp secrets/common.yaml.template secrets/common.yaml
   # compila i valori, poi:
   sops -e -i secrets/common.yaml
   ```

Da lì in poi si edita sempre con `sops secrets/common.yaml`: decifra nell'editor e ricifra al salvataggio. I tool (`sops`, `age`, `ssh-to-age`) vengono installati a sistema da `secrets.nix`; sull'installer live usa `nix-shell -p sops age ssh-to-age`.

---

## Uso quotidiano

- **Modificare un valore**: `sops secrets/common.yaml`.
- **Aggiungere una rete WiFi**: aggiungi una riga `WIFI_<NOME>_PSK=...` dentro `wifi_env`, poi dichiara il profilo nel `nm_configurations.nix` del host (copia un blocco esistente, imposta `id`/`ssid` e la variabile `psk = "$WIFI_<NOME>_PSK"`). Ogni host elenca solo le reti che usa; l'environment file le contiene tutte.
- **Cambiare la password utente**: genera l'hash con `mkpasswd -m sha-512` e incollalo come valore di `user_hashedPassword`.

---

## Aggiungere un host

**Host già installato**: deriva la sua chiave pubblica sulla macchina stessa, aggiungila, ricifra:

```bash
# sul nuovo host
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
# sulla tua postazione: aggiungi la age1... stampata a .sops.yaml, poi
sops updatekeys secrets/common.yaml
```

Fallo **prima** del primo `nixos-rebuild switch` che usa segreti su quel host: la build riesce comunque, ma l'attivazione non può decifrare finché la chiave non è a posto.

**Installazione da zero**: la chiave SSH host nasce normalmente al primo avvio - troppo tardi per l'installer. Generala in anticipo, subito dopo che Disko ha montato il disco in `/mnt` e prima di `nixos-install`:

```bash
sudo mkdir -p /mnt/etc/ssh
sudo ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
sudo ssh-to-age < /mnt/etc/ssh/ssh_host_ed25519_key.pub
# aggiungi la chiave stampata a .sops.yaml, esegui "sops updatekeys secrets/common.yaml",
# poi prosegui l'installazione normalmente
```

Il sistema installato troverà la chiave host già presente e decifrerà fin dal primissimo avvio.

---

## Rimuovere una macchina o una persona

1. Togli la sua chiave da `.sops.yaml` ed esegui `sops updatekeys secrets/common.yaml`.
2. **Ruota i valori stessi** (`sops secrets/common.yaml`): rimuovere una chiave impedisce le letture *future*, ma chi la possedeva potrebbe aver già visto i valori vecchi. Nuova password WiFi, nuovo hash.

---

## Risoluzione problemi

- *L'attivazione dice che non può decifrare* → manca la chiave di quel host in `.sops.yaml` (o non è stato eseguito `updatekeys`). I login esistenti sopravvivono grazie a `users.mutableUsers = true`; sistema la chiave e rifai il rebuild.
- *Chi può decifrare adesso?* → i destinatari `sops.age` elencati in fondo al file cifrato stesso.
- *Verifica che un file si decifri per te*: `sops -d secrets/common.yaml >/dev/null && echo ok`.

---

## Oltre il setup di base

- **Segreti per singolo host**: aggiungi `secrets/<host>.yaml` con la sua voce dedicata nelle `creation_rules` (admin + solo quel host).
- **Molti host / un team**: gruppi di chiavi per ambiente in `.sops.yaml`; `sops updatekeys` mantiene gestibile la rotazione.
- **CI/CD e cloud**: sops supporta i **backend KMS** (AWS/GCP/Azure) - stessi file, la custodia delle chiavi passa a servizi controllati via IAM.
- **Un secret manager centrale**: [OpenBao](https://openbao.org/) (il fork open source di Vault) tramite il backend Vault-compatibile di sops.
