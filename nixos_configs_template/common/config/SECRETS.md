# Secrets Management with sops-nix

> **Available languages**: [English (current)](SECRETS.md) | [Italiano](SECRETS.it.md)

Everything you write in a NixOS configuration ends up in the Nix store, which is **world-readable by every user and process on the machine** - and your copy of `nixos_configs` typically lives in a versioned folder, synced between machines or backed up. Passwords, WiFi keys and tokens must therefore never appear in cleartext in `.nix` files. This template solves it with [sops-nix](https://github.com/Mic92/sops-nix): **secrets stay inside `nixos_configs`, but encrypted** - you can version, sync or back it up without exposing them; each host decrypts them at system activation using a key derived from its own SSH host key, and the decrypted values appear only under `/run/secrets*` (RAM), with the right owner and permissions.

---

## Architecture

Three pieces, each with one job:

| File | Role | Inside `nixos_configs` |
|------|------|-------------|
| `.sops.yaml` | **Who** can decrypt: age *public* keys + rules per file | Plaintext (safe: only public keys) |
| `secrets/common.yaml` | **What** the secrets are: fleet-wide values | Encrypted (keys visible, values encrypted) |
| `common/config/secrets.nix` | The machinery: sops-nix module (pinned), host key path, editing tools | Plain module, identical for every host |

Consumers then declare the secrets they need, right where they use them:

- `users/XYZ/user.nix` declares `user_hashedPassword` (with `neededForUsers = true`, decrypted before users are created) and reads it via `hashedPasswordFile`;
- `hosts/<host>/nm_configurations.nix` declares `wifi_env` and feeds it to `networking.networkmanager.ensureProfiles` as an environment file: WiFi profiles are generated **directly inside NetworkManager**, with the PSKs referenced as `$WIFI_*` variables - no `.nmconnection` files to copy around.

Physically, **nothing secret ever touches the persistent disk in cleartext**: on disk lives only the encrypted `secrets/common.yaml`; the decrypted values sit in `/run/secrets*` (RAM) and the rendered WiFi profiles in `/run/NetworkManager/system-connections/` (RAM as well, 0600 permissions). At shutdown everything evaporates and gets regenerated at the next boot.

Because `user.nix` is imported by every host, **every host must import `common/config/secrets.nix`** (the `sops.*` options must exist everywhere they are referenced).

Key model - this is the part worth understanding once:

- Each **host** decrypts with the age key mathematically derived from its SSH host key (`/etc/ssh/ssh_host_ed25519_key`). Nothing to generate or distribute: the machine already owns it.
- The **administrator** (you) has a personal age key pair for *editing* secrets, in `~/.config/sops/age/keys.txt`. The private key never enters `nixos_configs` (nor any other shared location); only its public half goes into `.sops.yaml`.
- Private keys never travel. Adding a reader always means: add its *public* key to `.sops.yaml`, then `sops updatekeys`.

---

## Initial setup (once)

1. **Admin key**:

   ```bash
   mkdir -p ~/.config/sops/age && chmod 700 ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   ```

   Note the printed public key (`age1...`). Copy `keys.txt` manually to any other workstation where you will edit secrets - never inside `nixos_configs` nor through shared or public channels.

2. **Rules**: rename `.sops.yaml.template` to `.sops.yaml` and paste your admin public key (host keys will join later, see below).

3. **First secrets file**:

   ```bash
   cp secrets/common.yaml.template secrets/common.yaml
   # fill in the values, then:
   sops -e -i secrets/common.yaml
   ```

From then on, always edit with `sops secrets/common.yaml`: it decrypts into your editor and re-encrypts on save. The tools (`sops`, `age`, `ssh-to-age`) are installed system-wide by `secrets.nix`; on a live installer use `nix-shell -p sops age ssh-to-age`.

---

## Daily use

- **Edit a value**: `sops secrets/common.yaml`.
- **Add a WiFi network**: add a `WIFI_<NAME>_PSK=...` line inside `wifi_env`, then declare the profile in the host's `nm_configurations.nix` (copy an existing block, set `id`/`ssid` and the `psk = "$WIFI_<NAME>_PSK"` variable). Each host lists only the networks it uses; the environment file carries them all.
- **Change the user password**: generate a hash with `mkpasswd -m sha-512`, paste it as the `user_hashedPassword` value.

---

## Adding a host

**Already-installed host**: derive its public key on the machine itself, add it, re-encrypt:

```bash
# on the new host
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
# on your workstation: add the printed age1... to .sops.yaml, then
sops updatekeys secrets/common.yaml
```

Do this **before** the first `nixos-rebuild switch` that uses secrets on that host: builds succeed regardless, but activation cannot decrypt until the key is in place.

**Fresh installation**: the SSH host key normally appears at first boot - too late for the installer. Generate it in advance, right after Disko has mounted the disk at `/mnt` and before `nixos-install`:

```bash
sudo mkdir -p /mnt/etc/ssh
sudo ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
sudo ssh-to-age < /mnt/etc/ssh/ssh_host_ed25519_key.pub
# add the printed key to .sops.yaml, run "sops updatekeys secrets/common.yaml",
# then continue the installation normally
```

The installed system finds its host key already present and decrypts from the very first boot.

---

## Removing a machine or a person

1. Remove its key from `.sops.yaml` and run `sops updatekeys secrets/common.yaml`.
2. **Rotate the values themselves** (`sops secrets/common.yaml`): removing a key stops *future* reads, but whoever held it may have already seen the old values. New WiFi password, new hash.

---

## Troubleshooting

- *Activation says it cannot decrypt* → that host's key is missing from `.sops.yaml` (or `updatekeys` was not run). Existing logins survive thanks to `users.mutableUsers = true`; fix the key and rebuild.
- *Who can currently decrypt?* → the `sops.age` recipients listed at the bottom of the encrypted file itself.
- *Check a file decrypts for you*: `sops -d secrets/common.yaml >/dev/null && echo ok`.

---

## Beyond the basic setup

- **Host-specific secrets**: add `secrets/<host>.yaml` with its own `creation_rules` entry (admin + that host only).
- **Many hosts / a team**: key groups per environment in `.sops.yaml`; `sops updatekeys` keeps rotation manageable.
- **CI/CD and cloud**: sops supports **KMS backends** (AWS/GCP/Azure) - same files, key custody moves to IAM-controlled services.
- **A central secret manager**: [OpenBao](https://openbao.org/) (the open-source fork of Vault) via sops' Vault-compatible backend.
