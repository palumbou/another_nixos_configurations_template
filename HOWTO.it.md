# Guida

> **Lingue disponibili**: [English](HOWTO.md) | [Italiano (corrente)](HOWTO.it.md)

## Guida all'utilizzo dei file di configurazione

Puoi usare questi file di configurazione in due modi:

- **Build dopo l'installazione**
- **Installazione diretta** di NixOS con i tuoi file di configurazione personalizzati

Esploriamo entrambi i metodi.

---

## Build dopo l'installazione

È possibile effettuare prima un'installazione grafica e, dopo il primo avvio, ricompilare il sistema con i propri file di configurazione.

Ricapitolando, dovresti:

1. **Installare NixOS** normalmente.
2. **Modificare** i file di configurazione secondo le tue esigenze.
3. **Compilare** quei file sul tuo host NixOS.

### Installazione di NixOS

Scarica la ISO desiderata (Gnome o KDE-Plasma) dalla [pagina ufficiale del progetto NixOS](https://nixos.org/download/) nella sezione "NixOS: the Linux distribution". Avvia questa ISO sulla tua macchina host.

Durante l'installazione:

- **Partizionamento del disco**  
  Dopo l'installazione, verrà generato un file di configurazione in `/etc/nixos/configuration.nix`. Al suo interno troverai una riga che specifica il dispositivo GRUB, ad esempio:

  ```nix
  boot.loader.grub.device = "/dev/disk/by-id/wwn-0x500001234567890a";
  ```
  
  **Salva** questo valore (`/dev/disk/by-id/...`) per utilizzarlo successivamente nella tua configurazione personalizzata.

- **Utente**  
  Scegli lo stesso nome utente che intendi utilizzare nei file di configurazione oppure copia la configurazione di un utente esistente generato dall'installer.

> **Importante:** queste impostazioni verranno sovrascritte dalla tua configurazione personalizzata dopo la prima build, quindi presta molta attenzione al partizionamento del disco e alla denominazione degli utenti.

### Modifica dei file di configurazione

Puoi utilizzare questi file in due modi:

> **Nota:** prima di modificare qualsiasi file di configurazione, **leggi il file `env.conf`**.
> Contiene variabili di ambiente e riferimenti ai file dove vengono utilizzate.
> Sentiti libero di modificare `env.conf` secondo le tue necessità, sia che tu copi i file manualmente o utilizzi lo script fornito.

1. **Copia manuale**
   - Copia la cartella `nixos_configs_template`.
   - Rimuovi il suffisso `template` da ogni estensione del file (cambiando `.nix.template` in `.nix`).
   - Sostituisci le variabili elencate in `env.conf` con i valori specifici della tua configurazione.

2. **Utilizzo dello script**
   - Esegui lo script `nixos_configs_generator.sh` (vedi il [repository nixos_configurations_generator](https://github.com/palumbou/nixos_configurations_generator)) per automatizzare i passaggi descritti sopra.

### Compilazione

Quando sei pronto per **compilare** la configurazione, esegui:

```bash
nixos-rebuild switch -I nixos-config=PERCORSO_CARTELLA_CONF_NIXOS/configuration.nix
```

Sostituisci `PERCORSO_CARTELLA_CONF_NIXOS` con il percorso assoluto o relativo del tuo `configuration.nix`.

> **Suggerimento:** per ottenere maggiori dettagli durante il processo di build, aggiungi l'opzione `--show-trace`:
> ```bash
> nixos-rebuild switch -I nixos-config=./configuration.nix --show-trace
> ```

---

## Installazione diretta

Grazie al modulo Disko, è possibile effettuare direttamente l'installazione di NixOS partendo dalla formattazione del disco.

Fai riferimento al [README Disko](./nixos_configs_template/hosts/disk_configurations/README.md) [sezione Usage](./nixos_configs_template/hosts/disk_configurations/README.md#usage) per i dettagli iniziali. Qui ci concentriamo sull'uso dei file personalizzati generati dalla cartella "nixos_configs".

Seguendo le istruzioni nella sezione [Modifica dei file di configurazione](#modifica-dei-file-di-configurazione), personalizza e salva la tua copia su una penna USB, disco condiviso in rete, repository Git privato, o altro storage.

Fai particolare attenzione ai percorsi dei file che copierai, specialmente le configurazioni di Network Manager (`nm_configurations.nix` nella cartella host) e i dotfiles utenti (nella cartella `users`). Le variabili rilevanti sono `BASEPATHNM` e `BASEPATHUSER`, entrambe definite come `/home` nel file `env.conf`.

### Perché `/home`?

Per ragioni di sicurezza, la cartella "nixos_config" dovrebbe trovarsi sotto `/home` con proprietà root, così solo gli amministratori possono modificare o utilizzare questi file (il rebuild richiede privilegi amministrativi). Durante l'installazione, dopo la formattazione, il disco verrà montato sotto `/mnt`. Potrai quindi creare la directory `/home` (se non già partizionata) e copiare la cartella "nixos_config" lì, preservandola post-installazione.

### Passaggi dell'installazione

Assumendo che la cartella "nixos_config" modificata e personalizzata sia pronta:

1. **Avvia la ISO ufficiale** scaricata dalla [pagina ufficiale di NixOS](https://nixos.org/download/) sulla tua macchina.

2. Copia la cartella "nixos_config" in `/home/nixos`:
   ```bash
   /home/nixos/nixos_config
   ```

3. Formatta il disco con il template scelto, nella cartella host:
   ```bash
   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount /home/nixos/nixos_config/hosts/ABC/single-disk-ext4-bios.nix
   ```

4. Dopo la formattazione, il disco sarà montato sotto `/mnt`. Crea `/home` e copia la configurazione:
   ```bash
   sudo mkdir -p /mnt/home && sudo cp -r /home/nixos/nixos_config /mnt/home/
   ```

5. *(Opzionale)* Genera `hardware-configuration.nix` se necessario e copialo nella cartella host:
   ```bash
   sudo nixos-generate-config --no-filesystems --root /mnt && sudo cp /mnt/etc/nixos/hardware-configuration.nix /mnt/home/nixos_config/hosts/ABC/
   ```

6. Procedi con l'installazione:
   ```bash
   sudo NIXOS_CONFIG=/mnt/home/nixos_config/hosts/ABC/configuration.nix nixos-install
   ```

7. Riavvia il sistema:
   ```bash
   reboot
   ```

Se tutti i comandi hanno avuto successo, al riavvio avrai il tuo ambiente già configurato.