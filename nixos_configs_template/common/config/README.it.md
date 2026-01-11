# Configurazione del Sistema

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questa cartella contiene file di configurazione di base del sistema che definiscono i comportamenti fondamentali del sistema e i privilegi degli utenti.

## File Disponibili

- **`battery_management.nix`** - Configurazione per la gestione della batteria TLP e funzionalità di risparmio energetico, incluse soglie di carica della batteria, regolatori di frequenza CPU e politiche di prestazione energetiche per le modalità AC e batteria
- **`boot_luks.nix`** - Configurazione per il boot con crittografia LUKS e impostazioni Plymouth per la schermata di avvio
- **`os_compatibility.nix`** - Abilita la compatibilità con binari precompilati su NixOS usando nix-ld. Fornisce i percorsi delle librerie standard di Linux e le librerie condivise comuni (libc, libstdc++, X11, OpenGL, audio, ecc.) permettendo l'esecuzione di binari non-NixOS senza patch. Include supporto per applicazioni compatibili con FHS (Filesystem Hierarchy Standard). Configura inoltre le regole udev per l'accesso ai dispositivi HID (necessario per l'API WebHID in Chrome/Chromium per accedere a tastiere, mouse e altri dispositivi USB/HID) utilizzando il moderno meccanismo TAG+="uaccess". Sicuro da tenere abilitato anche quando non si usano attivamente binari esterni (importato automaticamente da `system.nix`)
- **`os_optimization.nix`** - Impostazioni di ottimizzazione del sistema incluse garbage collection automatica, ottimizzazione del Nix store, limiti del journal di systemd, supporto TRIM per SSD e configurazione zram (importato automaticamente da `system.nix`)
- **`sudo.nix`** - Configurazione per i privilegi sudo e le autorizzazioni degli utenti (importato automaticamente da `system.nix`)
- **`system.nix`** - Impostazioni di base del sistema inclusi locale, fuso orario, comportamenti fondamentali del sistema e importa `sudo.nix`, `os_compatibility.nix` e `os_optimization.nix`

## Utilizzo

Importa questi file di configurazione nel file `configuration.nix` specifico del tuo host:

```nix
imports = [
  # ...altri import...
  ../common/config/boot_luks.nix  # Opzionale: solo se si usa la crittografia LUKS
  ../common/config/battery_management.nix  # Opzionale: solo per laptop
  ../common/config/system.nix  # Richiesto: importa automaticamente sudo.nix e os_optimization.nix
  # ...altre configurazioni secondo necessità...
];
```

> **Nota**: Non è necessario importare `sudo.nix` e `os_optimization.nix` separatamente, poiché vengono importati automaticamente da `system.nix`.

## Personalizzazione

I file di configurazione in questa directory definiscono le impostazioni fondamentali del sistema. Puoi:

- Modificare `battery_management.nix` per regolare le soglie della batteria TLP e le politiche di gestione dell'energia
- Modificare `boot_luks.nix` per personalizzare le impostazioni di boot crittografato e la configurazione di Plymouth
- Modificare `sudo.nix` per regolare i livelli di privilegio degli utenti e le politiche di sicurezza (nota: importato automaticamente da `system.nix`)
- Modificare `os_optimization.nix` per ottimizzare la garbage collection di Nix, l'ottimizzazione dello store e la gestione delle risorse di sistema (nota: importato automaticamente da `system.nix`)
- Aggiornare `system.nix` per cambiare le impostazioni locali, i fusi orari o i comportamenti di base del sistema
- Fare riferimento a variabili specifiche dell'host per personalizzare le impostazioni per ogni macchina

### Esempio di Modifica

Se desideri personalizzare le impostazioni di sistema in `system.nix`:

```nix
# Nel file system.nix
{ config, pkgs, ... }:

{
  # Imposta il tuo fuso orario
  time.timeZone = "Europe/Rome";
  
  # Seleziona le proprietà di internazionalizzazione
  i18n.defaultLocale = "it_IT.UTF-8";
  
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };
  
  # Aggiungi qui le tue impostazioni di sistema personalizzate
  system.stateVersion = "25.11"; # NON MODIFICARE QUESTO VALORE
}
```

### Considerazioni

- I file di configurazione in questa directory formano la base della tua configurazione di sistema
- Fai attenzione quando modifichi le impostazioni di base poiché possono influire sulla stabilità del sistema
- Testa sempre le modifiche in un ambiente controllato prima di implementarle sui sistemi di produzione