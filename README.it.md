# Un Altro Template per Configurazioni NixOS

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Un approccio basato su template per configurare e replicare rapidamente e in modo coerente NixOS.

## Introduzione

Tornando a Linux come sistema operativo principale, desideravo una configurazione stabile, sicura e facilmente replicabile, che mi permettesse di passare da un disco rigido vuoto a una workstation completamente configurata, con le mie impostazioni personali, nel minor tempo possibile.

Volevo anche un sistema operativo che facilitasse la gestione dei client aziendali, consentendo la replica esatta degli ambienti (esclusi i dati specifici dell'utente). Per me, la risposta è stata **NixOS**.

Inizialmente, all'inizio del 2023, ho iniziato a esplorare NixOS ma ho abbandonato il progetto per mancanza di tempo, passando a Fedora KDE (che ho adorato e che potevo configurare in meno di un'ora da zero). Alla fine del 2024, desideroso di investire tempo nello sviluppo di dotfiles per un ambiente grafico completamente personalizzato e replicabile, ho deciso di fare un passo avanti. Invece di limitarmi a rivedere il mio ambiente desktop, volevo ricostruire l'intera configurazione del mio sistema operativo, quindi sono tornato a NixOS.

Ho trascorso innumerevoli ore leggendo il manuale ufficiale, guardando video su YouTube e studiando i file di configurazione di altri utenti su GitHub (tutte le fonti sono elencate nella sezione [Fonti](#fonti)). Ho quindi scelto di scrivere tutti i file di configurazione da zero, strutturando cartelle e file per soddisfare le mie esigenze, mantenendo i principi di **“Keep It Simple”** e **“Less Is More”**.

**Perché condividere questi file?**  
Ho deciso di trasformare le mie configurazioni in un template leggibile e riccamente commentato che chiunque può copiare e modificare secondo necessità. Ho anche creato uno script per automatizzarne la personalizzazione.

---

## Informazioni sui Branch

Questo repository mantiene diversi branch per diverse versioni di NixOS:

- **`master`** - Contiene configurazioni per **NixOS 25.05**
- **`25.05`** - Contiene configurazioni per **NixOS 25.05** (mergiato nel master)
- **`24.11`** - Contiene configurazioni per **NixOS 24.11**

Scegli il branch appropriato in base alla tua versione di NixOS. Il branch master è sempre allineato con l'ultima versione supportata di NixOS.

---

## Spiegazione delle Scelte

Nel 2023, ho commesso l'errore di iniziare subito con **Flakes** e **Home Manager**, pensando di dover includere tutto fin dall'inizio. Questa complessità mi ha portato ad abbandonare il progetto. Nel 2024, ho quasi ripetuto lo stesso errore finché non ho letto [questo aggiornamento](https://github.com/Misterio77/nix-starter-configs/issues/86) da [Misterio77’s nix-starter-configs](https://github.com/Misterio77/nix-starter-configs). È stato uno dei tanti spunti che suggerivano di introdurre Flakes e Home Manager solo se realmente necessari, e non subito.

---

## Struttura delle Cartelle e dei File

Di seguito è riportata la struttura delle directory pianificata, insieme ai file inclusi. Ogni sottocartella ha il proprio file README dedicato che spiega in dettaglio i file e le sottocartelle:
```bash
nixos_configs/                    # Cartella principale
└── common/                       # File di configurazione e sottocartelle comuni a tutti gli host/utenti
    ├── config/                   # Configurazioni relative al sistema operativo
    ├── gui/                      # Configurazioni relative all'interfaccia grafica
    │   └── themes/               # Temi per vari software (GRUB, Hyprland, Plymouth)
    ├── packages/                 # Configurazioni per i pacchetti software da installare
    └── network/                  # Configurazioni relative alla rete
    │   └── nmconnection_files/   # File di connessione di NetworkManager
└── hosts/                        # Sottocartelle per ogni host definito
    └── ABC/                      # File di configurazione per l'host 'ABC'
└── users/                        # Sottocartelle per ogni utente definito
    └── XYZ/                      # File di configurazione per l'utente 'XYZ'
        └── dotfile/              # Dotfiles per l'utente 'XYZ'
```

### La Cartella `nixos_configs`

La cartella `nixos_configs` contiene tutti i file di configurazione necessari per il tuo ambiente.  
Deve essere **copiata sul sistema di destinazione**, e sarà necessario sostituire il percorso all'interno dei file di configurazione ovunque siano presenti riferimenti ai percorsi di copia dei file. Questo garantisce che il processo di build possa accedere ai file specificati.

All'interno di `nixos_configs`, ci sono tre sottocartelle principali:

1. [`common`](#common)
2. [`hosts`](#hosts)
3. [`users`](#users)

---

#### `common`

La cartella **`common`** contiene file di configurazione di NixOS condivisi da tutti gli host e utenti. Al suo interno ci sono quattro sottocartelle:

- **`config`** – Contiene configurazioni relative al sistema operativo come parametri di boot con crittografia LUKS, schermata di avvio Plymouth, regole sudo e impostazioni di sistema.
- **`gui`** – Contiene configurazioni per le interfacce grafiche (attualmente Hyprland e KDE), tra cui puoi scegliere, e una sottocartella `themes` con temi per vari software.  
- **`packages`** – Specifica quali pacchetti installare e quali servizi abilitare.  
- **`network`** – Configurazioni relative alla rete. All'interno di questa cartella c'è un'altra sottocartella, `nmconnection_files`, che contiene i file di connessione di NetworkManager.

---

#### `hosts`

La cartella **`hosts`** memorizza le configurazioni dei singoli host, ognuno nella propria sottocartella denominata con il nome dell'host. All'interno della sottocartella di ogni host troverai:

- **`configuration.nix`** – La configurazione base per quell'host specifico. Qui specifichi quali pacchetti e servizi comuni importare da `common/packages` e quali utenti vuoi definire.
- **Un file di configurazione `Disko`** *(opzionale)* – Fai riferimento al [README](./nixos_configs_template/hosts/disk_configurations/README.it.md) presente nella cartella `disk_configurations` per maggiori informazioni.
- **`hardware-configuration.nix`** – Definisce le impostazioni hardware specifiche. Puoi ottenere questo file:
  - Copiandolo da `/etc/nixos` dopo aver installato NixOS da una [ISO ufficiale](https://nixos.org/download/).
  - Generandolo tramite `nixos-generate-config` sull'host.
  - Importandolo dal repository ufficiale [nixos-hardware](https://github.com/NixOS/nixos-hardware), che ospita una raccolta di configurazioni hardware-specifiche.

- (Opzionale) Il file `nm_configurations.nix` per importare connessioni specifiche di Network Manager necessarie per quell'host.

Per aggiungere un nuovo host, crea una nuova cartella con il nome dell'host e posiziona al suo interno sia `configuration.nix` che `hardware-configuration.nix`. In `configuration.nix`, assicurati di fare riferimento a:

- Le configurazioni desiderate in `common/packages`.
- Gli utenti che vuoi abilitare per quell'host.

---

#### `users`

La cartella **`users`** contiene configurazioni per i singoli utenti, ognuno nella propria sottocartella denominata con il nome dell'utente. All'interno di ogni sottocartella utente:

- **`USERNAME.nix`** – Il file di configurazione di NixOS per quell'utente.
- Una sottocartella **`dotfiles`** – Contiene i dotfiles personali dell'utente, che verranno copiati nella directory `~/.config/` dell'utente.

Farai riferimento alla configurazione di un utente nel file `configuration.nix` dell'host scelto per rendere disponibile quell'utente durante la build del sistema.

---

## Utilizzo

Fai riferimento al file [`HOWTO.md`](HOWTO.it.md) per sapere come utilizzare i file di configurazione.

---

## Motivazioni Aggiuntive

Ho usato la necessità di "replicare rapidamente le configurazioni della workstation" come scusa per provare **NixOS** e il suo approccio a sistema immutabile. Ovviamente, esistono molti altri modi per ottenere risultati simili (ad esempio, usando Ansible), ma volevo un progetto che mi permettesse anche di sfruttare i servizi di Intelligenza Artificiale per certi compiti, come aggiungere commenti esplicativi accanto a ogni pacchetto, cosa che mi ha fatto risparmiare molto tempo.

Questo progetto è ancora un **work in progress**: i prossimi passaggi (vedi [To-Do](#to-do)) devono ancora essere implementati.

---

## Da Fare

- ~~**Installazione con Btrfs**  
  Gli installer grafici attualmente permettono solo la formattazione del disco root con filesystem `ext4`. Tuttavia, è possibile configurare manualmente un filesystem `Btrfs`.  
  Vedi [Btrfs sulla Wiki di NixOS](https://nixos.wiki/wiki/Btrfs).~~
  ✅ *Completato: configurazione tramite Disko aggiunta a Marzo 2025.*

- **Attivazione Secure Boot con Lanzaboote**  
  Abilitare il Secure Boot utilizzando il tool della community [Lanzaboote](https://github.com/nix-community/lanzaboote).

- **Importazione del Profilo KDE**  
  Importare automaticamente il profilo KDE durante la build, senza doverlo importare manualmente.

- **Migliorare lo script `nixos_config_generator.sh`**  
  Aggiungere funzionalità per generare file di configurazione e hardware tramite `nixos-generate-config`.

---

## Contribuire

Se trovi utili queste configurazioni o vuoi aiutare a migliorarle, sentiti libero di aprire una pull request o creare un'issue nel repository.

---

## Fonti

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