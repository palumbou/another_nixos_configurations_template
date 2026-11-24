# Ruoli

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

I ruoli compongono moduli condivisi. Un host sceglie un ruolo e aggiunge utenti, hardware, storage, avvio e funzioni opzionali.

| File | Contenuto |
| --- | --- |
| `base.nix` | Lingua, fuso orario e tastiera tramite `common/config/system.nix`. |
| `client.nix` | Base, compatibilità dei binari, ottimizzazioni e regole sudo client. |
| `server.nix` | Base, strumenti da terminale essenziali, OpenSSH server e rete server. |

## Utilizzo

Per un host in `hosts/client/<nome>/configuration.nix`:

```nix
imports = [
  ../../../roles/client.nix
  ../../../users/ADMIN/client.nix
];
```

Per un host in `hosts/server/<nome>/configuration.nix`:

```nix
imports = [
  ../../../roles/server.nix
  ../../../users/ADMIN/admin.nix
  ../../../users/WORKER/worker.nix
];
```

Entrambi i ruoli importano già `base.nix`. Il ruolo client lascia desktop, rete e pacchetti applicativi all'host. Il modulo account client importa l'identità amministrativa essenziale e aggiunge le applicazioni personali del client. L’amministratore del server rimane minimale; l'account worker separato non ha privilegi amministrativi o gruppi dei demoni locali.

Il ruolo server include Bash, Python, Git, ripgrep, rsync, curl, jq, strumenti GNU per file e archivi, unzip e strumenti ACL. Tool di progetto, Docker, libvirt, Syncthing, desktop locale e Xfce RDP rimangono selezioni separate dell’host. Il ruolo server imposta `nixpkgs.config.allowUnfree = true;`, come la base client `default_packages_services.nix`.

Usa i moduli server per un host server. `common/packages/default_packages_services.nix` appartiene ai client e dichiara una policy SSH diversa; non combinarlo con il ruolo server.

## Policy dell'host

Gli esempi sono in `hosts/client/ABC/` e `hosts/server/ABC/`. Prepara manualmente i template selezionati con i valori pubblici di [`env.conf`](../../env.conf); vedi la [guida HOWTO](../../HOWTO.it.md). Import opzionali e impostazioni di avvio occupano rispettivamente `${HOST_IMPORTS}` e `${HOST_EXTRA_CONFIG}`.

Il [modulo SSH server](../common/services/README.it.md) usa l'autenticazione con chiave e non apre porte firewall. Sostituisci `${SSH_PORT}` con la porta numerica scelta. CIDR consentiti, WiFi, RDP e Syncthing sono specifici dell'host; mantieni `system.stateVersion` nell'host.

L'host server disabilita il riposo per inattività o chiusura del coperchio, la sospensione e l'ibernazione. La gestione batteria opzionale spegne il sistema alla soglia di azione invece di ibernarlo; `ENABLE_BATTERY=false` disabilita UPower anche se un desktop lo richiede. I limiti di ricarica devono corrispondere al plugin TLP dell'hardware reale. Limiti delle build, zram, snapshot, permessi della directory di lavoro e accessi di rete sono dichiarati nei moduli host e account, anziché nel ruolo condiviso.
