# Moduli comuni

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

I moduli NixOS riutilizzabili sono raggruppati per funzione. I [ruoli](../roles/README.it.md) selezionano le basi condivise; ogni host aggiunge i moduli opzionali tramite gli import.

| Directory | Contenuto |
| --- | --- |
| [`config/`](config/README.it.md) | Impostazioni di sistema, audio, compatibilità, ottimizzazioni, profili energetici, avvio cifrato, manutenzione Btrfs, SOPS e sudo. |
| [`gui/`](gui/README.it.md) | KDE, GNOME, Hyprland, Xfce RDP opzionale e [temi](gui/themes/README.it.md). |
| [`network/`](network/README.it.md) | Impostazioni NetworkManager client e server, Bluetooth e basi del firewall. |
| [`packages/`](packages/README.it.md) | Strumenti indipendenti per foto, video, sviluppo, registrazione, Compose, Distrobox e virtualizzazione; Btrfs Assistant, gaming e pacchetti hardware opzionali. |
| [`services/`](services/README.it.md) | Demoni locali Docker e libvirt e OpenSSH server. |

## Composizione

Un host in `hosts/client/<nome>/` o `hosts/server/<nome>/` importa i moduli con `../../../common/<categoria>/<file>.nix`. Prepara i file `.nix.template` selezionati come `.nix` e sostituisci i segnaposto documentati usando i valori pubblici descritti in [`env.conf`](../../env.conf). Vedi la [guida HOWTO](../../HOWTO.it.md) per la preparazione manuale.

I desktop locali sono opzionali e indipendenti da gruppi di applicazioni e demoni. Distrobox importa il proprio runtime Docker; gli strumenti Compose si possono selezionare separatamente. Virt Manager gestisce host remoti senza un demone libvirt locale. Il precedente modulo workstation corrisponde ai sette moduli di pacchetti dedicati più Docker e libvirt.

## Separazione tra host e utenti

Profili WiFi, intervalli di rete consentiti, dispositivi/cartelle Syncthing e hardware specifico appartengono a `hosts/client/<nome>/` o `hosts/server/<nome>/`. Gli account appartengono a [`users/`](../users/README.it.md). Mantieni password, hash, chiavi private e PSK WiFi nei file cifrati dei segreti; vedi [SECRETS.it.md](config/SECRETS.it.md).

Gli snapshot Btrfs si configurano con il modulo di base `config/btrfs_snapshots.nix`, che rileva il filesystem. Seleziona root e home soltanto quando il rispettivo mount è Btrfs e crea i contenitori degli snapshot necessari a Snapper. Le ACL home client e la policy della directory di lavoro worker appartengono all'host; il modulo di base non dipende da desktop o utenti. Il modulo opzionale `packages/btrfs_assistant.nix` installa soltanto il pacchetto della GUI; il desktop selezionato fornisce Polkit e il relativo agent di autenticazione. Scrub è un modulo separato riservato a Btrfs.

`battery_management.nix` importa `energy_profiles.nix` e offre la selezione automatica Performance/Balanced più Saver manuale temporaneo, con autorizzazione Polkit dedicata agli amministratori locali attivi. Mantieni gli override specifici di driver e firmware; vedi la [guida ai profili energetici](config/README.it.md#profili-energetici).
