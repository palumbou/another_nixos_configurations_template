# Segreti con sops-nix

[English](SECRETS.md) | [Italiano](SECRETS.it.md)

Configurazione Nix e risultati di build possono finire nel Nix store leggibile. Mantieni hash password, credenziali Wi-Fi e token fuori dai sorgenti Nix. Il modulo [sops-nix](https://github.com/Mic92/sops-nix) fissato in `secrets.nix` decifra YAML all'attivazione, prima degli account quando necessario. I valori vengono letti da file runtime anziché inseriti nei file dello store.

## File e responsabilità

| File/chiave | Ambito | Utilizzatore |
| --- | --- | --- |
| `.sops.yaml` | Destinatari age pubblici e regole per file | Modifica/cifratura SOPS |
| `secrets/common.yaml`: `admin_hashedPassword` | Credenziale amministratore condivisa | `users/<admin>/admin.nix`; `neededForUsers = true` |
| `secrets/common.yaml`: `admin_ssh_publicKey` | Chiave pubblica autorizzata dell'amministratore | Template SSH runtime dell'host |
| `secrets/<hostname>.yaml`: `worker_hashedPassword` | Account worker di questo host | `users/<worker>/worker.nix`; `neededForUsers = true` |
| `secrets/<hostname>.yaml`: `worker_ssh_publicKey` | Chiave pubblica autorizzata solo per il worker | Template SSH runtime dell'host server |
| `secrets/<hostname>.yaml`: `wifi_env` | Ambiente Wi-Fi di questo host | `nm_configurations.nix` dell'host |

Il file comune è leggibile dall'editor e da tutti gli host autorizzati. Il file di un host è leggibile dall'editor e solo da quell'host. Mantieni una regola distinta per host. I file client possono conservare le chiavi worker d'esempio inutilizzate oppure rimuoverle se non dichiarano segreti worker. Le chiavi SSH pubbliche sono cifrate per uniformare la configurazione degli account; le corrispondenti private non devono entrare nella struttura di configurazione.

Ogni host importa `common/config/secrets.nix` e imposta `sops.defaultSopsFile = ../../../secrets/<hostname>.yaml`. La password amministratore usa esplicitamente `../../secrets/common.yaml` rispetto al suo modulo account. La password worker usa il default dell'host. Entrambe hanno `neededForUsers` e sono disponibili prima della creazione degli account in `/run/secrets-for-users`; i segreti ordinari e i template renderizzati usano `/run/secrets*`.

## Preparare i destinatari

Lavora dalla radice della struttura configurata, dove saranno presenti `.sops.yaml`, `secrets/`, `users/` e `hosts/`. Se mancano i comandi, avvia `nix-shell -p sops age ssh-to-age mkpasswd`.

Crea una chiave age dell'editor fuori da questa struttura:

```bash
mkdir -p ~/.config/sops/age
chmod 700 ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

Annota il destinatario pubblico stampato. Proteggi e salva separatamente la privata. `secrets.nix` configura ogni host per decifrare con la sua `/etc/ssh/ssh_host_ed25519_key`. Ricava solo il destinatario pubblico su quell'host:

```bash
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

Per un'installazione nuova, prepara la chiave SSH del sistema destinazione dopo averlo montato in `/mnt` e prima dell'installazione, senza sovrascrivere una chiave esistente:

```bash
sudo mkdir -p /mnt/etc/ssh
sudo ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
sudo ssh-to-age < /mnt/etc/ssh/ssh_host_ed25519_key.pub
```

Copia `.sops.yaml.template` in `.sops.yaml`. Sostituisci `REPLACE_WITH_EDITOR_AGE_RECIPIENT` e `REPLACE_WITH_HOST_AGE_RECIPIENT` con i destinatari pubblici. Sostituisci `${HOSTNAME}` nella regola host con il nome scelto. I segnaposto sono destinatari volutamente non validi e richiedono configurazione manuale. Aggiungi un'ancora/regola per ogni altro host; includi tutti gli host autorizzati nella regola comune e limita ogni file host al proprio destinatario.

## Creare YAML cifrati

Per un host generico `example-node`:

```bash
cp secrets/common.yaml.template secrets/common.yaml
cp secrets/ABC.yaml.template secrets/example-node.yaml
mkpasswd -m sha-512
```

Se il file d'esempio ha già l'hostname nel nome, usa quello al posto di `ABC.yaml.template`. Sostituisci i segnaposto YAML con gli hash scelti, le righe complete delle chiavi SSH pubbliche e la passphrase Wi-Fi. Usa il prompt interattivo di `mkpasswd` senza inserire password nella riga di comando. Non usare i segnaposto come credenziali. Il blocco `wifi_env` contiene `WIFI_PSK=...`; il profilo NetworkManager riferisce esattamente `$WIFI_PSK`.

Cifra entrambi i file prima di versionarli, sincronizzarli o usarli con NixOS:

```bash
sops --encrypt --in-place secrets/common.yaml
sops --encrypt --in-place secrets/example-node.yaml
```

Dopo la cifratura modifica soltanto con `sops secrets/common.yaml` o `sops secrets/example-node.yaml`. Controlla i metadati del file cifrato per verificare i destinatari. Proteggi backup dell'editor e file temporanei in chiaro secondo l'editor usato. I template in chiaro contengono solo esempi; distribuisci i `.yaml` cifrati, non i `.yaml.template`.

## Chiavi SSH autorizzate runtime

L'host dichiara `admin_ssh_publicKey` dal file comune e, sul server, `worker_ssh_publicKey` dal file host. `sops.templates` crea `ssh-authorized-keys/<admin>` dell'amministratore con permessi `0400`. Il server crea anche `ssh-authorized-keys/<worker>` del worker, con entrambe le chiavi pubbliche. L'amministratore può così accedere a entrambi gli account; la chiave worker autorizza solo quello worker.

OpenSSH legge `/run/secrets/rendered/ssh-authorized-keys/%u`, dove `%u` è l'account richiesto. I file vengono renderizzati all'attivazione; la valutazione Nix non deve decifrare i valori. Gli esempi host includono dichiarazioni e `AllowUsers`. Un modulo account importato da solo non configura i template SSH. Conserva un accesso amministrativo funzionante finché la nuova configurazione non è verificata.

## Aggiornamenti e rimozione

- Per una password esegui `mkpasswd -m sha-512` e aggiorna la chiave corrispondente con SOPS. La modifica amministratore riguarda tutti gli host che leggono il file comune; quella worker riguarda l'host scelto.
- Per il Wi-Fi modifica `wifi_env` dell'host; `restartUnits` aggiorna `NetworkManager-ensure-profiles.service`. Una nuova variabile/rete richiede anche il relativo profilo.
- Aggiungi un destinatario host a `.sops.yaml`, poi esegui `sops updatekeys secrets/common.yaml` e `sops updatekeys secrets/<hostname>.yaml` sui file interessati prima dell'attivazione.
- Rimuovi un destinatario dalle regole, aggiorna i file coinvolti e ruota i valori che poteva leggere. La rimozione non revoca copie già decifrate o la cronologia del repository.

## Verifiche prima dell'attivazione

Parsing, valutazione o build non provano che il destinatario possa decifrare. Controlla destinatari e identità pubblica dell'host prima di installazione/rebuild. Se vuoi verificare la decifratura con la chiave editor, scarta stdout senza visualizzare i valori:

```bash
sops --decrypt secrets/common.yaml > /dev/null
sops --decrypt secrets/example-node.yaml > /dev/null
```

Questo prova solo l'accesso editor; quello dell'host richiede la sua identità configurata. Un errore sui segreti `neededForUsers` può bloccare creazione account e attivazione. `users.mutableUsers = true` sui client non garantisce il recupero da un'attivazione fallita. Correggi destinatari/percorso chiave prima di proseguire.
