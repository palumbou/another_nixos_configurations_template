# Cartella Users

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

La cartella **`users`** contiene configurazioni utente che possono essere incluse nel file `configuration.nix` dell’host scelto.  Per **ogni utente**, crea una sottocartella con il nome dell’utente. Al suo interno, includi:

- **`<USERNAME>.nix`** – Il file di configurazione dell’utente  
- **`dotfiles`** (opzionale) – Una cartella contenente eventuali dotfiles da copiare nella `~/.config/` dell’utente

## Struttura della cartella

```bash
users/
└── XYZ/
    ├── dotfiles/
    └── user.nix
```

La cartella **`XYZ`** è un esempio. Copiala, rinominala in base al nuovo nome utente e adatta le configurazioni alle tue esigenze.

---

## File `user.nix`

Questo file definisce un **utente Linux di base** con:

- Un **password hash** generato eseguendo `mkpasswd -m sha-512`  
- Un gruppo principale corrispondente al nome utente  
- Un ID utente (UID) e un ID gruppo (GID) impostati a **1000**  
- Una home directory in `"/home/<USERNAME>"`, che conterrà sottocartelle come `Documents`, `Download`, `Images` e `Videos`  
- Appartenenza al gruppo **`wheel`** per privilegi di amministratore  
- Alcuni **alias di shell** configurati
- **Restrizioni di sicurezza** che specificano quali comandi possono essere eseguiti con **`sudo`**

> **ATTENZIONE**: se prevedi di creare più utenti, **ogni utente deve avere UID e GID unici**.  
> Assicurati di modificare i valori di UID/GID predefiniti per evitare conflitti.

Inoltre:

- **Software desktop più comuni** può essere installato automaticamente (ogni pacchetto ha un commento esplicativo).  
- I **dotfiles** possono essere copiati nella cartella `~/.config` dell’utente (leggi [Cartella dotfiles](#dotfiles-folder) qui sotto).
- Se utilizzi **Syncthing**, puoi decommentare due righe per eseguire Syncthing come questo utente (con lo stesso UID e GID).  
- Se installi **Virtual Machine Manager**, puoi aggiungere l’utente al suo gruppo per gestire le macchine virtuali.

Per la **creazione della cartella home**, utilizziamo **tmpfiles** (un componente di systemd) per creare directory persistenti. Anche se tmpfiles è spesso usato per file e cartelle temporanee, è possibile specificare una modalità “persistente” impostando l’argomento `age` a “-”.

Per maggiori informazioni su **tmpfiles**, vedi:  
- [https://www.freedesktop.org/software/systemd/man/latest/tmpfiles.d.html](https://www.freedesktop.org/software/systemd/man/latest/tmpfiles-setup.service.html](https://www.freedesktop.org/software/systemd/man/latest/systemd-tmpfiles-setup.service.html)

> **Nota**: nel file `user.nix`, assicurati di cambiare le variabili:
> - `${USER}` con il nome effettivo dell’utente  
> - `${DICTIONARY}` con il dizionario scelto (ad es. `en-US`)  
> - `${BASEPATHUSER}` con il percorso assoluto della **cartella padre** di `nixos_configs`

---

## Cartella `dotfiles`

La cartella **`dotfiles`** è **opzionale** e serve per copiare i tuoi dotfiles personali nella directory `~/.config` dell’utente durante la build.  
Anche questa copia è gestita tramite **tmpfiles**.

- Di default, utilizziamo il tipo **“C+”**, che copia ricorsivamente file o directory solo se la destinazione non esiste già o è vuota. Se in seguito i dotfiles fossero modificati nella cartella home (anziché in `nixos_configs`), potrebbero essere sovrascritti durante la ricostruzione.

Per evitare di sovrascrivere modifiche locali, puoi:  
1. **Aggiornare anche i dotfiles** nella cartella di origine `nixos_configs`, oppure  
2. **Cambiare l’azione di tmpfiles** da `“C+”` a `“L”` per creare un symlink da `nixos_configs/users/<USER>/dotfiles/` a `/home/<USER>/.config`, oppure  
3. **Usare uno strumento come GNU Stow** per gestire i dotfiles.