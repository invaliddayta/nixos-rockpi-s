# NixOS for Radxa Rock Pi S

A heavily automated, plug-and-play NixOS flake for the Radxa Rock Pi S (RK3308 SoC). 

If you've tried putting NixOS on this board before, you know it's a massive headache. Between proprietary DDR initialization blobs, RAMdisk memory overlaps, and serial console baud rate mismatches, it's easy to brick the boot process. This project patches all of that and lets you build a bootable SD card image with a single command.

**Hardware Note:** This flake was built and tested on the **512MB RAM** variant of the Rock Pi S. There is no guarantee it will work on the 256MB version (NixOS evaluation and builds are very memory-hungry).

## What this fixes
* **Bootloader Injection:** Pre-vendors a known-good Radxa U-Boot binary so we don't have to deal with compiling proprietary RK3308 RAM init blobs.
* **RAMdisk Overlaps:** Automatically patches U-Boot's `ramdisk_addr_r` via injected scripts. This stops the NixOS initrd from colliding with the kernel in memory.
* **Serial Console:** Forces the Linux kernel to use Rockchip's native `1500000` baud rate so your terminal doesn't output garbage during boot.

---

## Quick Start

### 1. Build the Image
You'll need a machine with Nix installed and flakes enabled. Clone this repo and build the image:

```bash
git clone [https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git](https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git)
cd YOUR-REPO-NAME
nix build .#default
```
*(Note: The `rockpis-bootloader.bin` file is included in this repo. If you tweak the flake locally, make sure that file stays tracked by git, otherwise the Nix daemon will throw a "file not found" error during the build!)*

### 2. Flash to SD Card
Once the build finishes, you'll find a raw `.img` file in the `result/sd-image/` directory. Flash it using `dd`, BalenaEtcher, Popsicle, etc.

```bash
sudo popsicle result/sd-image/*.img /dev/sdX
```
*(Make sure to replace `/dev/sdX` with your actual SD card!)*

### 3. Boot & Connect
Pop the SD card into the Rock Pi S and plug it in. 

**Default Credentials:**
* **User:** `nixos` | **Password:** `nixos` *(Has passwordless `sudo`)*
* **User:** `root`  | **Password:** *(None / Empty)*

---

## Next Steps: Configuring Your System

Once you're booted, you shouldn't run off the installer image forever. I've included an `example/` directory in this repo to help you transition to a permanent NixOS setup.

1. Copy the contents of the `example/` folder directly to your Rock Pi S (e.g., into `/etc/nixos/`).
2. **Generate your hardware config:** Run `sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix`.
3. **Add your SSH Key:** Open `configuration.nix` and replace `"YOURSSHKEY"` with your actual public SSH key, or you won't be able to SSH in as root.
4. Apply the flake: `sudo nixos-rebuild switch --flake .#rockpis`

### A Warning on Swap and Rebuild Times
I've added swap to both the base image and the example configuration. If you rebuild directly on the device, you are going to need it to avoid Out-Of-Memory (OOM) crashes.
* **It is going to be slow:** Rebuilding on this board relies heavily on that swapfile. The first rebuild can easily take ~20 minutes. It might look completely stuck at times—just let it do its thing.
* **Don't need it?** If you never plan to run `nixos-rebuild` locally on the board (e.g., you prefer to cross-compile and deploy remotely from a faster machine), you don't actually need the swap. Feel free to remove it from the config to save SD card space and wear.

---

## Serial Console (UART) Setup

USB-C OTG serial isn't enabled by default. If you want to watch the boot process or debug, you need a **3.3V USB-to-TTL serial adapter** hooked up to **UART0**.

**Wiring:**
* Adapter **GND** -> Rock Pi S **Pin 6** (GND)
* Adapter **RX** -> Rock Pi S **Pin 8** (UART0_TX)
* Adapter **TX** -> Rock Pi S **Pin 10** (UART0_RX)
*(Leave the VCC power pin disconnected. Power the board normally via USB-C).*

**The Baud Rate Gotcha:**
You **must** connect at `1500000` baud. Standard speeds like `115200` will just spit out unreadable garbage.

Example using `picocom` on Linux:
```bash
sudo picocom -b 1500000 /dev/ttyUSB0
```

---

## The "Dirty" Bootloader Trick (For Developers)

You probably noticed the 16MB `rockpis-bootloader.bin` file. 

Building U-Boot from source for the RK3308 requires highly specific proprietary DDR memory timing blobs (`rkbin`). Doing this cleanly within Nixpkgs is incredibly fragile. 

Instead, this project extracts a perfectly working bootloader (including Trust partitions and DDR blobs) straight from the official Radxa Debian image. The flake uses `dd` to inject this binary into the empty space at the beginning of the NixOS SD card image during the `postBuildCommands` phase.

*(It uses `skip=64` & `seek=64` to skip the first 64 sectors and preserve the GPT partition table NixOS just made).*

**Updating the bootloader yourself:**
If you ever need to pull a newer bootloader from an official Radxa `.img`, run this:
```bash
dd if=radxa-debian-updated.img of=rockpis-bootloader.bin bs=512 skip=64 count=32704
```

---

## License
Open-source. Fork it, tweak it, and use it for your own embedded NixOS projects.
