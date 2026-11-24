# Un Altro Template per Configurazioni NixOS

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Un approccio basato su template per configurare e replicare rapidamente e in modo coerente NixOS.

## Introduzione

Tornando a Linux come sistema operativo principale, desideravo una configurazione stabile, sicura e facilmente replicabile, che mi permettesse di passare da un disco rigido vuoto a una workstation completamente configurata, con le mie impostazioni personali, nel minor tempo possibile.

Volevo anche un sistema operativo che facilitasse la gestione dei client aziendali, consentendo la replica esatta degli ambienti (esclusi i dati specifici dell'utente). Per me, la risposta è stata **NixOS**.

Inizialmente, all'inizio del 2023, ho iniziato a esplorare NixOS ma ho abbandonato il progetto per mancanza di tempo, passando a Fedora KDE (che ho adorato e che potevo configurare in meno di un'ora da zero). Alla fine del 2024, desideroso di investire tempo nello sviluppo di dotfiles per un ambiente grafico completamente personalizzato e replicabile, ho deciso di fare un passo avanti. Invece di limitarmi a rivedere il mio ambiente desktop, volevo ricostruire l'intera configurazione del mio sistema operativo, quindi sono tornato a NixOS.

Ho trascorso innumerevoli ore leggendo il manuale ufficiale, guardando video su YouTube e studiando i file di configurazione di altri utenti su GitHub (tutte le fonti sono elencate nella sezione [Fonti](#fonti--riferimenti)). Ho quindi scelto di scrivere tutti i file di configurazione da zero, strutturando cartelle e file per soddisfare le mie esigenze, mantenendo i principi di **“Keep It Simple”** e **“Less Is More”**.

**Perché condividere questi file?**  
Ho deciso di trasformare le mie configurazioni in un template leggibile e riccamente commentato che chiunque può copiare e modificare secondo necessità.

---

## Informazioni sui Branch

Questo repository mantiene diversi branch per diverse versioni di NixOS:

- **`master`** - Contiene configurazioni per **NixOS 26.05**
- **`26.05`** - Contiene configurazioni per **NixOS 26.05** (allineato con master)
- **`25.11`** - Contiene configurazioni per **NixOS 25.11**
- **`25.05`** - Contiene configurazioni per **NixOS 25.05**
- **`24.11`** - Contiene configurazioni per **NixOS 24.11**

Scegli il branch appropriato in base alla tua versione di NixOS. Il branch master è sempre allineato con l'ultima versione supportata di NixOS.

---

## Spiegazione delle Scelte

Nel 2023, ho commesso l'errore di iniziare subito con **Flakes** e **Home Manager**, pensando di dover includere tutto fin dall'inizio. Questa complessità mi ha portato ad abbandonare il progetto. Nel 2024, ho quasi ripetuto lo stesso errore finché non ho letto [questo aggiornamento](https://github.com/Misterio77/nix-starter-configs/issues/86) da [Misterio77’s nix-starter-configs](https://github.com/Misterio77/nix-starter-configs). È stato uno dei tanti spunti che suggerivano di introdurre Flakes e Home Manager solo se realmente necessari, e non subito.

---

## Struttura delle Cartelle e dei File

L'albero di configurazione riutilizzabile si trova in `nixos_configs_template/`. Copialo nella posizione desiderata e prepara manualmente i template selezionati; puoi chiamare `nixos_configs/` l'albero risultante. Mantieni la struttura relativa delle directory.

```text
nixos_configs_template/
├── common/
│   ├── config/                   # System settings, power, snapshots and SOPS
│   ├── gui/                      # Local desktops and optional Xfce RDP
│   ├── network/                  # Client and server networking
│   ├── packages/                 # Independent application groups
│   └── services/                 # Docker, libvirt and server SSH
├── roles/                        # base.nix, client.nix, server.nix
├── hosts/
│   ├── client/ABC/               # Client host example
│   ├── server/ABC/               # Server host example
│   ├── disk_configurations/      # Shared Disko layouts
│   └── secure_boot/              # Lanzaboote configuration
├── users/
│   ├── ADMIN/                    # admin.nix and optional client.nix
│   └── WORKER/                   # worker.nix
├── secrets/                      # Encrypted data prepared separately
└── .sops.yaml                    # Recipient rules prepared separately
```

### Preparazione di un host

Leggi [`env.conf`](env.conf) per i nomi dei parametri pubblici e i valori di esempio. Copia `hosts/client/ABC` oppure `hosts/server/ABC` in una directory dell'host nella stessa categoria. Prepara i file `.nix.template` selezionati come file `.nix` e sostituisci soltanto i segnaposto documentati con i valori dell'host. Modificare `env.conf` da solo non sostituisce alcun valore. La [guida HOWTO](HOWTO.it.md) spiega tipi dei valori, elenchi degli import opzionali e installazione.

Un host in `hosts/client/<nome>/` o `hosts/server/<nome>/` importa moduli comuni, ruoli e utenti tramite `../../../`. I layout Disko condivisi e i moduli Secure Boot si raggiungono con `../../disk_configurations/` e `../../secure_boot/`. Ottieni una dichiarazione hardware per la macchina reale con `nixos-generate-config` o un modulo [nixos-hardware](https://github.com/NixOS/nixos-hardware) appropriato; i campi pubblici di CPU e piattaforma sono esempi e non sostituiscono il rilevamento dell'hardware.

### `common`

La [guida common](nixos_configs_template/common/README.it.md) collega le cinque categorie di moduli. Desktop locale (`none`, KDE, GNOME o Hyprland), Xfce RDP opzionale, gruppi di applicazioni e demoni locali sono scelte indipendenti. Un host senza desktop può comunque abilitare Docker, libvirt, Syncthing, snapshot e strumenti da terminale.

Importare [`battery_management.nix`](nixos_configs_template/common/config/battery_management.nix) installa anche `energy-profile` tramite [`energy_profiles.nix`](nixos_configs_template/common/config/energy_profiles.nix), con requisito TLP 1.9 o successivo. Il funzionamento automatico sceglie Performance con alimentazione AC e Balanced a batteria. Usa temporaneamente `energy-profile performance`, `energy-profile balanced` o `energy-profile saver`; `energy-profile auto` ripristina la modalità automatica e `energy-profile status` restituisce JSON. Il riavvio ripristina la modalità automatica tramite lo stato nativo TLP. Gli utenti locali attivi in `wheel` possono cambiare profilo attraverso l'azione Polkit dedicata.

Balanced consente il turbo e usa `balance_performance`; Saver, scelto manualmente, usa `balance_power` e disabilita il turbo. I governor predefiniti sono pensati per `intel_pstate`/`amd-pstate` attivi. Sovrascrivi `services.tlp.settings` per altri driver o nomi dei profili firmware e consulta `tlp-stat -p` per i valori supportati. I valori firmware predefiniti sono `performance` con AC e `balanced` per entrambi i profili a batteria.

Gli snapshot Btrfs usano il modulo di base separato che rileva i filesystem. Il modulo opzionale `btrfs_assistant.nix` installa separatamente il pacchetto della GUI. Il desktop selezionato fornisce Polkit; le richieste grafiche di privilegi richiedono anche il relativo agent di autenticazione attivo. Vedi la [guida alla configurazione](nixos_configs_template/common/config/README.it.md) e la [guida ai pacchetti](nixos_configs_template/common/packages/README.it.md).

### `roles` e `hosts`

I [ruoli](nixos_configs_template/roles/README.it.md) compongono moduli condivisi: `base.nix` fornisce lingua, fuso orario e tastiera; `client.nix` aggiunge compatibilità dei binari, ottimizzazioni e regole sudo client; `server.nix` aggiunge strumenti da terminale essenziali, SSH server e rete server. L'host sceglie ruolo, utenti, hardware, storage, avvio e funzioni opzionali. Mantieni `system.stateVersion` alla versione della prima installazione.

La [guida host](nixos_configs_template/hosts/README.it.md) descrive gli esempi client e server. WiFi, restrizioni di accesso SSH/RDP e Syncthing risiedono nella directory di ogni host. La [guida Disko](nixos_configs_template/hosts/disk_configurations/README.it.md) comprende un layout server con partizione EFI da 1 GiB, swap cifrata con chiave casuale e LUKS2 con passphrase per i subvolumi Btrfs di root, home, Nix store e directory di lavoro. [Secure Boot](nixos_configs_template/hosts/secure_boot/README.it.md) rimane opzionale.

### `users` e segreti

I [moduli account](nixos_configs_template/users/README.it.md) separano l'identità amministrativa, le personalizzazioni client opzionali e l'identità worker. L'account worker usa un gruppo e una directory di lavoro dedicati. Prepara i dati delle chiavi SSH pubbliche tramite i valori cifrati condivisi e dell’host usati dalla configurazione host e mantieni password, hash delle password, PSK WiFi e chiavi private fuori da `env.conf` e dai file Nix in chiaro. Segui la [guida SOPS](nixos_configs_template/common/config/SECRETS.it.md) per preparare valori cifrati e destinatari. Le dichiarazioni di dispositivi e cartelle Syncthing appartengono all'host selezionato.

---

## Utilizzo

Fai riferimento al file [`HOWTO.it.md`](HOWTO.it.md) per imparare come utilizzare i file di configurazione.

### Aggiornamento di NixOS

Per istruzioni dettagliate sull'aggiornamento del tuo sistema NixOS a una versione più recente (sia aggiornamenti minor che major), incluse informazioni importanti sulla variabile `stateVersion`, consulta il file [`UPGRADE_SYSTEM.it.md`](UPGRADE_SYSTEM.it.md).

---

## Motivazioni Aggiuntive

Ho usato la necessità di "replicare rapidamente le configurazioni della workstation" come scusa per provare **NixOS** e il suo approccio a sistema immutabile. Ovviamente, esistono molti altri modi per ottenere risultati simili (ad esempio, usando Ansible), ma volevo un progetto che mi permettesse anche di sfruttare i servizi di Intelligenza Artificiale per certi compiti, come aggiungere commenti esplicativi accanto a ogni pacchetto, cosa che mi ha fatto risparmiare molto tempo.

Questo progetto è ancora un **work in progress**: i prossimi passaggi (vedi [To-Do](#da-fare)) devono ancora essere implementati.

---

## Da Fare

- ~~**Installazione con Btrfs**  
  Gli installer grafici attualmente permettono solo la formattazione del disco root con filesystem `ext4`. Tuttavia, è possibile configurare manualmente un filesystem `Btrfs`.  
  Vedi [Btrfs sulla Wiki di NixOS](https://nixos.wiki/wiki/Btrfs).~~
  ✅ *Completato: configurazione tramite Disko aggiunta a Marzo 2025.*

- ~~**Attivazione Secure Boot con Lanzaboote**  
  Abilitare il Secure Boot utilizzando il tool della community [Lanzaboote](https://github.com/nix-community/lanzaboote).~~
  ✅ *Completato: file di configurazione e documentazione completa aggiunti a Gennaio 2026. Vedi [`hosts/secure_boot/`](nixos_configs_template/hosts/secure_boot/README.it.md) per i dettagli.*

- **Importazione del Profilo KDE**  
  Importare automaticamente il profilo KDE durante la build, senza doverlo importare manualmente.


---

## Contribuire

Se trovi utili queste configurazioni o vuoi aiutare a migliorarle, sentiti libero di aprire una pull request o creare un'issue nel repository.

---

## Fonti & Riferimenti

- **Vimjoyer’s YouTube Channel**  
  [https://www.youtube.com/@vimjoyer](https://www.youtube.com/@vimjoyer)  
  Il mio primo incontro con NixOS, con utili approfondimenti sul sistema.

- **Sascha Koenig’s “Rebuilding my NixOS flake configuration from scratch”**  
  [Playlist](https://www.youtube.com/playlist?list=PLCQqUlIAw2cCuc3gRV9jIBGHeekVyBUnC)  
  Questa serie ha fornito ispirazione per la struttura delle cartelle/file, che a sua volta si basa su:

- **Misterio77’s nix-starter-configs**  
  [https://github.com/Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)

- **Manuale Ufficiale di NixOS**  
  [https://nixos.org/manual/nixos/stable/](https://nixos.org/manual/nixos/stable/)

- **Wiki di NixOS**  
  [https://nixos.wiki/wiki/](https://nixos.wiki/wiki/)

- **Ricerca Pacchetti e Opzioni di Nix**  
  [https://search.nixos.org/packages](https://search.nixos.org/packages?)

- **Repository di file dotfiles e nix di notusknot**
  [https://github.com/notusknot/dotfiles-nix/](https://github.com/notusknot/dotfiles-nix/)

- **Esempio di configurazione (Blog)**  
  [https://0xda.de/blog/2024/06/framework-and-nixos-day-one/](https://0xda.de/blog/2024/06/framework-and-nixos-day-one/)

- **Altro esempio di configurazione (Blog)**  
  [https://bmcgee.ie/posts/2022/12/setting-up-my-new-laptop-nix-style/](https://bmcgee.ie/posts/2022/12/setting-up-my-new-laptop-nix-style/)

---

## Disclaimer

Questo progetto è ancora in **fase di sviluppo**, e sto ancora imparando a utilizzare questo sistema operativo.  
Non mi assumo alcuna responsabilità per eventuali malfunzionamenti o perdita di dati sul tuo computer.  
Usa questi file di configurazione a tuo rischio.
