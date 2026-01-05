# Cartella Hosts

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

La cartella **`hosts`** contiene le configurazioni per ognuna delle tue macchine (host). Ogni host risiede nella propria sottocartella denominata come quell'host. Questa cartella include anche:

- **`disk_configurations/`** - Template Disko per il partizionamento dichiarativo del disco e la configurazione del filesystem
- **`secure_boot/`** - File di configurazione Secure Boot utilizzando Lanzaboote per la firma automatica
- Cartelle di singoli host (ad esempio, **`ABC/`**) contenenti file di configurazione specifici per l'host

Ogni cartella host include tipicamente:

- **`configuration.nix`** - File di configurazione di base con import per GUI, pacchetti, utenti e funzionalità opzionali
- **`hardware-configuration.nix`** - Configurazione specifica dell'hardware generata durante l'installazione
- **`nm_configurations.nix`** (opzionale) - File di connessione NetworkManager da importare durante la build

## Struttura della cartella

```bash
hosts/
├── ABC/                          # Cartella host di esempio
│   ├── configuration.nix
│   ├── hardware-configuration.nix
│   └── nm_configurations.nix
├── disk_configurations/          # Template Disko per configurazione disco
│   ├── btrfs/
│   └── ext4/
└── secure_boot/                  # Secure Boot con Lanzaboote
    ├── lon.nix
    └── secure_boot.nix
```

La cartella **`ABC`** è un esempio. Copiala, rinominala per farla corrispondere al tuo hostname effettivo, e poi modifica i suoi file secondo necessità.

---

## Opzionale: Configurazione Secure Boot

La cartella **`secure_boot`** fornisce file di configurazione per abilitare Secure Boot sul tuo sistema NixOS utilizzando **Lanzaboote**, uno strumento della community che automatizza la firma dei file di boot.

**Cos'è Secure Boot?**  
Secure Boot è una funzionalità del firmware UEFI che garantisce che solo bootloader e kernel firmati crittograficamente possano essere eseguiti, proteggendo da malware a livello di boot e modifiche non autorizzate.

**Perché usare Lanzaboote?**  
Lanzaboote integra la firma Secure Boot direttamente nel processo di rebuild di NixOS, eliminando la necessità di firmare manualmente i file di boot dopo ogni aggiornamento del sistema.

**Come abilitare:**  
1. Segui le istruzioni dettagliate in [`secure_boot/README.it.md`](secure_boot/README.it.md)
2. Decommenta la riga `#../secure_boot/secure_boot.nix` nel `configuration.nix` del tuo host
3. Completa i passaggi di generazione e registrazione delle chiavi descritti nel README
4. Abilita Secure Boot nel firmware UEFI dopo la verifica

---

## Opzionale: Configurazione Disco con Disko

La cartella **`disk_configurations`** contiene template per il partizionamento dichiarativo del disco usando Disko. Consulta [`disk_configurations/README.it.md`](disk_configurations/README.it.md) per informazioni dettagliate sui template disponibili (Btrfs, ext4, crittografia LUKS, ecc.) e istruzioni d'uso.

---

## File `configuration.nix`

1. **Decommenta gli import** di cui hai bisogno. Ad esempio, scegli solo un'interfaccia grafica (`gnome.nix`, `hyprland.nix` o `kde.nix`). Decommenta i pacchetti/servizi rilevanti da `../../common/packages/`.

2. **Funzionalità opzionali**: Decommenta `../secure_boot/secure_boot.nix` per il supporto Secure Boot, o `../disk_configurations/...` se usi Disko per la gestione del disco.

3. **Configurazione utente**: Indica la configurazione utente corretta, ad esempio `../../users/XYZ/user.nix`.

4. **Imposta il dispositivo del bootloader** sostituendo `/dev/disk/by-id/wwn-0x500001234567890a` con l'identificatore effettivo del tuo disco:
    
        boot.loader.grub.enable = true;
        boot.loader.grub.device = "/dev/disk/by-id/wwn-0x500001234567890a";
        boot.loader.grub.useOSProber = false;

   Puoi trovarlo:
   - Installando NixOS e copiandolo da `/etc/nixos/configuration.nix`, oppure  
   - Eseguendo `nixos-generate-config` sulla tua macchina.

5. **Imposta l'hostname**:
    
        networking.hostName = "nixos"; # Sostituisci con il tuo hostname

6. **Abilita le cartelle Syncthing selezionate** specificate per l'host (opzionale).

    Se utilizzi Syncthing per sincronizzare cartelle tra i tuoi computer, puoi usare questa opzione per abilitare la sincronizzazione di cartelle specifiche durante la build del sistema.

    Sostituisci "NAME FOLDER" con il nome della cartella che vuoi sincronizzare.

        services.syncthing.settings.folders.NAME FOLDER.enable = true;

  - **Usa un'opzione per cartella:** aggiungi più righe per tutte le cartelle che vuoi abilitare.
  - **Nota:** le configurazioni delle cartelle corrispondenti devono essere specificate nel file di configurazione Syncthing (`../../common/packages/syncthing.nix`).

---

## File `hardware-configuration.nix`

Questo file contiene le impostazioni specifiche dell'hardware per l'host.  
Puoi ottenerlo:

- Installando NixOS da una [ISO ufficiale](https://nixos.org/download) e copiando `/etc/nixos/hardware-configuration.nix`.
- Eseguendo `nixos-generate-config` sull'host di destinazione.
- Importandolo da [nixos-hardware](https://github.com/NixOS/nixos-hardware), se esiste un profilo corrispondente.

---

## File `nm_configurations.nix` (Opzionale)

Se hai bisogno di importare file `.nmconnection` in fase di build (ad esempio, impostazioni WiFi o VPN):

1. Inserisci quei file in `nixos_configs/common/network/nmconnection_files/`.
2. Decommenta la riga `./nm_configurations.nix` nel tuo `configuration.nix`.
3. In `nm_configurations.nix`, fai riferimento ai file con il percorso assoluto corretto. Ad esempio:

        {
          environment.etc."NetworkManager/system-connections/HomeWiFi.nmconnection" = {
            source = "${BASEPATHNM}/nixos_configs/common/network/nmconnection_files/HomeWiFi.nmconnection";
            mode = "0600";
            user = "root";
            group = "root";
          };
        }

Sostituisci `${BASEPATHNM}` con il percorso effettivo a `nixos_configs` e `HomeWiFi.nmconnection` con il nome del tuo file.  
Se un file viene dichiarato ma non trovato, vedrai un avviso durante la build, ma non ci sarà un errore bloccante.

> **Nota**: puoi anche gestire il WiFi tramite [`networking.wireless.networks`](https://search.nixos.org/options?channel=25.11&from=0&size=50&sort=relevance&type=packages&query=networking.wireless.networks.), ma questo approccio abilita `wpa_supplicant` e disabilita il controllo WiFi in NetworkManager.

---

## Riepilogo

1. **Copia la cartella `ABC`**, rinominala con il nome del tuo host.  
2. **Modifica** `configuration.nix`, `hardware-configuration.nix` ed eventualmente `nm_configurations.nix`.  
3. **Decommenta** ciò di cui hai bisogno e imposta gli identificatori corretti (dispositivo del bootloader, hostname, ecc.).

A questo punto, `hosts/ABC` dovrebbe essere pronto per le build di NixOS.
