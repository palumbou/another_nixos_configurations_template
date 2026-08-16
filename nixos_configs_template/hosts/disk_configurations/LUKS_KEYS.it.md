# Gestione delle chiavi LUKS (passphrase e chiavette USB)

> **Lingue disponibili**: [English](LUKS_KEYS.md) | [Italiano (corrente)](LUKS_KEYS.it.md)

Questa guida spiega le opzioni LUKS usate dai template Disko di questa cartella e come combinare **più passphrase** e/o una o più **chiavette USB** per sbloccare il disco cifrato — registrandole **già alla formattazione (installazione)** oppure **in un secondo momento, a sistema già installato**.

---

## Come funzionano le chiavi LUKS

Un volume LUKS2 ha fino a **32 keyslot indipendenti**. Ogni slot contiene una chiave (una passphrase o il contenuto di un file-chiave); **ognuno di essi da solo sblocca il disco**, e ogni slot può essere aggiunto o revocato senza toccare gli altri. È questo che rende possibile lo scenario "passphrase + due chiavette USB con chiavi diverse": tre slot, tre vie d'accesso indipendenti. Se perdi una chiavetta, revochi solo il suo slot.

Con i template di questa cartella la disposizione degli slot è deterministica:

| Slot | Chiave                             | Da dove arriva                                              |
|------|------------------------------------|-------------------------------------------------------------|
| 0    | la tua passphrase                  | `passwordFile` alla formattazione                            |
| 1…n  | chiavi extra (es. chiavette USB)   | `additionalKeyFiles` alla formattazione, o `luksAddKey` dopo |

---

## Riferimento opzioni

### `passwordFile`

Usato **solo durante la formattazione**: quando Disko esegue `cryptsetup luksFormat`, il contenuto di questo file diventa la passphrase registrata nel keyslot 0. Dopo l'installazione il file non esiste più e non serve — a ogni avvio digiterai quella passphrase al prompt. Va creato appena prima di lanciare Disko:

```bash
echo -n "latuapassphrase" > /tmp/secret.key
```

`echo -n` è importante: cryptsetup confronta i **byte esatti**, e un newline finale diventerebbe parte della passphrase. Sull'installer NixOS `/tmp` vive in RAM, quindi il file sparisce al riavvio.

### `settings.*` — comportamento al boot

Tutto ciò che sta dentro `settings` viene inoltrato tale e quale da Disko all'opzione NixOS `boot.initrd.luks.devices.<name>`, cioè configura **come l'initrd sblocca il disco a ogni avvio**:

- **`allowDiscards`** — lascia passare i comandi TRIM/discard del filesystem attraverso lo strato cifrato fino all'SSD. dm-crypt di default li blocca: il rovescio della medaglia di attivarlo è che un attaccante che ispeziona il disco raw può vedere *quanto* spazio è in uso (non il contenuto). Senza, `fstrim` non ha effetto sul volume e le prestazioni dell'SSD degradano nel tempo. Su SSD normalmente lo vuoi a `true` — ed è per questo che i template lo portano già attivo.
- **`keyFile`** — un percorso che l'initrd legge per sbloccare il disco *senza chiedere nulla*. Il percorso deve essere leggibile **dentro l'initrd**, quindi in pratica è un device raw (una chiavetta USB) o un symlink udev che ci punta — non un file su un filesystem.
- **`keyFileSize`** — legge solo i primi N byte di `keyFile` come chiave. Necessario con chiavi su device raw, dove il "file" sarebbe altrimenti l'intera chiavetta.
- **`keyFileOffset`** — inizia a leggere la chiave a un certo offset invece che dall'inizio del device.
- **`keyFileTimeout`** — quanti secondi aspettare che il device-chiave compaia; allo scadere, l'initrd ripiega sul normale prompt della passphrase. È ciò che rende la chiavetta *opzionale* all'avvio. Funziona con l'initrd systemd (`boot.initrd.systemd.enable = true`, vedi `common/config/boot_luks.nix`).
- **`fallbackToPassword`** — stessa idea di fallback per il vecchio initrd a script; con l'initrd systemd usa invece `keyFileTimeout`.

### `additionalKeyFiles`

Una lista di file che Disko registra come **keyslot aggiuntivi subito dopo il `luksFormat`** (un `luksAddKey` per ciascuno, slot 1, 2, … nell'ordine della lista). È così che registri le chiavette USB già in fase di installazione.

---

## Scenari

I mattoni sono sempre gli stessi — `passwordFile` (slot 0), `additionalKeyFiles` (slot extra alla formattazione), `cryptsetup luksAddKey` (slot extra in seguito), `settings.keyFile` (sblocco automatico al boot). Quello che cambia tra gli scenari è come li combini.

### 1. Più passphrase, nessuna chiavetta

Utile per una passphrase di emergenza/riserva (conservata in un password manager o stampata e messa in un posto sicuro), o per due persone che usano la stessa macchina con passphrase diverse. Non serve alcuna opzione NixOS aggiuntiva: il prompt di boot confronta ciò che digiti con **tutti** i keyslot, quindi qualunque passphrase registrata sblocca il disco.

**Alla formattazione** — scrivi la passphrase aggiuntiva in un file e registrala con `additionalKeyFiles`:

```bash
echo -n "latuapassphrase"     > /tmp/secret.key   # slot 0
echo -n "passphrasediriserva" > /tmp/second.key   # slot 1
```

```nix
passwordFile = "/tmp/secret.key";
additionalKeyFiles = [ "/tmp/second.key" ];
```

Poiché il file è creato con `echo -n` (niente newline finale), la stessa identica stringa potrà poi essere digitata al prompt di boot.

**A sistema già installato** — tutto interattivo, niente da configurare né rebuild:

```bash
sudo cryptsetup luksAddKey /dev/nvme0n1p2
```

Chiede una passphrase esistente per autorizzare, poi due volte quella nuova.

### 2. Passphrase + una sola chiavetta USB

Identico allo scenario 3 qui sotto — prepari la chiavetta e la registri (sezione A alla formattazione, sezione B in seguito) — ma il lato NixOS è più semplice: con una sola chiavetta la regola udev è opzionale, perché `keyFile` può puntare direttamente al percorso stabile della chiavetta:

```nix
settings = {
  allowDiscards = true;
  keyFile = "/dev/disk/by-id/usb-CHIAVETTA1-0:0";  # la chiavetta stessa
  keyFileSize = 4096;
  keyFileTimeout = 10;                             # chiavetta assente → prompt passphrase
};
```

La regola udev (`/dev/usbkey`) resta una buona idea se prevedi di aggiungere una seconda chiavetta in futuro: basterà aggiungerle una riga.

### 3. Passphrase + due o più chiavette USB

Il setup più semplice e robusto memorizza la chiave nei **primi 4096 byte raw della chiavetta**. Attenzione: scriverli **distrugge tabella delle partizioni e filesystem della chiavetta**, che diventa dedicata a fare da chiave (ai file manager apparirà "vuota/corrotta"). Dai a ogni chiavetta una chiave casuale *diversa*, così ognuna occupa il suo slot e può essere revocata singolarmente.

#### A. Registrare le chiavette alla formattazione

1. Individua le chiavette e scrivi una chiave casuale su ciascuna (si può fare anche prima, su qualunque macchina):

   ```bash
   ls -l /dev/disk/by-id/ | grep usb
   sudo dd if=/dev/urandom of=/dev/disk/by-id/usb-CHIAVETTA1-0:0 bs=4096 count=1
   sudo dd if=/dev/urandom of=/dev/disk/by-id/usb-CHIAVETTA2-0:0 bs=4096 count=1
   ```

2. Dall'installer, appena prima di lanciare Disko, crea il file della passphrase e scarica i byte-chiave di ogni chiavetta in un file temporaneo:

   ```bash
   echo -n "latuapassphrase" > /tmp/secret.key
   dd if=/dev/disk/by-id/usb-CHIAVETTA1-0:0 of=/tmp/usbkey1.key bs=4096 count=1
   dd if=/dev/disk/by-id/usb-CHIAVETTA2-0:0 of=/tmp/usbkey2.key bs=4096 count=1
   ```

3. Nella copia del template del tuo host, decommenta/imposta:

   ```nix
   passwordFile = "/tmp/secret.key";
   additionalKeyFiles = [ "/tmp/usbkey1.key" "/tmp/usbkey2.key" ];
   settings = {
     allowDiscards = true;
     keyFile = "/dev/usbkey";
     keyFileSize = 4096;
     keyFileTimeout = 10;
   };
   ```

4. Aggiungi la regola udev qui sotto al `configuration.nix` del host, poi lancia Disko e installa normalmente. Il disco nasce già con tutti e tre gli slot, e il primo avvio è già sbloccabile con una chiavetta o con la passphrase.

#### B. Registrare le chiavette a sistema già installato

1. Scrivi una chiave casuale sulla chiavetta, poi registrala (chiede la passphrase attuale per autorizzare):

   ```bash
   sudo dd if=/dev/urandom of=/dev/disk/by-id/usb-CHIAVETTA1-0:0 bs=4096 count=1
   sudo cryptsetup luksAddKey /dev/nvme0n1p2 /dev/disk/by-id/usb-CHIAVETTA1-0:0 --new-keyfile-size 4096
   ```

   (`/dev/nvme0n1p2` è la partizione LUKS — trova la tua con `lsblk -f | grep crypto_LUKS`.)

2. Aggiungi le stesse righe `settings` viste sopra al file Disko del host. Su un host già installato è **sicuro**: `settings` cambia solo la configurazione di boot generata, Disko non riformatta mai nulla al rebuild.

3. Aggiungi la regola udev qui sotto al `configuration.nix`, ricostruisci (`nixos-rebuild switch`) e collauda prima di fidarti (vedi sotto).

#### La regola udev (per entrambi i casi)

`keyFile` accetta un solo percorso, quindi con due chiavette il trucco è una regola udev nell'initrd che dà **a entrambe lo stesso symlink** `/dev/usbkey` — qualunque delle due inserisci, il percorso è valido. Ricava il seriale di ogni chiavetta con `udevadm info /dev/sdX | grep ID_SERIAL_SHORT`, poi:

```nix
boot.initrd.services.udev.rules = ''
  SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_SERIAL_SHORT}=="SERIALE1", SYMLINK+="usbkey"
  SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_SERIAL_SHORT}=="SERIALE2", SYMLINK+="usbkey"
'';
```

Risultato all'avvio: con una chiavetta inserita la macchina si sblocca da sola; senza, dopo `keyFileTimeout` secondi compare il consueto prompt della passphrase.

---

## Collaudo e manutenzione

```bash
# prova una chiave senza toccare nulla
sudo cryptsetup open --test-passphrase /dev/nvme0n1p2 --key-file /dev/disk/by-id/usb-CHIAVETTA1-0:0 --keyfile-size 4096 && echo OK

# vedi quali keyslot sono occupati
sudo cryptsetup luksDump /dev/nvme0n1p2

# persa una chiavetta? revoca solo il suo slot (scopri quale slot è di chi con --test-passphrase --key-slot N)
sudo cryptsetup luksKillSlot /dev/nvme0n1p2 2

# backup dell'header — da conservare FUORI da questo disco
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p2 --header-backup-file luks-header.img
```

---

## Note di sicurezza

- **Mai** conservare un file-chiave di boot su una partizione non cifrata dello stesso disco (es. `/boot`): è la chiave appoggiata sopra la cassaforte. Solo supporti rimovibili.
- I file-chiave di cryptsetup sono confrontati **byte per byte**: crea le passphrase testuali con `echo -n` e mantieni coerenti la dimensione registrata e il `keyFileSize` di boot (4096 negli esempi).
- I file `/tmp/*.key` usati durante l'installazione vivono nella RAM dell'installer e spariscono al riavvio.
