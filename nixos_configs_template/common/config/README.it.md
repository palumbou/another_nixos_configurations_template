# Configurazione del Sistema

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questa cartella contiene file di configurazione di base del sistema che definiscono i comportamenti fondamentali del sistema e i privilegi degli utenti.

## File Disponibili

- **`audio.nix`** - Configurazione audio centralizzata con PipeWire, session manager wireplumber, rtkit per la priorità real-time, supporto ALSA (32-bit e 64-bit), layer di compatibilità PulseAudio, supporto JACK per applicazioni audio professionali e utility audio (strumenti CLI pulseaudio, GUI pwvucontrol). Importato automaticamente dalle configurazioni degli ambienti desktop (Hyprland, GNOME, KDE)
- **`audio_airplay.nix`** - Supporto opzionale per lo streaming AirPlay/RAOP per inviare audio a dispositivi compatibili AirPlay (Apple HomePod, speaker Denon Home, ecc.). Configura il modulo libpipewire-module-raop-discover di PipeWire e Avahi mDNS per il rilevamento dei dispositivi. Importare solo nelle configurazioni host che necessitano della funzionalità AirPlay
- **`audio_chromecast.nix`** - Supporto opzionale per lo streaming Google Cast (Chromecast) per inviare audio a dispositivi compatibili Cast (speaker Google Home/Nest, Chromecast, ecc.). PipeWire non ha un modulo Cast nativo, quindi questo file esegue pulseaudio-dlna come servizio utente systemd che crea un sink audio virtuale per ogni dispositivo rilevato in LAN (funziona con PipeWire tramite il layer di compatibilità pipewire-pulse). Configura inoltre Avahi mDNS per il rilevamento dei dispositivi e apre le porte firewall necessarie per lo streaming (TCP 8080, UDP 1900). Importare solo nelle configurazioni host che necessitano della funzionalità Google Cast
- **[`battery_management.nix`](battery_management.nix)** - Tre profili energetici TLP: Performance con alimentatore, Bilanciato in batteria e Risparmio manuale. Importa automaticamente `energy_profiles.nix` e può essere usato anche sui fissi. I limiti di ricarica appartengono all’host e al plugin hardware TLP, senza soglie comuni imposte. UPower usa percentuali: batteria bassa al 15%, critica al 10% e azione al 7% in scarica. L’azione è `Hibernate` soltanto con `boot.resumeDevice` non vuoto; altrimenti è `PowerOff`. Verifica comunque che la configurazione di resume dell’host sia funzionante
- **`boot_luks.nix`** - Configurazione per il boot con crittografia LUKS e impostazioni Plymouth per la schermata di avvio; abilita inoltre automaticamente lo stack userspace TPM2 quando un device LUKS è impostato per sbloccarsi via TPM2 (vedi [LUKS_KEYS.it.md](../../hosts/disk_configurations/LUKS_KEYS.it.md))
- **`btrfs_scrub.nix`** - Scrub btrfs periodico tramite `services.btrfs.autoScrub`: rilegge ogni blocco allocato e ne verifica il checksum, intercettando la corruzione silenziosa (bit rot) prima di incontrarla aprendo un file. I metadati corrotti vengono riparati dalla seconda copia quando il profilo è DUP o RAID (DUP è il default di mkfs per i metadati), mentre gli errori dentro un chunk dati in profilo single possono solo essere segnalati nel journal. Gira mensilmente a bassa priorità di CPU e I/O su ogni mount point btrfs, deduplicato per device, quindi i subvolumi di uno stesso disco producono una sola unit. Importare solo negli host il cui filesystem è Btrfs: altrove la lista dei filesystem risulta vuota e la build fallisce su un'asserzione
- **`btrfs_snapshots.nix`** - Snapshot timeline Snapper ogni ora e pulizia giornaliera, con selezione indipendente di `/` e `/home` solo quando il rispettivo mount è Btrfs. Il modulo crea automaticamente i contenitori `.snapshots` dalle configurazioni Snapper, senza dipendere da desktop o utenti. Un subvolume Nix store separato, EFI e swap restano fuori dagli snapshot root/home; un layout root unico può includere `/nix` se non è un subvolume separato. Le ACL home sono definite nell’host client per l’amministratore selezionato; il server aggiunge la policy del subvolume di lavoro nell’host e gestisce gli snapshot tramite sudo. La GUI [Btrfs Assistant](../packages/README.it.md) è nel modulo opzionale separato `common/packages/btrfs_assistant.nix`, che installa soltanto il pacchetto della GUI. Il desktop selezionato fornisce Polkit; i prompt grafici richiedono il relativo agent di autenticazione attivo. Le CLI `snapper` e `btrfs-progs` provengono dai moduli NixOS corrispondenti
- **[`disko.nix`](disko.nix)** - Modulo Disko condiviso fissato alla versione prevista. Importalo insieme a una ricetta disco preparata quando scegli un layout; le dichiarazioni non eseguono formattazione durante una normale ricostruzione
- **[`energy_profiles.nix`](energy_profiles.nix)** - CLI `energy-profile` e azione Polkit dedicata per la selezione manuale temporanea dei profili. Richiede TLP 1.9 o successivo; importato automaticamente da `battery_management.nix`. Gli utenti `wheel` con sessione locale attiva possono scegliere il profilo, mentre `energy-profile status` restituisce JSON senza privilegi elevati
- **`os_compatibility.nix`** - Abilita la compatibilità con binari precompilati su NixOS usando nix-ld. Fornisce i percorsi delle librerie standard di Linux e le librerie condivise comuni (libc, libstdc++, X11, OpenGL, audio, ecc.) permettendo l'esecuzione di binari non-NixOS senza patch. Include supporto per applicazioni compatibili con FHS (Filesystem Hierarchy Standard). Configura inoltre le regole udev per l'accesso ai dispositivi HID (necessario per l'API WebHID in Chrome/Chromium per accedere a tastiere, mouse e altri dispositivi USB/HID) utilizzando il moderno meccanismo TAG+="uaccess". Sicuro da tenere abilitato anche quando non si usano attivamente binari esterni (importato automaticamente da `roles/client.nix`)
- **`os_optimization.nix`** - Impostazioni di ottimizzazione del sistema incluse garbage collection automatica, ottimizzazione del Nix store, limiti del journal di systemd, supporto TRIM per SSD e configurazione zram (importato automaticamente da `roles/client.nix`)
- **`secrets.nix`** - Gestione dei segreti con [sops-nix](https://github.com/Mic92/sops-nix), pinnato per commit: gli host decifrano i file in `secrets/` con la chiave age derivata dalla propria chiave SSH host, e i tool di editing (`sops`, `age`, `ssh-to-age`) vengono installati a sistema. Richiesto quando l'host importa moduli che dichiarano segreti `sops.*`, poiché i moduli condivisi (utente, WiFi) dichiarano segreti `sops.*`. Guida completa: [SECRETS.it.md](SECRETS.it.md)
- **`sudo.nix`** - Configurazione per i privilegi sudo e le autorizzazioni degli utenti (importato automaticamente da `roles/client.nix`)
- **`system.nix`** configura locale, fuso orario e tastiera. È importato da `roles/base.nix`; `system.stateVersion` resta nella configurazione di ciascun host.

## Utilizzo

Per un client in `hosts/client/<nome>/configuration.nix`, importa il ruolo client e scegli i moduli opzionali. Per un server, vedi la [guida ai ruoli](../../roles/README.it.md):

```nix
imports = [
  # Other imports...
  ../../../common/config/audio_airplay.nix  # Optional: AirPlay/RAOP streaming.
  ../../../common/config/audio_chromecast.nix  # Optional: Google Cast streaming.
  ../../../common/config/boot_luks.nix  # Optional: encrypted boot and Plymouth.
  ../../../common/config/btrfs_scrub.nix  # Optional: Btrfs hosts.
  ../../../common/config/btrfs_snapshots.nix  # Optional: Btrfs root/home subvolumes.
  ../../../common/config/secrets.nix  # For modules declaring SOPS secrets.
  ../../../common/config/battery_management.nix  # Optional: TLP power profiles.
  ../../../roles/client.nix  # Base settings, compatibility, optimizations and sudo.
  # Other optional modules...
];
```

> **Nota**: `roles/client.nix` importa `os_compatibility.nix`, `os_optimization.nix` e `sudo.nix`; `roles/base.nix` importa le impostazioni comuni di locale, fuso orario e tastiera. I moduli degli ambienti desktop (Hyprland, GNOME, KDE) importano `audio.nix`.

Le selezioni opzionali `audio`, `audio_airplay` e `audio_chromecast` corrispondono ai rispettivi moduli. Senza desktop locale, importa anche `audio.nix` quando scegli uno dei moduli di streaming; i desktop GNOME/KDE/Hyprland lo importano già.

`battery_management.nix` importa anche `energy_profiles.nix`: gli host che importano già la gestione batteria non richiedono un ulteriore import.

### Selezione dei profili snapshot

`btrfs_snapshots.nix` controlla separatamente le dichiarazioni `fileSystems."/".fsType` e `fileSystems."/home".fsType`. Crea il profilo `root` o `home` soltanto quando il rispettivo mount è dichiarato `btrfs`. Queste condizioni permettono di usare il modulo sia con root e home separate sia con un layout che ha soltanto il subvolume root; non rilevano il filesystem o i subvolumi presenti sul disco durante la valutazione.

Con `/` e `/home` dichiarati Btrfs rimangono attivi entrambi i profili. Se `/home` è una normale directory del subvolume root, è già compresa negli snapshot root e non viene creato un profilo home separato. Un subvolume home autonomo non è incluso negli snapshot del padre: per proteggerlo, dichiaralo come mount Btrfs oppure aggiungi esplicitamente il suo profilo Snapper nell’host.

## Profili Energetici

Automatico seleziona Performance con alimentatore e Bilanciato in batteria. Un fisso senza batteria di sistema usa automaticamente Performance. Risparmio si seleziona manualmente.

| Impostazione | Performance (`AC`) | Bilanciato (`BAT`) | Risparmio (`SAV`) |
|---|---|---|---|
| Governor CPU | `performance` | `powersave` | `powersave` |
| Preferenza energetica | `performance` | `balance_performance` | `balance_power` |
| Turbo consentito | Sì | Sì | No |
| Profilo firmware | `performance` | `balanced` | `balanced` |

Questi governor predefiniti sono pensati per i driver `intel_pstate`/`amd-pstate` in modalità attiva. Personalizza `services.tlp.settings` nella configurazione dell'host se il driver o il firmware richiede valori differenti; `tlp-stat -p` mostra quelli supportati. Per esempio, un host con `acpi-cpufreq` può usare `schedutil` invece di `powersave`.

Dopo il rebuild NixOS, usa:

```bash
energy-profile auto         # Ripristina la selezione automatica in base all'alimentazione
energy-profile performance  # Forza Performance, anche in batteria
energy-profile balanced     # Forza Bilanciato, anche con alimentatore
energy-profile saver        # Seleziona Risparmio manualmente
energy-profile status       # Legge profilo, modalità e alimentazione in JSON
```

Le scelte manuali restano attive collegando o scollegando l'alimentatore e dopo la sospensione; terminano tornando in Automatico o riavviando. Si usa soltanto lo stato temporaneo nativo di TLP, senza creare un ulteriore file di stato. I cambi di profilo sono autorizzati da un'azione Polkit dedicata agli utenti `wheel` con una sessione locale attiva. Il modulo richiede TLP 1.9 o successivo e verifica le impostazioni native di commutazione necessarie a questo comportamento.

## Personalizzazione

I file di configurazione in questa directory definiscono le impostazioni fondamentali del sistema. Puoi:

- Personalizzare `services.tlp.settings` per host per regolare i profili dichiarati da `battery_management.nix`, mantenendo riutilizzabili i valori comuni. Seleziona nell’host modalità di ricarica e soglie supportate dall’hardware; il modulo fornisce soglie UPower in percentuale e sceglie Hibernate soltanto se è configurato un dispositivo di resume
- Modificare `boot_luks.nix` per personalizzare le impostazioni di boot crittografato e la configurazione di Plymouth
- Modificare `btrfs_scrub.nix` per cambiare l'intervallo dello scrub, limitarlo a una lista specifica di filesystem o mettere un tetto al throughput con `limit` sui dischi lenti
- Modificare `btrfs_snapshots.nix` per cambiare quali subvolumi vengono snapshottati, l'intervallo degli snapshot e quanti snapshot orari/giornalieri/settimanali/mensili conservare; i contenitori snapshot seguono automaticamente i subvolumi Btrfs configurati
- Gestire i segreti cifrati stessi con `sops secrets/common.yaml` (vedi [SECRETS.it.md](SECRETS.it.md)); `secrets.nix` va modificato solo per aggiornare il pin di sops-nix
- Modificare `sudo.nix` per regolare i livelli di privilegio degli utenti e le politiche di sicurezza (nota: importato automaticamente da `roles/client.nix`)
- Modificare `os_optimization.nix` per ottimizzare la garbage collection di Nix, l'ottimizzazione dello store e la gestione delle risorse di sistema (nota: importato automaticamente da `roles/client.nix`)
- Aggiornare `system.nix` per cambiare locale, fuso orario e tastiera
- Fare riferimento a variabili specifiche dell'host per personalizzare le impostazioni per ogni macchina

### Esempio di Modifica

Se desideri personalizzare le impostazioni di sistema in `system.nix`:

```nix
# Nel file system.nix
{ config, pkgs, ... }:

{
  # Imposta il tuo fuso orario
  time.timeZone = "Europe/Rome";
  
  # Seleziona le proprietà di internazionalizzazione
  i18n.defaultLocale = "it_IT.UTF-8";
  
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };
  
  # Aggiungi qui le tue impostazioni di sistema personalizzate
  # Nota: system.stateVersion è impostato per host in hosts/client/<nome>/configuration.nix,
  # perché registra la release NixOS con cui ciascun host è stato installato la prima volta.
}
```

### Considerazioni

- I file di configurazione in questa directory formano la base della tua configurazione di sistema
- Fai attenzione quando modifichi le impostazioni di base poiché possono influire sulla stabilità del sistema
- Testa sempre le modifiche in un ambiente controllato prima di implementarle sui sistemi di produzione
