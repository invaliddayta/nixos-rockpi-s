# nixos-rockpi-s

A plug-and-play NixOS flake for the Radxa Rock Pi S (RK3308). 

Getting NixOS to boot on this board is normally a pain. This flake handles the dirty work so you can just build, flash, and boot.

**Note:** Built and tested on the **512MB** variant. NixOS evaluation is heavy, so your mileage may vary on the 256MB board.

### What it does out of the box:
* **Bootloader:** Pre-injects a working Radxa U-Boot to bypass compiling proprietary RK3308 RAM blobs.
* **RAMdisk Fix:** Patches `ramdisk_addr_r` via scripts so the initrd doesn't collide with the kernel.
* **Serial Console:** Forces the kernel to use Rockchip's native `1.5M` baud rate.

---

## 1. Quick Start

**Build the image:**
*(Make sure `rockpis-bootloader.bin` stays tracked by git if you edit the flake locally!)*
```bash
git clone [https://github.com/YOUR-USERNAME/nixos-rockpi-s.git](https://github.com/YOUR-USERNAME/nixos-rockpi-s.git)
cd nixos-rockpi-s
nix build .#default
```

**Flash to SD card:**
```bash
sudo dd if=result/sd-image/*.img of=/dev/sdX bs=4M status=progress
```

**Log in:**
* User: `nixos` | Password: `nixos` (passwordless sudo)
* User: `root`  | Password: *(empty)*

---

## 2. Permanent Configuration

Don't run off the installer image forever. I've included an `example/` directory to help you set up a real system.

1. Copy the `example/` folder to your board (e.g., to `/etc/nixos/`).
2. Generate your hardware config:
   ```bash
   sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
   ```
3. **Important:** Edit `configuration.nix` and replace `"YOURSSHKEY"` with your actual SSH public key, or you'll be locked out of root SSH.
4. Apply the config:
   ```bash
   sudo nixos-rebuild switch --flake .#rockpis
   ```

### ⚠️ Rebuilds & Swap Warning
Rebuilding directly on the Rock Pi S is extremely slow. The first run can take ~20 minutes, and it might look frozen. 
I've included a swapfile in the example config to prevent Out-Of-Memory (OOM) crashes during builds. If you prefer to cross-compile or deploy remotely from a faster machine, you don't need this swap—feel free to delete it from the config.

---

## 3. Serial Debugging (UART)

USB-C OTG serial is off by default. To view the boot logs, use a 3.3V USB-to-TTL adapter on **UART0**.

* **GND** -> Pin 6
* **RX** -> Pin 8 (UART0_TX)
* **TX** -> Pin 10 (UART0_RX)

**Baud Rate:** You *must* use `1500000` baud. Standard 115200 will just show garbage.
```bash
sudo picocom -b 1500000 /dev/ttyUSB0
```

---

## 4. How the Bootloader Trick Works

Building RK3308 U-Boot from source in Nixpkgs is incredibly fragile due to proprietary DDR blobs. Instead, this flake extracts a working bootloader directly from the official Radxa Debian image. 

During the Nix `postBuildCommands` phase, it gets injected into the front of the `.img` (skipping 64 sectors to preserve the NixOS GPT table). 

If you ever need to extract a newer bootloader from an official Radxa `.img` yourself, run:
```bash
dd if=radxa-debian-updated.img of=rockpis-bootloader.bin bs=512 skip=64 count=32704
```
