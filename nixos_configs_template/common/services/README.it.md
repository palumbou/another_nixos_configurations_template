# Servizi

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questi moduli riutilizzabili abilitano i servizi locali indipendentemente dai client grafici. Le identità degli utenti, le chiavi autorizzate e le regole di accesso specifiche della macchina si dichiarano nell'host o nei moduli utente.

## Moduli disponibili

| File | Comportamento |
| --- | --- |
| `docker.nix` | Demone Docker con privilegi di root, abilitato all'avvio; pulizia automatica e Docker rootless disabilitati. |
| `libvirt.nix` | Demone libvirt con QEMU abilitato a KVM, account dedicato `qemu-libvirtd`, TPM software e autorizzazione Polkit. Avvia all'accensione i guest configurati e li arresta allo spegnimento dell'host. |
| `server_ssh.nix.template` | Policy OpenSSH server: autenticazione a chiave pubblica; login diretto di root, autenticazione con password e keyboard-interactive disabilitati; `openFirewall = false`. |

## Docker e libvirt

Da `hosts/server/<nome>/configuration.nix`:

```nix
imports = [
  ../../../common/services/docker.nix
  ../../../common/services/libvirt.nix
];
```

Seleziona ogni demone dove necessario. I [moduli di pacchetti](../packages/README.it.md) offrono strumenti Compose e di virtualizzazione indipendenti. `distrobox.nix` importa `docker.nix` e seleziona Docker tramite `DBX_CONTAINER_MANAGER = "docker"`. `virtualization_tools.nix` abilita Virt Manager e il reindirizzamento USB SPICE senza abilitare un demone libvirt locale, quindi gestisce anche host remoti.

`libvirt.nix` mantiene il servizio oneshot `libvirt-default-network`: dopo `libvirtd.service`, imposta l'avvio automatico della rete `default` e la avvia se non è già attiva. Il servizio è avviato da `multi-user.target` e non richiede una sessione desktop. Le definizioni delle reti e dei guest appartengono alla configurazione di virtualizzazione dell'host.

Il modulo account client aggiunge i gruppi hardware/demoni pertinenti in modo condizionale. L’identità worker rimane fuori dai gruppi amministrativi, Docker e libvirt; le operazioni amministrative usano sudo tramite l’account amministratore separato. Mantieni le identità nei moduli account e i dati delle chiavi nei valori cifrati configurati per l’host.

## OpenSSH per server

Il ruolo [server](../../roles/README.it.md) importa il modulo SSH server. Per riutilizzarlo in un altro profilo:

```nix
imports = [
  ../../../common/services/server_ssh.nix
];
```

Prepara `server_ssh.nix.template` come `server_ssh.nix` e sostituisci `${SSH_PORT}` con una porta numerica. Definisci l'utente e le sue chiavi autorizzate nei moduli dell'host o dell'utente.

Le aperture firewall e gli eventuali filtri per subnet appartengono alla configurazione di rete dell'host, ad esempio `nm_configurations.nix`. Le regole firewall devono usare la porta di OpenSSH. Adatta l'esempio nella [guida di rete](../network/README.it.md) alla porta scelta e alle reti consentite.

La base client mantiene la propria policy di autenticazione in `../packages/default_packages_services.nix.template`; scegli il modulo adatto al ruolo dell'host.
