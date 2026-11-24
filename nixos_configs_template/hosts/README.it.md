# Host

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Gli esempi host sono separati per funzione:

```text
hosts/
├── client/ABC/
│   ├── configuration.nix.template
│   ├── hardware-configuration.nix.template
│   ├── external-hardware-configuration.nix.template
│   ├── nm_configurations.nix.template
│   └── syncthing.nix.template
├── server/ABC/
│   ├── configuration.nix.template
│   ├── hardware-configuration.nix.template
│   ├── external-hardware-configuration.nix.template
│   ├── nm_configurations.nix.template
│   └── syncthing.nix.template
├── disk_configurations/
│   ├── btrfs/
│   └── ext4/
└── secure_boot/
```

Copia l'esempio `ABC` pertinente nella sua categoria e rinominalo per l'host. Prepara i file `.nix.template` selezionati come file `.nix` con i valori pubblici descritti in [`env.conf`](../../env.conf) e nella [guida HOWTO](../../HOWTO.it.md).

## Import e valori pubblici

Il client importa ruolo client, personalizzazioni dell'amministratore client, base rete/pacchetti client, helper avvio cifrato/Plymouth, SOPS e file locali di hardware/rete/Syncthing. Il server importa ruolo server, amministratore minimale, account worker separato, SOPS e file locali. Mantieni questi import obbligatori.

`${HOST_IMPORTS}` contiene soltanto import opzionali: desktop locale, Xfce RDP, gruppi di pacchetti, Docker/libvirt, manutenzione Btrfs e altre funzioni selezionate. `${HOST_EXTRA_CONFIG}` contiene soltanto impostazioni di avvio. Sceglili esplicitamente; modificare `env.conf` da solo non cambia alcun file Nix.

I percorsi da entrambe le categorie host sono:

| Destinazione | Percorso relativo |
| --- | --- |
| Moduli comuni | `../../../common/` |
| Ruoli | `../../../roles/` |
| Account | `../../../users/ADMIN/` e `../../../users/WORKER/` |
| Dati cifrati | `../../../secrets/` |
| Ricette Disko condivise | `../../disk_configurations/` |
| Secure Boot | `../../secure_boot/secure_boot.nix` |
| Moduli locali dell'host | `./hardware-configuration.nix`, `./nm_configurations.nix`, `./syncthing.nix` |

Prepara nome host e `system.stateVersion` dell'installazione, ID degli account, limiti e interruttori usando i tipi Nix corretti. Mantieni `NIXOS_VERSION` alla versione della prima installazione. I valori zram predefiniti sono client `30`/`lz4` o server `50`/`zstd`, con priorità `100`; risolvi i valori pubblici vuoti prima della sostituzione. `MAX_JOBS` e `BUILD_CORES` controllano la concorrenza delle build.

## Hardware, dischi e avvio

Ottieni `hardware-configuration.nix` da `nixos-generate-config` sulla macchina reale, dall'installer originale o da un modulo [nixos-hardware](https://github.com/NixOS/nixos-hardware) appropriato. I campi `CPU_VENDOR` e `PLATFORM` del template pubblico sono input generici; non rilevano storage, moduli o firmware.

Su una macchina installata conserva le dichiarazioni funzionanti di filesystem e bootloader. Per una nuova installazione scegli un [layout Disko](disk_configurations/README.it.md) preparato, importa modulo Disko fissato alla revisione prevista e ricetta e scegli il bootloader coerente. `DISK_LAYOUT` vuoto si risolve in `single-disk-ext4` sui client e `btrfs-worker-luks` sui server. Questi valori predefiniti sono UEFI; GRUB richiede una ricetta BIOS scelta esplicitamente. `DISK_LAYOUT=none` esplicito richiede un vero `hardware-configuration.nix` con i filesystem della destinazione; il template generico non basta. [Secure Boot con Lanzaboote](secure_boot/README.it.md) è opzionale.

Il layout server Btrfs/LUKS prevede EFI da 1 GiB, swap cifrata con chiave casuale di dimensione `SWAP_SIZE` (predefinita `16G`) e LUKS2 con passphrase per subvolumi root, home, Nix store e `WORK_ROOT`. Il server disabilita ibernazione e resume. La formattazione è un passo di installazione esplicito, mai una conseguenza della selezione di un modulo durante una normale ricostruzione.

Usa `external-hardware-configuration.nix` opzionale per stampanti, scanner e altre periferiche di destinazione. Controlla le dichiarazioni di esempio prima di importarlo.

## Rete, SSH e RDP

`nm_configurations.nix` gestisce WiFi e intervalli di accesso ai servizi. Prepara le liste IPv4/IPv6 consentite a partire dai CIDR pubblici SSH e RDP. Le regole usano le porte effettive dei servizi; liste server vuote non aprono porte SSH/RDP. Il client conserva la policy SSH di base salvo configurazione di un filtro per subnet. Vedi la [guida di rete](../common/network/README.it.md).

Per WiFi prepara `ENABLE_WIFI` e `WIFI_SSID_NIX` e inserisci `wifi_env` cifrato con `WIFI_PSK` nel file segreti dell'host. Il file SOPS predefinito dell'host è `../../../secrets/<hostname>.yaml`; i dati condivisi della chiave amministrativa provengono da `../../../secrets/common.yaml`. Segui la [guida SOPS](../common/config/SECRETS.it.md).

La scelta del desktop locale e Xfce RDP sono indipendenti. Il [modulo RDP](../common/gui/README.it.md) opzionale impedisce il login root e richiede una password PAM non vuota. Prepara password e reti consentite prima di affidarti a RDP; le chiavi SSH pubbliche non autenticano una sessione RDP.

## Account worker, directory di lavoro e alimentazione

L'amministratore essenziale appartiene a `wheel`. L'identità worker separata ha UID/GID privato propri, nessun privilegio `wheel` o Docker/libvirt e una home privata. Amministratore e worker condividono `WORK_GROUP` per accedere esplicitamente ai dati di lavoro. `WORK_ROOT` appartiene a root con modo `2750`; la directory `data` e le directory di lavoro selezionate usano proprietà worker, ereditarietà del gruppo e ACL predefinite. Gli alberi esistenti non vengono modificati ricorsivamente. Vedi la [guida account](../users/README.it.md).

Il server continua il lavoro con il coperchio chiuso, disabilita sospensione/ibernazione e non avvia il riposo per inattività. La gestione batteria UPower opzionale usa PowerOff alla soglia di azione prevista; con `ENABLE_BATTERY=false` il demone rimane disabilitato anche se Xfce lo richiede. Il modulo batteria client usa Hibernate alla soglia del 7% solo quando `boot.resumeDevice` è non vuoto; altrimenti usa PowerOff. I limiti di ricarica sono scelti dall’host: `CHARGE_LIMIT_MODE` accetta `none` (predefinito, nessun limite impostato) oppure `thresholds`, che usa `CHARGE_START_THRESHOLD` e `CHARGE_STOP_THRESHOLD` (valori pubblici predefiniti 75/80). Scegli soglie supportate dal plugin TLP dell’hardware reale; il modulo comune non impone soglie di ricarica.

### Esempio manuale: Lenovo non ThinkPad

Per un modello supportato, la [documentazione TLP per Lenovo non ThinkPad](https://linrunner.de/tlp/settings/bc-vendors.html#lenovo-non-thinkpad-series) descrive la modalità conservazione con valori 0/1. Il firmware fissa il limite di carica secondo il modello; questo non garantisce una soglia dell'80%.

Mantieni `CHARGE_LIMIT_MODE=none` in `env.conf` così il blocco delle soglie generiche resta inattivo. Aggiungi e decommenta manualmente questo esempio soltanto nel `configuration.nix` dell'host pertinente:

```nix
# Optional host-only settings for a supported Lenovo non-ThinkPad model.
# services.tlp.settings = {
#   START_CHARGE_THRESH_BAT0 = 0;
#   STOP_CHARGE_THRESH_BAT0 = 1;
# };
```

Su un server imposta `services.tlp.enable = true;` se necessario. Imposta `services.tlp.settings.TLP_DISABLE_DEFAULTS = 1;` soltanto se TLP deve applicare i limiti di carica senza gli altri suoi valori predefiniti.

## Manutenzione Btrfs

Il modulo snapshot condiviso configura `/` e `/home` separatamente quando il rispettivo mount è Btrfs. I client concedono esplicitamente all'amministratore selezionato accesso agli snapshot home. Un server con `WORK_ROOT` Btrfs aggiunge una policy snapshot di lavoro senza utenti/gruppi non root o accesso ACL sincronizzato.

Scrub e snapshot sono moduli opzionali indipendenti. Il modulo Btrfs Assistant opzionale separato installa soltanto il pacchetto della GUI; il desktop selezionato fornisce Polkit e il relativo agent di autenticazione. Il modulo snapshot funziona senza GUI o desktop. Un subvolume Nix store separato è escluso dagli snapshot root/home del genitore, così come EFI e swap. Un layout root unico senza subvolume `/nix` separato può includere il Nix store negli snapshot root. Vedi la [guida alla configurazione](../common/config/README.it.md).

## Syncthing specifico dell'host

Mantieni Syncthing nel file `syncthing.nix` dell'host. Imposta esplicitamente `ENABLE_SYNCTHING`. Con `SYNCTHING_DEVICE_ID` vuoto non vengono dichiarati peer o cartella. Un peer configurato richiede ID dispositivo reale, endpoint TCP fisso raggiungibile, `SYNCTHING_FOLDER_ID` condiviso corrispondente e `SYNCTHING_FOLDER_PATH` assoluto. La cartella dati sincronizzata sul server deve essere `WORK_ROOT/data`; un client può scegliere un altro percorso dati assoluto. Discovery, relay e NAT traversal sono disabilitati, quindi scegli un indirizzo raggiungibile secondo la policy di rete.

I client eseguono il servizio con l'identità amministrativa; i server usano un account `syncthing` dedicato, con stato del servizio fuori da `WORK_ROOT` e accesso al gruppo di lavoro solo quando è attivo il servizio di sistema. La sincronizzazione usa `sendreceive`, conserva i permessi Unix, esclude directory comuni di dipendenze/cache e propaga modifiche ed eliminazioni in entrambe le direzioni.

Il listener è `tcp4://:22222`; non vengono aperte porte predefinite. Configura manualmente accessi in ingresso nella policy di rete dell'host soltanto dove servono. La GUI HTTPS ascolta su `127.0.0.1:8843`. Raggiungila tramite tunnel, adattando account, host e porta SSH:

```bash
ssh -p 22 -L 8843:127.0.0.1:8843 admin@example-host
```

Poi apri localmente `https://127.0.0.1:8843`. Consulta le guide account e SOPS prima dell'attivazione.
