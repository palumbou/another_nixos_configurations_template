# Profili utente

[English](README.md) | [Italiano](README.it.md)

I moduli separano amministrazione, sessione personale client ed esecuzione del lavoro. Scegli nomi, UID e GID distinti prima di usare i file.

| Modulo | Scopo | Importato da |
| --- | --- | --- |
| `ADMIN/admin.nix.template` | Amministratore essenziale, `wheel`, hash condiviso, alias e cronologia globali | Host server e profilo client |
| `ADMIN/client.nix.template` | Importa `admin.nix`; pacchetti CLI/desktop personali, cartelle home, dizionari, percorso sudo e identità Syncthing client | Host client |
| `WORKER/worker.nix.template` | Account normale separato con home privata, hash dell'host, gruppo e cartelle condivisi | Host server |

La struttura finale è `users/<admin>/admin.nix`, `users/<admin>/client.nix` e `users/<worker>/worker.nix`. Mantieni i due file dell'amministratore insieme per risolvere `./admin.nix`. Password, hash e chiavi SSH autorizzate vanno nei file YAML cifrati: vedi [SECRETS.it.md](../common/config/SECRETS.it.md).

## Configurazione manuale

1. Copia la struttura di configurazione. Rinomina `ADMIN` e `WORKER` con gli utenti scelti e rimuovi `.template` dai moduli Nix utilizzati. Sostituisci i segnaposto maiuscoli `${...}` secondo la tabella. Conserva le espressioni Nix come `${lib.makeBinPath [ pkgs.systemd ]}`.
2. Scegli `hosts/client/ABC` o `hosts/server/ABC`, rinomina `ABC` con l'hostname e compila i segnaposto host. Il client importa `../../../users/<admin>/client.nix`; il server importa `../../../users/<admin>/admin.nix` e `../../../users/<worker>/worker.nix`.
3. Configura e cifra `secrets/common.yaml` e `secrets/<hostname>.yaml`, poi configura i template runtime delle chiavi SSH. Ogni host importa `common/config/secrets.nix` e sceglie `sops.defaultSopsFile = ../../../secrets/<hostname>.yaml`.
4. Controlla il risultato e valuta/compila l'host NixOS scelto prima dell'attivazione.

| Segnaposto | Esempio generico / significato |
| --- | --- |
| `ADMIN_USER`, `ADMIN_UID`, `ADMIN_GID` | `admin`, `1000`, `1000` |
| `WORKER_USER`, `WORKER_UID`, `WORKER_GID` | `worker`, `1001`, `1001` |
| `WORK_GROUP`, `WORK_GID` | `work-data`, `1100`; distinti dai due gruppi privati |
| `WORK_ROOT` | `/srv/worker`; percorso assoluto senza spazi |
| `DICTIONARY` | `it_IT`; attributo di `pkgs.hunspellDicts`; viene installato anche `en_US` |
| `BASEPATHUSER` | Solo per la regola dotfiles facoltativa: directory assoluta che contiene `nixos_configs` |

Il modulo worker verifica che nomi/UID dei due account e nomi/GID dei tre gruppi siano distinti. Usa ID positivi senza collisioni con utenti o gruppi di servizio esistenti. I campi numerici sono interi Nix, senza virgolette.

L'amministratore essenziale non installa applicazioni personali. Il client installa i suoi pacchetti anche senza desktop grafico: adatta la lista alla macchina. La base dei pacchetti client abilita i pacchetti non liberi per il profilo. `zz`, dizionari e `secure_path` di sudo appartengono al client. `secure_path` regola la ricerca dei comandi, non quelli autorizzati. I gruppi client `audio`, `input` e `video` sono sempre presenti. I gruppi Docker, NetworkManager, libvirt, QEMU non root e I²C dipendono dalle funzioni abilitate. Il client mantiene esplicitamente `users.mutableUsers = true`; il profilo essenziale lascia la scelta all'host.

## Dati worker

Il worker non appartiene a `wheel`, Docker o libvirt. Ha gruppo primario privato e home `0700`. `WORK_GROUP` comprende amministratore e worker, più l'identità Syncthing soltanto quando è attivo il servizio di sistema.

`WORK_ROOT` è un contenitore di root con permessi `2750`. `WORK_ROOT/data` e le sottocartelle `workspaces`, `documents` e `results` appartengono al worker/gruppo condiviso con permessi `2770`. Setgid conserva il gruppo nei nuovi elementi. Le ACL predefinite danno accesso a proprietario/gruppo ed escludono gli altri. Modalità esplicite come `0600` possono comunque restringere l'accesso. Le regole non correggono ricorsivamente i file esistenti. Mantieni snapshot/backup del contenitore separati dalla sincronizzazione di `data`.

## Syncthing per host

Il modulo host configura la sincronizzazione; il modulo utente client ne definisce l'identità. I server usano l'account dedicato `syncthing` con stato in `/var/lib/syncthing`. I client usano l'amministratore, configurazione in `/home/<admin>/.config/syncthing` e radice dati `/home/<admin>/Sync`.

| Segnaposto | Significato |
| --- | --- |
| `ENABLE_SYNCTHING` | Booleano Nix `true` o `false` |
| `SYNCTHING_DEVICE_ID` | ID remoto; vuoto avvia il servizio locale senza peer né cartella condivisa |
| `SYNCTHING_ADDRESS` | Indirizzo esplicito, es. `tcp4://storage.example.invalid:22222` |
| `SYNCTHING_FOLDER_ID` | Uguale sui due peer, es. `work-data` |
| `SYNCTHING_FOLDER_PATH` | Predefinito server `/srv/worker/data`; client `/home/admin/Sync/work-data` |

Un peer configurato condivide una sola cartella `sendreceive` con `ignorePerms = false`: modifiche, cancellazioni e permessi Unix si propagano. Sono escluse le comuni directory di dipendenze/cache. Sul server mantieni `WORK_ROOT/data` per usare le ACL worker; un altro percorso richiede permessi configurati separatamente.

La GUI usa HTTPS su `127.0.0.1:8843`. Discovery globale/locale, NAT traversal e relay sono disabilitati. Nessuna porta firewall viene aperta automaticamente. Se i peer devono iniziare connessioni in ingresso, aggiungi una regola TCP esplicita e limitata per la porta `22222`. Un tunnel come `ssh -L 8843:127.0.0.1:8843 admin@host.example.invalid` permette l'accesso alla GUI su `https://127.0.0.1:8843`; verifica il certificato locale. Dispositivi/cartelle sono dichiarativi: le voci non dichiarate vengono rimosse al riavvio. La sincronizzazione non sostituisce i backup.

## Dotfiles facoltativi

Il client contiene un esempio tmpfiles `C+` commentato. Crea `users/<admin>/dotfiles`, poi decommenta la regola dentro `systemd.tmpfiles.rules`. La sorgente è `${BASEPATHUSER}/nixos_configs/users/<admin>/dotfiles`. Controlla il comportamento della copia systemd prima di abilitarla su una home esistente, oppure usa uno strumento dedicato.
