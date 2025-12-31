# Guida all'Aggiornamento di NixOS

> **Lingue disponibili**: [English](UPGRADE_SYSTEM.md) | [Italiano (corrente)](UPGRADE_SYSTEM.it.md)

Questa guida spiega come aggiornare il tuo sistema NixOS a una versione più recente, sia per aggiornamenti minori che maggiori.

---

## Indice

- [Comprendere le Versioni di NixOS](#comprendere-le-versioni-di-nixos)
- [Comprendere stateVersion](#comprendere-stateversion)
- [Prima di Aggiornare](#prima-di-aggiornare)
- [Aggiornamento Versione Minor](#aggiornamento-versione-minor)
- [Aggiornamento Versione Major](#aggiornamento-versione-major)
- [Operazioni Post-Aggiornamento](#operazioni-post-aggiornamento)
- [Risoluzione dei Problemi](#risoluzione-dei-problemi)

---

## Comprendere le Versioni di NixOS

NixOS utilizza uno schema di versioning `AA.MM`:
- **Versione major**: rappresenta un rilascio significativo (es. 24.11, 25.05, 25.11)
- **Versione minor**: correzioni di bug e aggiornamenti di sicurezza all'interno della stessa versione major

Esempi:
- `24.11` → `25.05`: **Aggiornamento major**
- `25.05` → `25.11`: **Aggiornamento major**
- Aggiornamenti all'interno di `25.11`: **Aggiornamento minor** (aggiornamenti channel, aggiornamenti pacchetti)

---

## Comprendere stateVersion

La variabile `system.stateVersion` nella tua configurazione è **critica** e deve essere gestita con cura:

```nix
system.stateVersion = "25.11"; # Questo valore determina lo schema dei dati stateful
```

### Cos'è stateVersion?

`stateVersion` definisce la versione di rilascio di NixOS con cui i **dati stateful** del tuo sistema (database, file di stato, configurazioni) sono stati originariamente configurati. NON definisce quale versione di NixOS stai eseguendo.

### Quando Modificare stateVersion

⚠️ **IMPORTANTE**: Modifica `stateVersion` solo in questi casi:

1. **Installazione ex-novo**: impostala alla versione che stai installando
2. **Migrazione intenzionale dello stato**: quando vuoi migrare i dati stateful a uno schema più recente (richiede pianificazione accurata)

### Quando NON Modificare stateVersion

❌ **NON** modificare `stateVersion` quando:
- Aggiorni a una nuova versione di NixOS
- Aggiorni i pacchetti
- Cambi channel
- Ricostruisci il tuo sistema

### Perché È Importante

Modificare `stateVersion` può:
- Attivare migrazioni automatiche di database e file di stato
- Cambiare comportamenti predefiniti dei servizi
- Potenzialmente rompere servizi esistenti che dipendono dall'attuale schema di stato
- Causare perdita di dati se le migrazioni falliscono

**Regola generale**: se il tuo sistema funziona, lascia `stateVersion` invariata a meno che non hai una ragione specifica e comprendi le conseguenze.

---

## Prima di Aggiornare

### 1. Backup del Sistema

Crea sempre un backup prima di aggiornare:

```bash
# Backup dei dati importanti
sudo rsync -av /home /percorso/backup/destinazione
sudo rsync -av /etc/nixos /percorso/backup/destinazione

# Documenta la configurazione attuale
nixos-version > ~/nixos-version-prima-aggiornamento.txt
nix-channel --list > ~/channels-prima-aggiornamento.txt
```

### 2. Rivedi le Note di Rilascio

Leggi sempre le note di rilascio per la versione target:
- [Note di Rilascio NixOS 25.11](https://nixos.org/manual/nixos/stable/release-notes.html#sec-release-25.11)
- [Manuale NixOS](https://nixos.org/manual/nixos/stable/)

Cerca:
- Modifiche che rompono la compatibilità
- Opzioni deprecate
- Interventi manuali richiesti
- Nuove funzionalità e miglioramenti

### 3. Pulisci il Sistema

```bash
# Rimuovi vecchie generazioni (mantieni le ultime 3)
sudo nix-collect-garbage --delete-older-than 3d

# Controlla lo spazio disco disponibile
df -h
```

---

## Aggiornamento Versione Minor

Gli aggiornamenti minor sono aggiornamenti all'interno della stessa versione NixOS (es. aggiornamenti pacchetti, patch di sicurezza).

### Passaggi

1. **Aggiorna i channel**:
   ```bash
   sudo nix-channel --update
   ```

2. **Ricostruisci il sistema**:
   ```bash
   sudo nixos-rebuild switch
   ```

3. **Verifica l'aggiornamento**:
   ```bash
   nixos-version
   ```

4. **Riavvia se il kernel è stato aggiornato**:
   ```bash
   sudo reboot
   ```

**Nota**: Non sono necessarie modifiche a `stateVersion` per gli aggiornamenti minor.

---

## Aggiornamento Versione Major

Gli aggiornamenti major comportano il passaggio a un nuovo rilascio di NixOS (es. 25.05 → 25.11).

### Metodo 1: Utilizzando i Channel (Raccomandato per Sistemi Stabili)

#### Passo 1: Passa al Nuovo Channel

```bash
# Controlla i channel attuali
sudo nix-channel --list

# Passa alla nuova versione (esempio: 25.11)
sudo nix-channel --add https://nixos.org/channels/nixos-25.11 nixos
sudo nix-channel --update
```

#### Passo 2: Rivedi le Modifiche alla Configurazione

Controlla opzioni deprecate o modifiche che rompono la compatibilità:

```bash
# Testa la configurazione senza applicarla
sudo nixos-rebuild dry-build
```

#### Passo 3: Applica l'Aggiornamento

```bash
# Aggiorna il sistema
sudo nixos-rebuild switch --upgrade

# Alternativa: prima build, poi switch
sudo nixos-rebuild boot --upgrade
sudo reboot
```

#### Passo 4: Verifica l'Aggiornamento

```bash
nixos-version
# Dovrebbe mostrare: 25.11.xxxxxx.xxxxxxx (NixOS)
```

---

## Operazioni Post-Aggiornamento

### 1. Controlla lo Stato del Sistema

```bash
# Controlla servizi falliti
systemctl --failed

# Controlla i log di sistema
journalctl -p err -b
```

### 2. Aggiorna i Channel Utente (se applicabile)

```bash
# Per ogni utente
nix-channel --update
```

### 3. Pulisci le Vecchie Generazioni

Dopo aver confermato che il sistema funziona correttamente:

```bash
# Elenca le generazioni
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rimuovi vecchie generazioni (mantieni le ultime 5)
sudo nix-collect-garbage --delete-older-than 5d

# Oppure rimuovi generazioni specifiche
sudo nix-env --delete-generations 1 2 3 --profile /nix/var/nix/profiles/system
```

### 4. Ottimizza il Nix Store

```bash
sudo nix-store --optimise
```

---

## Risoluzione dei Problemi

### Il Sistema Non Si Avvia Dopo l'Aggiornamento

1. **Avvia in una generazione precedente**:
   - All'avvio, seleziona una generazione più vecchia dal menu del bootloader
   - Una volta avviato, indaga sul problema

2. **Rollback**:
   ```bash
   # Rollback alla generazione precedente
   sudo nixos-rebuild switch --rollback
   ```

### Errori di Configurazione

Se incontri errori di configurazione:

```bash
# Controlla errori di sintassi
sudo nixos-rebuild dry-build

# Rivedi attentamente i messaggi di errore
# Problemi comuni:
# - Opzioni rimosse o rinominate
# - Valori predefiniti modificati
# - Combinazioni di pacchetti incompatibili
```

### Fallimenti dei Servizi

```bash
# Controlla un servizio specifico
sudo systemctl status nome-servizio

# Visualizza i log
sudo journalctl -u nome-servizio -b

# Riavvia il servizio
sudo systemctl restart nome-servizio
```

### Fallimenti nella Build dei Pacchetti

```bash
# Pulisci la cache dei pacchetti
nix-collect-garbage -d

# Prova a ricostruire
sudo nixos-rebuild switch --upgrade

# Se un pacchetto specifico fallisce, controlla:
# - Note di rilascio per quel pacchetto
# - NixOS discourse: https://discourse.nixos.org/
# - GitHub issues: https://github.com/NixOS/nixpkgs/issues
```

### Recupero da una Modifica Errata di stateVersion

Se hai accidentalmente modificato `stateVersion` e qualcosa si è rotto:

1. **Ripristinala immediatamente** al valore originale
2. **Ricostruisci**:
   ```bash
   sudo nixos-rebuild switch
   ```
3. **Controlla gli stati dei servizi**:
   ```bash
   sudo systemctl --failed
   ```
4. **Ripristina dal backup** se necessario

---

## Risorse Aggiuntive

- [Manuale NixOS](https://nixos.org/manual/nixos/stable/)
- [NixOS Wiki - Aggiornamento](https://nixos.wiki/wiki/Upgrading_NixOS)
- [NixOS Discourse](https://discourse.nixos.org/)
- [NixOS GitHub](https://github.com/NixOS/nixpkgs)
- [NixOS Release Channels](https://channels.nixos.org/)