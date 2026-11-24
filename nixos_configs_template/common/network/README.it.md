# Rete

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

I moduli condivisi forniscono le basi della rete; profili e reti consentite per i servizi appartengono a ogni host.

| Modulo | Funzione |
| --- | --- |
| `default_network.nix` | NetworkManager client, firewall e strumenti WireGuard. |
| `server_network.nix` | NetworkManager server, nftables e firewall; importato dal ruolo server. |
| `default_bluetooth.nix` | Configurazione hardware e firmware Bluetooth. Un gestore grafico si seleziona separatamente. |

Da un host in `hosts/client/<nome>/` o `hosts/server/<nome>/`, gli import comuni usano `../../../common/network/`. Il ruolo server importa già il modulo di rete server. Vedi [ruoli](../../roles/README.it.md) e [servizi](../services/README.it.md).

## Profili e regole di accesso dell'host

Entrambe le categorie host contengono `nm_configurations.nix.template`. Preparalo come `nm_configurations.nix` e mantieni il suo import locale in `configuration.nix` dell'host. Gestisce WiFi e filtri CIDR SSH/RDP.

Se `RDP_ALLOWED_CIDRS` è vuoto, usa i CIDR SSH per RDP. Dividi poi `SSH_ALLOWED_CIDRS` e i CIDR RDP effettivi nelle famiglie IPv4 e IPv6 e prepara i token `*_ALLOWED_IPV4_NIX`/`*_ALLOWED_IPV6_NIX` come liste Nix. Per esempio, reti riservate alla documentazione diventano:

```nix
  ssh4 = [ "192.0.2.0/24" ];
  ssh6 = [ "2001:db8::/32" ];
  rdp4 = [];
  rdp6 = [];
```

Usa reti appropriate all'host reale. Il modulo costruisce le regole nftables da queste liste e legge le porte OpenSSH effettive e la porta xrdp dalla configurazione NixOS, quindi modificare `SSH_PORT` o `RDP_PORT` mantiene il filtro coerente.

Un filtro per subnet SSH configurato disabilita l'apertura firewall automatica di OpenSSH. Mantieni le stesse porte fuori da `allowedTCPPorts` globali o per interfaccia, intervalli di porte e interfacce fidate, che potrebbero aggirare il filtro per sorgente. IPv4 e IPv6 sono gestiti separatamente.

I moduli SSH e RDP del server non aprono automaticamente porte. Le liste CIDR vuote non aggiungono regole di accettazione. La base client mantiene la policy firewall OpenSSH esistente salvo inserimento di un filtro per subnet. RDP richiede un intervallo consentito, fornito direttamente o ereditato da SSH.

## WiFi con credenziali cifrate

Imposta `ENABLE_WIFI=true` e prepara `WIFI_SSID_NIX` come stringa Nix completa con escape corretti. Gli SSID sono configurazione pubblica dell'host. Il file host `../../../secrets/<hostname>.yaml` contiene il valore cifrato `wifi_env` con `WIFI_PSK`; segui [SECRETS.it.md](../config/SECRETS.it.md). WiFi disabilitato richiede `ENABLE_WIFI=false` e `WIFI_SSID_NIX=""`.

`ensureProfiles` di NetworkManager legge il file di ambiente decifrato all'attivazione. Il template mantiene automatici IPv4 e IPv6 e usa `"$WIFI_PSK"` per la PSK; conserva questa variabile di runtime. I destinatari della chiave host devono essere preparati prima dell'attivazione.

I profili dichiarativi si applicano in `/run/NetworkManager/system-connections/`. Mantieni configurazione Nix dell'host e segreto cifrato come fonte di verità. Modificare i profili dalla GUI o con `nmcli connection modify` può salvare copie aggiuntive in `/etc/`.

## Syncthing e VPN

Syncthing risiede in `syncthing.nix` di ogni host e disabilita le aperture automatiche delle porte. Consenti il listener TCP selezionato soltanto dalle reti dei peer desiderati nella policy di rete dell'host; la GUI HTTPS ascolta su loopback ed è raggiungibile tramite tunnel SSH. Vedi la [guida host](../../hosts/README.it.md).

Il modulo client include `wireguard-tools`. NetworkManager supporta direttamente le connessioni WireGuard; in alternativa usa `wg-quick`. Aggiungi una regola firewall UDP esplicita soltanto su un host che riceve traffico VPN in ingresso.
