# LUKS Key Management (passphrase and USB keys)

> **Available languages**: [English (current)](LUKS_KEYS.md) | [Italiano](LUKS_KEYS.it.md)

This guide explains the LUKS-related options used by the Disko templates in this folder, and how to combine **multiple passphrases**, one or more **USB key sticks** and/or the **TPM2 chip** (with an optional PIN) to unlock the encrypted disk — enrolling them either **at installation (format) time** or **later, on an already-installed system**.

---

## How LUKS keys work

A LUKS2 volume has up to **32 independent keyslots**. Each slot holds one key (a passphrase or the content of a key file); **any single one of them unlocks the disk**, and each can be added or revoked without touching the others. This is what makes the scenario "passphrase + two USB sticks with different keys" possible: three slots, three independent ways in. If you lose one stick, you revoke only its slot.

With the templates in this folder the slot layout is deterministic:

| Slot | Key                          | Where it comes from                                      |
|------|------------------------------|----------------------------------------------------------|
| 0    | your passphrase              | `passwordFile` at format time                             |
| 1…n  | extra keys (e.g. USB sticks) | `additionalKeyFiles` at format time, or `luksAddKey` later |
| 1…n  | TPM2 (key held by the chip, optional PIN) | `systemd-cryptenroll` on the running system |

---

## Options reference

### `passwordFile`

Used **only while formatting**: when Disko runs `cryptsetup luksFormat`, the content of this file becomes the passphrase stored in keyslot 0. After installation the file is gone and irrelevant — at every boot you type that passphrase at the prompt. Create it right before running Disko:

```bash
echo -n "yourpassphrase" > /tmp/secret.key
```

`echo -n` matters: cryptsetup compares **exact bytes**, and a trailing newline would become part of the passphrase. On the NixOS installer `/tmp` lives in RAM, so the file disappears at reboot.

### `settings.*` — boot-time behavior

Everything inside `settings` is forwarded verbatim by Disko to the NixOS option `boot.initrd.luks.devices.<name>`, i.e. it configures **how the initrd unlocks the disk at every boot**:

- **`allowDiscards`** — lets TRIM/discard commands from the filesystem pass through the encrypted layer down to the SSD. dm-crypt blocks them by default: the drawback of enabling it is that an attacker inspecting the raw disk can see *how much* space is in use (not its content). Without it, `fstrim` has no effect on the volume and SSD performance degrades over time. On an SSD you normally want this `true` — which is why the templates ship it enabled.
- **`keyFile`** — a path the initrd reads to unlock the disk *without prompting*. The path must be readable **inside the initrd**, so in practice it is a raw device (a USB stick) or a udev symlink pointing to it — not a file on some filesystem.
- **`keyFileSize`** — read only the first N bytes of `keyFile` as the key. Needed with raw-device keys, where the "file" would otherwise be the whole stick.
- **`keyFileOffset`** — start reading the key at a byte offset instead of the beginning of the device.
- **`keyFileTimeout`** — how many seconds to wait for the key device to appear; when it expires, the initrd falls back to the normal passphrase prompt. This is what makes the USB key *optional* at boot. Works with the systemd initrd (`boot.initrd.systemd.enable = true`, see `common/config/boot_luks.nix`).
- **`fallbackToPassword`** — same fallback idea for the legacy script-based initrd; with the systemd initrd use `keyFileTimeout` instead.

### `additionalKeyFiles`

A list of files that Disko enrolls as **extra keyslots right after `luksFormat`** (one `luksAddKey` each, slots 1, 2, … in list order). This is how you register USB keys already at installation time.

---

## Scenarios

The building blocks are always the same — `passwordFile` (slot 0), `additionalKeyFiles` (extra slots at format time), `cryptsetup luksAddKey` (extra slots later), `settings.keyFile` (automatic unlock at boot). What changes between scenarios is how you combine them.

### 1. Multiple passphrases, no USB key

Useful for an emergency/backup passphrase (kept in a password manager or printed and stored somewhere safe), or for two people using the same machine with different passphrases. No extra NixOS options are needed: the boot prompt tries whatever you type against **every** keyslot, so any enrolled passphrase unlocks the disk.

**At installation time** — write the extra passphrase in a file and enroll it with `additionalKeyFiles`:

```bash
echo -n "yourpassphrase"     > /tmp/secret.key   # slot 0
echo -n "recoverypassphrase" > /tmp/second.key   # slot 1
```

```nix
passwordFile = "/tmp/secret.key";
additionalKeyFiles = [ "/tmp/second.key" ];
```

Since the file is created with `echo -n` (no trailing newline), the very same string can later be typed at the boot prompt.

**On an already-installed system** — fully interactive, nothing to configure or rebuild:

```bash
sudo cryptsetup luksAddKey /dev/nvme0n1p2
```

It asks for an existing passphrase to authorize, then for the new passphrase twice.

### 2. Passphrase + one USB key

Identical to scenario 3 below — prepare the stick and enroll it (section A at installation time, section B afterwards) — but the NixOS side is simpler: with a single stick the udev rule is optional, because `keyFile` can point directly at the stick's stable path:

```nix
settings = {
  allowDiscards = true;
  keyFile = "/dev/disk/by-id/usb-STICK1-0:0";  # the stick itself
  keyFileSize = 4096;
  keyFileTimeout = 10;                         # no stick inserted → passphrase prompt
};
```

The udev rule (`/dev/usbkey`) remains a good idea if you plan to add a second stick later: you would only add one more line to it.

### 3. Passphrase + two or more USB keys

The simplest robust setup stores the key as the **first 4096 raw bytes of the stick**. Note that writing them **destroys any partition table/filesystem on the stick**: it becomes a dedicated key stick (it will look "empty/corrupted" to file managers). Give each stick a *different* random key, so each occupies its own slot and can be revoked individually.

#### A. Enrolling the USB keys at installation time

1. Identify the sticks and write a random key on each (can be done beforehand, on any machine):

   ```bash
   ls -l /dev/disk/by-id/ | grep usb
   sudo dd if=/dev/urandom of=/dev/disk/by-id/usb-STICK1-0:0 bs=4096 count=1
   sudo dd if=/dev/urandom of=/dev/disk/by-id/usb-STICK2-0:0 bs=4096 count=1
   ```

2. From the installer, right before running Disko, create the passphrase file and dump each stick's key bytes to a temporary file:

   ```bash
   echo -n "yourpassphrase" > /tmp/secret.key
   dd if=/dev/disk/by-id/usb-STICK1-0:0 of=/tmp/usbkey1.key bs=4096 count=1
   dd if=/dev/disk/by-id/usb-STICK2-0:0 of=/tmp/usbkey2.key bs=4096 count=1
   ```

3. In your host's copy of the template, uncomment/set:

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

4. Add the udev rule below to the host's `configuration.nix`, then run Disko and install as usual. The disk is born with all three slots, and the first boot can already be unlocked with either stick or the passphrase.

#### B. Enrolling the USB keys on an already-installed system

1. Write a random key on the stick, then register it (it asks for the current passphrase to authorize):

   ```bash
   sudo dd if=/dev/urandom of=/dev/disk/by-id/usb-STICK1-0:0 bs=4096 count=1
   sudo cryptsetup luksAddKey /dev/nvme0n1p2 /dev/disk/by-id/usb-STICK1-0:0 --new-keyfile-size 4096
   ```

   (`/dev/nvme0n1p2` is the LUKS partition — find yours with `lsblk -f | grep crypto_LUKS`.)

2. Add the same `settings` lines shown above to the host's Disko file. On an installed host this is **safe**: `settings` only changes the generated boot configuration, Disko never re-formats anything on rebuild.

3. Add the udev rule below to `configuration.nix`, rebuild (`nixos-rebuild switch`), and test before trusting it (see below).

#### The udev rule (both cases)

`keyFile` accepts a single path, so with two sticks the trick is a udev rule in the initrd that gives **both sticks the same symlink** `/dev/usbkey` — whichever one is plugged in, the path is valid. Get each stick's serial with `udevadm info /dev/sdX | grep ID_SERIAL_SHORT`, then:

```nix
boot.initrd.services.udev.rules = ''
  SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_SERIAL_SHORT}=="SERIAL1", SYMLINK+="usbkey"
  SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_SERIAL_SHORT}=="SERIAL2", SYMLINK+="usbkey"
'';
```

Result at boot: with a stick inserted the machine unlocks by itself; without one, after `keyFileTimeout` seconds you get the usual passphrase prompt.

### 4. TPM2: automatic unlock, with or without PIN

The TPM2 chip on the motherboard can hold a key and release it **only if the measured boot state matches the expected one** (firmware, Secure Boot…): the disk unlocks by itself, nothing to type. Requirements: LUKS2 (these templates already create it), the systemd initrd (`boot.initrd.systemd.enable = true`, see `common/config/boot_luks.nix`) and a TPM2 chip — check with `systemd-analyze has-tpm2`.

Enrollment happens **on the running system** and occupies an extra keyslot next to the passphrase:

```bash
# bind the unlock to the Secure Boot state (PCR 7)
sudo systemd-cryptenroll /dev/nvme0n1p2 --tpm2-device=auto --tpm2-pcrs=7

# stronger: additionally require a PIN typed at boot
sudo systemd-cryptenroll /dev/nvme0n1p2 --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes
```

On the NixOS side, uncomment the ready-made lines:

- in the host's Disko file: `crypttabExtraOpts = [ "tpm2-device=auto" ];`
- in `common/config/boot_luks.nix`: `security.tpm2.enable = true;`

**PIN or no PIN?** Without a PIN the machine boots unattended straight to the login screen: convenient, but a stolen laptop gets there too, so all the protection shifts to the user password/lockscreen. With `--tpm2-with-pin=yes` you type a short PIN at boot: you keep the TPM's anti-tampering (the key is released only with a healthy measured boot) **plus** a knowledge factor, and the TPM's built-in dictionary-attack lockout throttles brute-force attempts. It is the sensible middle ground for laptops.

Note that the PIN needs **no extra option in `settings`**: the requirement is stored in the LUKS2 header at enrollment time (`--tpm2-with-pin=yes`), the PIN itself is set interactively during that same enrollment, and at boot the PIN prompt appears automatically (`tpm2-device=auto` is all the configuration needed). To change the PIN, re-enroll: `--wipe-slot=tpm2`, then enroll again.

Notes:

- **PCR 7** binds the unlock to the Secure Boot state — a natural fit with the Lanzaboote setup in `hosts/secure_boot/`. Binding more PCRs (e.g. `--tpm2-pcrs=0+2+7`) is stricter, but firmware updates will drop you to the recovery passphrase more often.
- **Always keep the passphrase in its keyslot** as recovery: after a firmware update, a PCR change or a TPM reset it is the only way back in. Then re-enroll with `systemd-cryptenroll --wipe-slot=tpm2` followed by a new enrollment.
- `cryptsetup luksDump` shows the `tpm2` token; `systemd-cryptenroll /dev/... --wipe-slot=tpm2` removes it.

---

## Verification and maintenance

```bash
# test a key without touching anything
sudo cryptsetup open --test-passphrase /dev/nvme0n1p2 --key-file /dev/disk/by-id/usb-STICK1-0:0 --keyfile-size 4096 && echo OK

# see which keyslots are occupied
sudo cryptsetup luksDump /dev/nvme0n1p2

# lost a stick? revoke only its slot (test which slot is which with --test-passphrase --key-slot N)
sudo cryptsetup luksKillSlot /dev/nvme0n1p2 2

# header backup — store it OUTSIDE this disk
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p2 --header-backup-file luks-header.img
```

---

## Security notes

- **Never** store a boot key file on an unencrypted partition of the same disk (e.g. `/boot`): that is the key taped on top of the safe. Removable media only.
- cryptsetup key files are compared **byte-for-byte**: create text passphrases with `echo -n`, and keep the enrolled size and the boot-time `keyFileSize` consistent (4096 in the examples).
- The `/tmp/*.key` files used during installation live in the installer's RAM and vanish at reboot.
