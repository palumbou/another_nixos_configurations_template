# Gestione delle chiavi LUKS (passphrase e chiavette USB)

> **Lingue disponibili**: [English](LUKS_KEYS.md) | [Italiano (corrente)](LUKS_KEYS.it.md)

Questa guida spiega le opzioni LUKS usate dai template Disko di questa cartella e come combinare **più passphrase**, una o più **chiavette USB** e/o il **chip TPM2** (con PIN opzionale) per sbloccare il disco cifrato - registrandoli **già alla formattazione (installazione)** oppure **in un secondo momento, a sistema già installato**.

Tutti e cinque i layout LUKS forniti usano `askPassword = true;` come impostazione predefinita: la passphrase viene chiesta nelle operazioni Disko di creazione/apertura durante l’installazione e poi a ogni boot, salvo configurare esplicitamente USB o TPM2. Nel caso predefinito non devi creare `/tmp/secret.key`. La variante `passwordFile` descritta sotto è opzionale e richiede di rimuovere o disabilitare `askPassword`.

---


Il layout server `btrfs-worker-luks.nix` usa una chiave casuale separata per la swap, che non viene sbloccata con gli slot della partizione LUKS. Nei comandi, sostituisci `/dev/disk/by-id/REPLACE_WITH_LUKS_PARTITION` con la partizione LUKS reale verificata con `lsblk`.

## Come funzionano le chiavi LUKS

Un volume LUKS2 ha fino a **32 keyslot indipendenti**. Ogni slot contiene una chiave (una passphrase o il contenuto di un file-chiave); **ognuno di essi da solo sblocca il disco**, e ogni slot può essere aggiunto o revocato senza toccare gli altri. È questo che rende possibile lo scenario "passphrase + due chiavette USB con chiavi diverse": tre slot, tre vie d'accesso indipendenti. Se perdi una chiavetta, revochi solo il suo slot.

La passphrase iniziale e le chiavi aggiuntive opzionali occupano keyslot indipendenti:

| Slot | Chiave                             | Da dove arriva                                              |
|------|------------------------------------|-------------------------------------------------------------|
| 0    | la tua passphrase                  | `askPassword` predefinito, oppure `passwordFile` opzionale alla formattazione                            |
| 1…n  | chiavi extra (es. chiavette USB)   | `additionalKeyFiles` alla formattazione, o `luksAddKey` dopo |
| 1…n  | TPM2 (chiave custodita dal chip, PIN opzionale) | `systemd-cryptenroll` a sistema avviato |

---

## Riferimento opzioni

### `askPassword` — impostazione interattiva predefinita

Tutti e cinque i layout LUKS forniti impostano `askPassword = true;`. Disko chiede la passphrase per la creazione/apertura del volume durante l’installazione, quindi il caso predefinito non richiede un file della passphrase principale:

```nix
askPassword = true;
```

Senza configurazioni opzionali di boot con chiavetta USB o TPM2, l'initrd chiede quella passphrase a ogni avvio. `askPassword` sceglie il metodo di inserimento per le operazioni Disko; l’initrd installato riceve separatamente il device e `settings` per lo sblocco al boot.

### `passwordFile` — alternativa opzionale

Usala soltanto quando vuoi fornire la passphrase iniziale da un file. Prima di aggiungere `passwordFile`, sostituisci `askPassword = true;` con `askPassword = false;` oppure rimuovi l'impostazione interattiva attiva. Sono alternative: se rimane configurato `askPassword = true;`, questo prevale e `passwordFile` viene ignorato:

```nix
askPassword = false;
passwordFile = "/tmp/secret.key";
```

Disko usa il file per le proprie **operazioni di creazione/apertura del volume durante l’installazione**. Alla creazione, il file fornisce la passphrase iniziale; all’apertura, fornisce la passphrase per sbloccare il volume. L’initrd installato non usa automaticamente questo file: device e `settings` determinano lo sblocco al boot. Il flusso interattivo predefinito non richiede un file della passphrase principale; preparane uno appena prima di Disko soltanto per questa alternativa con file:

```bash
echo -n "latuapassphrase" > /tmp/secret.key
```

L’esempio usa `echo -n` per scrivere una passphrase testuale senza newline finale. La stessa stringa può essere digitata al prompt di boot. Disko non cancella automaticamente il file; rimuovilo volontariamente quando le sue operazioni non ne hanno più bisogno. Un percorso sotto `/tmp` in questi esempi appartiene all’ambiente live dell’installer.

### `settings.*` - comportamento al boot

Tutto ciò che sta dentro `settings` viene inoltrato tale e quale da Disko all'opzione NixOS `boot.initrd.luks.devices.<name>`, cioè configura **come l'initrd sblocca il disco a ogni avvio**:

- **`allowDiscards`** - lascia passare i comandi TRIM/discard del filesystem attraverso lo strato cifrato fino all'SSD. dm-crypt di default li blocca: il rovescio della medaglia di attivarlo è che un attaccante che ispeziona il disco raw può vedere *quanto* spazio è in uso (non il contenuto). Senza, `fstrim` non ha effetto sul volume e le prestazioni dell'SSD degradano nel tempo. Su SSD normalmente lo vuoi a `true` - ed è per questo che i template lo portano già attivo.
- **`keyFile`** - un percorso che l'initrd legge per sbloccare il disco *senza chiedere nulla*. Il percorso deve essere leggibile **dentro l'initrd**, quindi in pratica è un device raw (una chiavetta USB) o un symlink udev che ci punta - non un file su un filesystem.
- **`keyFileSize`** - legge solo i primi N byte di `keyFile` come chiave. Necessario con chiavi su device raw, dove il "file" sarebbe altrimenti l'intera chiavetta.
- **`keyFileOffset`** - inizia a leggere la chiave a un certo offset invece che dall'inizio del device.
- **`keyFileTimeout`** - quanti secondi aspettare che il device-chiave compaia; allo scadere, l'initrd ripiega sul normale prompt della passphrase. È ciò che rende la chiavetta *opzionale* all'avvio. Funziona con l'initrd systemd (`boot.initrd.systemd.enable = true`, vedi `common/config/boot_luks.nix`).
- **`fallbackToPassword`** - stessa idea di fallback per il vecchio initrd a script; con l'initrd systemd usa invece `keyFileTimeout`.

### `additionalKeyFiles`

Una lista di file che Disko registra come **keyslot aggiuntivi subito dopo il `luksFormat`** (un `luksAddKey` per ciascuno, slot 1, 2, … nell'ordine della lista). È così che registri le chiavette USB già in fase di installazione.

---

## Scenari

I mattoni sono `askPassword` (predefinito interattivo) oppure `passwordFile` (alternativa opzionale con file) per la passphrase iniziale, `additionalKeyFiles` (slot extra alla formattazione), `cryptsetup luksAddKey` (slot extra in seguito), `settings.keyFile` (sblocco automatico al boot). Quello che cambia tra gli scenari è come li combini.

### 1. Più passphrase, nessuna chiavetta

Utile per una passphrase di emergenza/riserva (conservata in un password manager o stampata e messa in un posto sicuro), o per due persone che usano la stessa macchina con passphrase diverse. Non serve alcuna opzione NixOS aggiuntiva: il prompt di boot confronta ciò che digiti con **tutti** i keyslot, quindi qualunque passphrase registrata sblocca il disco.

**Alla formattazione, variante opzionale con file** — questo esempio sostituisce il caso interattivo predefinito con `askPassword = false;` e `passwordFile`. Scrivi passphrase iniziale e aggiuntiva in file temporanei e registra la seconda con `additionalKeyFiles`:

```bash
echo -n "latuapassphrase"     > /tmp/secret.key   # slot 0
echo -n "passphrasediriserva" > /tmp/second.key   # slot 1
```

```nix
askPassword = false;
passwordFile = "/tmp/secret.key";
additionalKeyFiles = [ "/tmp/second.key" ];
```

Poiché il file è creato con `echo -n` (niente newline finale), la stessa identica stringa potrà poi essere digitata al prompt di boot.

**A sistema già installato** - tutto interattivo, niente da configurare né rebuild:

```bash
sudo cryptsetup luksAddKey /dev/disk/by-id/REPLACE_WITH_LUKS_PARTITION
```

Chiede una passphrase esistente per autorizzare, poi due volte quella nuova.

### 2. Passphrase + una sola chiavetta USB

Identico allo scenario 3 qui sotto - prepari la chiavetta e la registri (sezione A alla formattazione, sezione B in seguito) - ma il lato NixOS è più semplice: con una sola chiavetta la regola udev è opzionale, perché `keyFile` può puntare direttamente al percorso stabile della chiavetta:

```nix
settings = {
  allowDiscards = true;
  keyFile = "/dev/disk/by-id/usb-CHIAVETTA1-0:0";  # la chiavetta stessa
  keyFileSize = 4096;
  keyFileTimeout = 10;                             # chiavetta assente -> prompt passphrase
};
```

> **Se usi già TPM2 con PIN**
>
> Registrare una chiave USB con `cryptsetup luksAddKey` aggiunge uno slot indipendente e non cambia, da solo, il comportamento all'avvio.
>
> Per ottenere il comportamento di questo esempio, configura `keyFile`, `keyFileSize` e `keyFileTimeout` e rimuovi `tpm2-device=auto` da `crypttabExtraOpts`, conservando eventuali altre opzioni:
>
> - **USB presente e valida:** sblocco automatico, senza PIN.
> - **USB assente o non valida:** richiesta della passphrase LUKS, non del PIN TPM.
>
> Lo slot e il token TPM già registrati non vengono cancellati.
>
> Aggiungere invece `keyFile` mantenendo `tpm2-device=auto` non garantisce la sequenza "USB -> TPM con PIN -> passphrase": systemd può interpretare il file come una chiave sigillata dal TPM.

La regola udev (`/dev/usbkey`) resta una buona idea se prevedi di aggiungere una seconda chiavetta in futuro: basterà aggiungerle una riga.

### 3. Passphrase + due o più chiavette USB

Il setup più semplice e robusto memorizza la chiave nei **primi 4096 byte raw della chiavetta**. Attenzione: scriverli **distrugge tabella delle partizioni e filesystem della chiavetta**, che diventa dedicata a fare da chiave (ai file manager apparirà "vuota/corrotta"). Dai a ogni chiavetta una chiave casuale *diversa*, così ognuna occupa il suo slot e può essere revocata singolarmente.

#### A. Registrare le chiavette alla formattazione

Questa è la variante opzionale con file. Per mantenere il caso interattivo predefinito senza file della passphrase principale, installa normalmente e registra le chiavette in seguito come nella sezione B.

1. Individua le chiavette e scrivi una chiave casuale su ciascuna (si può fare anche prima, su qualunque macchina):

   ```bash
   ls -l /dev/disk/by-id/ | grep usb
   sudo dd if=/dev/urandom of=/dev/disk/by-id/usb-CHIAVETTA1-0:0 bs=4096 count=1
   sudo dd if=/dev/urandom of=/dev/disk/by-id/usb-CHIAVETTA2-0:0 bs=4096 count=1
   ```

2. Per questa variante opzionale con file, crea dall’installer il file della passphrase principale appena prima di Disko e scarica i byte-chiave di ogni chiavetta in un file temporaneo:

   ```bash
   echo -n "latuapassphrase" > /tmp/secret.key
   dd if=/dev/disk/by-id/usb-CHIAVETTA1-0:0 of=/tmp/usbkey1.key bs=4096 count=1
   dd if=/dev/disk/by-id/usb-CHIAVETTA2-0:0 of=/tmp/usbkey2.key bs=4096 count=1
   ```

3. Nella copia dell’host, sostituisci `askPassword = true;` con la configurazione a file seguente; non lasciare attivi entrambi i metodi di inserimento:

   ```nix
   askPassword = false;
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
   sudo cryptsetup luksAddKey /dev/disk/by-id/REPLACE_WITH_LUKS_PARTITION /dev/disk/by-id/usb-CHIAVETTA1-0:0 --new-keyfile-size 4096
   ```

   (`/dev/disk/by-id/REPLACE_WITH_LUKS_PARTITION` è la partizione LUKS - trova la tua con `lsblk -f | grep crypto_LUKS`.)

2. Aggiungi le stesse righe `settings` viste sopra al file Disko del host. Su un host già installato è **sicuro**: `settings` cambia solo la configurazione di boot generata, Disko non riformatta mai nulla al rebuild.

3. Aggiungi la regola udev qui sotto al `configuration.nix`, ricostruisci (`nixos-rebuild switch`) e collauda prima di fidarti (vedi sotto).

#### La regola udev (per entrambi i casi)

`keyFile` accetta un solo percorso, quindi con due chiavette il trucco è una regola udev nell'initrd che dà **a entrambe lo stesso symlink** `/dev/usbkey` - qualunque delle due inserisci, il percorso è valido. Ricava il seriale di ogni chiavetta con `udevadm info /dev/sdX | grep ID_SERIAL_SHORT`, poi:

```nix
boot.initrd.services.udev.rules = ''
  SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_SERIAL_SHORT}=="SERIALE1", SYMLINK+="usbkey"
  SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_SERIAL_SHORT}=="SERIALE2", SYMLINK+="usbkey"
'';
```

Risultato all'avvio: con una chiavetta inserita la macchina si sblocca da sola; senza, dopo `keyFileTimeout` secondi compare il consueto prompt della passphrase.

### 4. TPM2: sblocco automatico, con o senza PIN

Il chip TPM2 sulla scheda madre può custodire una chiave e rilasciarla **solo se lo stato di boot misurato corrisponde a quello atteso** (firmware, Secure Boot…): il disco si sblocca da solo, senza digitare nulla. Requisiti: LUKS2 (questi template lo creano già), l'initrd systemd (`boot.initrd.systemd.enable = true`, vedi `common/config/boot_luks.nix`) e un chip TPM2 - verifica con `systemd-analyze has-tpm2`.

A differenza di passphrase e chiavette USB, il TPM **non si può registrare alla formattazione**. Non è un limite di Disko ma la natura del TPM: la registrazione sigilla la chiave contro i valori PCR del boot *corrente*, e durante l'installazione quelli misurati riflettono l'installer USB - al primo riavvio non combacerebbero e cadresti comunque sulla passphrase. Il flusso completo è:

1. **Formatta e installa normalmente** con il valore interattivo predefinito `askPassword = true;`; non serve un file della passphrase principale.
2. **Primo avvio**, digitando la passphrase.
3. **Registrazione dal sistema avviato** - chiede una passphrase esistente per autorizzare e, con `--tpm2-with-pin=yes`, imposti anche il PIN lì, interattivamente. Occupa un keyslot in più accanto alla passphrase:

   ```bash
   # lega lo sblocco allo stato Secure Boot (PCR 7)
   sudo systemd-cryptenroll /dev/disk/by-id/REPLACE_WITH_LUKS_PARTITION --tpm2-device=auto --tpm2-pcrs=7

   # più robusto: richiede anche un PIN digitato al boot
   sudo systemd-cryptenroll /dev/disk/by-id/REPLACE_WITH_LUKS_PARTITION --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes
   ```

4. **Aggiungi o decommenta la riga seguente dentro `settings` del contenuto LUKS nel file Disko dell’host**, poi ricostruisci (`nixos-rebuild switch`):

   ```nix
   crypttabExtraOpts = [ "tpm2-device=auto" ];
   ```

   Quando importato dall’host, `common/config/boot_luks.nix` abilita lo stack userspace TPM2 (`security.tpm2.enable`) non appena vede un device LUKS con un'opzione `tpm2-*`, così il file Disko resta l'unica fonte di verità. È impostato con `lib.mkDefault`, quindi un host può comunque forzarlo esplicitamente in caso di bisogno.

5. **Dal riavvio successivo** il TPM sblocca il disco (chiedendo il PIN, se registrato con PIN) al posto della passphrase lunga - che resta nel suo keyslot come recovery.

I passi 3 e 4 si possono invertire senza rischi: con `tpm2-device=auto` configurato ma nessuna registrazione fatta, il boot ripiega semplicemente sul prompt della passphrase.

**PIN sì o PIN no?** Senza PIN la macchina si avvia da sola fino alla schermata di login: comodo, ma ci arriva anche un portatile rubato, quindi tutta la protezione si sposta su password utente/lockscreen. Con `--tpm2-with-pin=yes` digiti un breve PIN al boot: mantieni l'anti-manomissione del TPM (la chiave esce solo con un boot misurato sano) **più** un fattore di conoscenza, e il blocco anti-dizionario integrato nel TPM strozza i tentativi di forza bruta. È il compromesso sensato per i portatili.

Nota che il PIN **non richiede alcuna opzione aggiuntiva in `settings`**: il requisito viene scritto nell'header LUKS2 al momento della registrazione (`--tpm2-with-pin=yes`), il PIN stesso lo imposti interattivamente durante quella stessa registrazione, e al boot il prompt del PIN compare da solo (`tpm2-device=auto` è tutta la configurazione necessaria). Per cambiare PIN si ri-registra: `--wipe-slot=tpm2`, poi nuova registrazione.

Note:

- **PCR 7** lega lo sblocco allo stato Secure Boot - si sposa naturalmente con il setup Lanzaboote in `hosts/secure_boot/`. Legare più PCR (es. `--tpm2-pcrs=0+2+7`) è più rigido, ma gli aggiornamenti firmware ti faranno cadere più spesso sulla passphrase di recovery.
- **Tieni sempre la passphrase nel suo keyslot** come recovery: dopo un aggiornamento firmware, un cambio di PCR o un reset del TPM è l'unica via di rientro. Poi ri-registra con `systemd-cryptenroll --wipe-slot=tpm2` seguito da una nuova registrazione.
- `cryptsetup luksDump` mostra il token `tpm2`; `systemd-cryptenroll /dev/... --wipe-slot=tpm2` lo rimuove.

---

## Collaudo e manutenzione

```bash
# prova una chiave senza toccare nulla
sudo cryptsetup open --test-passphrase /dev/disk/by-id/REPLACE_WITH_LUKS_PARTITION --key-file /dev/disk/by-id/usb-CHIAVETTA1-0:0 --keyfile-size 4096 && echo OK

# vedi quali keyslot sono occupati
sudo cryptsetup luksDump /dev/disk/by-id/REPLACE_WITH_LUKS_PARTITION

# persa una chiavetta? revoca solo il suo slot (scopri quale slot è di chi con --test-passphrase --key-slot N)
sudo cryptsetup luksKillSlot /dev/disk/by-id/REPLACE_WITH_LUKS_PARTITION 2

# backup dell'header - da conservare FUORI da questo disco
sudo cryptsetup luksHeaderBackup /dev/disk/by-id/REPLACE_WITH_LUKS_PARTITION --header-backup-file luks-header.img
```

---

## Note di sicurezza

- **Mai** conservare un file-chiave di boot su una partizione non cifrata dello stesso disco (es. `/boot`): è la chiave appoggiata sopra la cassaforte. Solo supporti rimovibili.
- I file-chiave di cryptsetup sono confrontati **byte per byte**: crea le passphrase testuali con `echo -n` e mantieni coerenti la dimensione registrata e il `keyFileSize` di boot (4096 negli esempi).
- I file opzionali `/tmp/*.key` degli esempi di installazione con file appartengono all’ambiente live dell’installer; Disko non cancella automaticamente i file forniti. Rimuovili quando non servono più. Il flusso `askPassword` predefinito non richiede un file della passphrase principale.
