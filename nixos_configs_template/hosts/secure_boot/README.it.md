# Secure Boot con NixOS

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questa guida illustra come abilitare **Secure Boot** su NixOS utilizzando due approcci:

1. **Metodo manuale** con `sbctl` (richiede firma manuale)
2. **Metodo automatizzato** con **Lanzaboote** (firma automatica)

---

## Introduzione

**Secure Boot** è una funzionalità di sicurezza del firmware UEFI che protegge il sistema garantendo che solo bootloader, kernel e driver firmati crittograficamente possano essere eseguiti durante il processo di avvio. Questo impedisce a malware e modifiche non autorizzate di essere eseguiti a livello di boot, fornendo un livello critico di sicurezza per il sistema.

**Come funziona:**  
Secure Boot utilizza firme digitali per verificare l'autenticità dei componenti di avvio. Quando abilitato, il firmware UEFI controlla ogni componente confrontandolo con le chiavi fidate memorizzate nel suo database prima di consentirne l'esecuzione. Solo i componenti correttamente firmati con firme valide possono avviare il sistema.

**Perché usare Secure Boot su NixOS?**  
- **Sicurezza avanzata**: protezione contro malware a livello di boot e rootkit
- **Verifica dell'integrità**: garantisce che non ci siano modifiche non autorizzate ai file di boot
- **Conformità**: richiesto per certi ambienti enterprise e sensibili alla sicurezza
- **Benefici della cifratura completa del disco**: quando combinato con TPM, fornisce una protezione più forte

**Due metodi di implementazione:**
1. **Manuale con sbctl**: ti dà controllo diretto ma richiede la firma dopo ogni aggiornamento del sistema
2. **Automatizzato con Lanzaboote**: integra la firma nel processo di rebuild di NixOS per un'operazione senza interruzioni

---

## Struttura della Cartella

```bash
hosts/
└── secure_boot/
    ├── lon.nix               # Definizione sorgente Lanzaboote
    └── secure_boot.nix       # File di configurazione Lanzaboote completo
```

**Descrizione dei file:**

- **`lon.nix`** - Definisce la posizione sorgente di Lanzaboote utilizzando `builtins.fetchTarball` per scaricare da GitHub. Questo file viene importato da `secure_boot.nix` per fornire il modulo Lanzaboote.

- **`secure_boot.nix`** - File di configurazione pronto da importare che:
  - Importa il modulo Lanzaboote da `lon.nix`
  - Disabilita il modulo systemd-boot standard (usando `lib.mkForce false`)
  - Abilita Lanzaboote con firma automatica dei file di boot
  - Include il pacchetto `sbctl` per la gestione delle chiavi
  - Configura il percorso PKI (`/var/lib/sbctl`)


---

## Prerequisiti

Prima di procedere, assicurati di avere:

1. **Firmware UEFI** (non BIOS legacy)
2. **Secure Boot inizialmente disabilitato** nelle impostazioni del firmware
3. **systemd-boot** come bootloader (richiesto da entrambi i metodi)

Per verificare che systemd-boot sia attivo:

```bash
bootctl status
```

Questo comando mostra anche lo stato attuale di Secure Boot e altre informazioni importanti:
- Bootloader corrente e tipo di firmware (deve essere UEFI)
- Se Secure Boot è **abilitato** o **disabilitato**
- Voci di boot e kernel disponibili

**Cosa verificare nell'output:**
- `Firmware: UEFI` (non BIOS legacy)
- `Secure Boot: disabled` (deve essere inizialmente disabilitato)
- `systemd-boot` elencato come boot loader

Se Secure Boot è già abilitato, disabilitalo nelle impostazioni del firmware UEFI prima di procedere.

---

## Panoramica

Entrambi gli approcci seguono questo flusso di lavoro:

1. **Fase A** - Preparare il sistema (systemd-boot + sbctl)
2. **Fase B** - Generare e registrare le chiavi Secure Boot
3. **Fase C** - Abilitare la firma (manuale con sbctl **oppure** automatica con Lanzaboote)
4. **Fase D** - Verificare che tutti i file di boot siano firmati
5. **Fase E** - Abilitare Secure Boot nel firmware

**Differenza chiave**:
- **Metodo manuale**: devi firmare i kernel dopo ogni aggiornamento con `sbctl sign-all`
- **Metodo Lanzaboote**: firma automatica durante `nixos-rebuild`

> **Nota su Lanzaboote**: Lanzaboote sostituisce il modulo NixOS systemd-boot standard con una versione modificata che include la firma automatica. systemd-boot rimane il bootloader effettivo, ma è gestito diversamente per integrare la firma Secure Boot nel processo di build.

---

## Metodo 1: Manuale con sbctl

### Fase A — Preparazione del Sistema

#### 1. Abilitare systemd-boot

Nel tuo `configuration.nix`:

```nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
```

Ricostruisci:

```bash
sudo nixos-rebuild switch
```

#### 2. Installare sbctl

Aggiungi al tuo `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [ sbctl ];
```

Ricostruisci di nuovo:

```bash
sudo nixos-rebuild switch
```

---

### Fase B — Generare e Registrare le Chiavi

#### 1. Creare le chiavi Secure Boot

```bash
sudo sbctl create-keys"
```

Le chiavi vengono archiviate in `/var/lib/sbctl/`.

#### 2. Registrare le chiavi nel firmware

```bash
sudo sbctl enroll-keys --microsoft"
```

> **Informazioni sul flag `--microsoft`**: Questo include i certificati Microsoft nel database delle chiavi. È **necessario** se si utilizza il dual-boot con Windows o se si ha bisogno di avviare hardware con driver firmati da Microsoft (es. alcune schede di rete, schede grafiche). Se si avvia solo NixOS e non si ha tale hardware, si può omettere questo flag, anche se includerlo è generalmente più sicuro per la compatibilità.

> **Attenzione**: Secure Boot rimane **disabilitato** nel firmware in questa fase. Non abilitarlo ancora.

---

### Fase C — Firma Manuale

#### 1. Firmare tutti i file di boot

```bash
sudo sbctl sign-all
```

Questo firma:
- `systemd-bootx64.efi`
- `BOOTX64.EFI`
- Tutti i file `nixos-generation-*.efi`

#### 2. Dopo ogni aggiornamento del sistema

**Importante**: Devi eseguire manualmente questo comando dopo ogni rebuild:

```bash
sudo sbctl sign-all
```

Dimenticare questo passaggio impedirà l'avvio dopo aver abilitato Secure Boot.

---

### Fase D — Verifica (obbligatoria)

```bash
sbctl verify
```

Tutti i file di boot devono risultare **firmati**. Esempio di output:

```
✓ /boot/EFI/systemd/systemd-bootx64.efi is signed
✓ /boot/EFI/BOOT/BOOTX64.EFI is signed
✓ /boot/EFI/nixos/nixos-generation-1.efi is signed
```

---

### Fase E — Abilitare Secure Boot

Solo dopo una verifica riuscita:

1. Riavviare il sistema
2. Entrare nel setup BIOS/UEFI (tipicamente DEL, F2 o F12 durante l'avvio)
3. Abilitare **Secure Boot**
4. Impostare la modalità su **Custom** o **Setup Mode** (se disponibile)
5. Salvare e uscire

Se il sistema non si avvia, disabilitare Secure Boot nel firmware e verificare che tutti i file siano firmati.

---

## Metodo 2: Automatizzato con Lanzaboote

**Lanzaboote** è uno strumento della community che integra la firma Secure Boot nelle ricostruzioni di NixOS, eliminando l'intervento manuale.

### Fase A — Preparazione del Sistema

Come nel Metodo 1 (systemd-boot + sbctl).

---

### Fase B — Generare e Registrare le Chiavi

#### Con nix-shell (se sbctl non è ancora installato)

```bash
sudo nix-shell -p sbctl --run "sbctl create-keys"
sudo nix-shell -p sbctl --run "sbctl enroll-keys --microsoft"
```

#### Con sbctl installato

```bash
sudo sbctl create-keys"
sudo sbctl enroll-keys --microsoft"
```

> **Informazioni sul flag `--microsoft`**: Includilo se utilizzi il dual-boot con Windows o hai hardware che richiede driver firmati da Microsoft. Vedi la Fase B nel Metodo 1 per i dettagli.

> **Attenzione**: Secure Boot rimane **disabilitato** nel firmware.

---

### Fase C — Abilitare Lanzaboote

#### 1. Importare `secure-boot.nix` nella configurazione del tuo host

Nel tuo `configuration.nix` (es. `hosts/ABC/configuration.nix`), aggiungi:

```nix
imports = [
  ./hardware-configuration.nix
  ../secure_boot/secure_boot.nix
];
```

Il file `secure_boot.nix` fornito in questa directory contiene:
- Import di Lanzaboote da `lon.nix`
- Configurazione Lanzaboote con percorso PKI bundle (`/var/lib/sbctl`)
- Disabilitazione forzata del modulo systemd-boot standard
- Pacchetto sbctl per la gestione delle chiavi

È sufficiente importare questo file nel `configuration.nix` del tuo host per abilitare la firma automatica Secure Boot.

#### 2. Ricostruire

```bash
sudo nixos-rebuild switch
```

Lanzaboote firmerà automaticamente tutti i file di boot durante la ricostruzione.

---

### Fase D — Verifica (obbligatoria)

```bash
sbctl verify
```

Deve mostrare tutti i file firmati:

- `systemd-bootx64.efi`
- `BOOTX64.EFI`
- `nixos-generation-*.efi`

---

### Fase E — Abilitare Secure Boot

Stessa procedura del Metodo 1:

1. Riavviare
2. Entrare nel setup BIOS/UEFI
3. Abilitare **Secure Boot**
4. Impostare la modalità su **Custom / Setup Mode**
5. Salvare e uscire

Con Lanzaboote, **non è richiesta firma manuale** dopo gli aggiornamenti futuri.

---

## Confronto

| Aspetto              | Manuale (sbctl) | Lanzaboote |
| -------------------- | --------------- | ---------- |
| systemd-boot         | ✔               | ✔ (modulo modificato) |
| Firma automatica     | ✖               | ✔          |
| Rischio dimenticanze | Alto            | Minimo     |
| Complessità iniziale | Bassa           | Media      |
| Manutenzione         | Manuale         | Automatica |

---

## Fonti & Riferimenti

- **NixOS Manual – Bootloader & Secure Boot**  
  [https://nixos.org/manual/nixos/stable/#sec-boot](https://nixos.org/manual/nixos/stable/#sec-boot)

- **sbctl (Foxboron)**  
  [https://github.com/Foxboron/sbctl](https://github.com/Foxboron/sbctl)

- **Lanzaboote – Getting Started**  
  [https://github.com/nix-community/lanzaboote/blob/master/docs/getting-started/prepare-your-system.md](https://github.com/nix-community/lanzaboote/blob/master/docs/getting-started/prepare-your-system.md)

- **systemd-boot Documentation**  
  [https://www.freedesktop.org/software/systemd/man/systemd-boot.html](https://www.freedesktop.org/software/systemd/man/systemd-boot.html)

---

## Note Importanti

Indipendentemente dal metodo scelto:

- **Non abilitare mai Secure Boot prima della verifica** - eseguire sempre prima `sbctl verify`
- **Mantenere disponibile un metodo di recovery** - accesso BIOS + USB live NixOS
- **Testare accuratamente** prima di distribuire su sistemi di produzione

Questa non è una limitazione di NixOS, ma una proprietà intrinseca di Secure Boot.
