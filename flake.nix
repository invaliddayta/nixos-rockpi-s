{
  description = "Standalone Rock Pi S NixOS Image";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    packages.aarch64-linux.default = (nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ({ pkgs, ... }: {
          system.stateVersion = "25.11";

          sdImage.firmwarePartitionOffset = 32;
          sdImage.compressImage = false;

          # RK3308 native baud rate is 1.5M; required to maintain serial output after handoff
          boot.kernelParams = [ "console=ttyS0,1500000n8" ];
          
          networking.networkmanager.enable = true;

          # Memory optimizations for 256MB/512MB RAM
          zramSwap.enable = true;
          swapDevices = [{
            device = "/var/lib/swapfile";
            size = 1024;
          }];

          # Fix RAMdisk memory overlap with the kernel
          sdImage.populateRootCommands = ''
            mkdir -p ./files/boot
            
            # Set ramdisk_addr_r via uEnv.txt and boot.scr for maximum compatibility
            echo "ramdisk_addr_r=0x0c000000" > ./files/uEnv.txt
            echo "ramdisk_addr_r=0x0c000000" > ./files/boot/uEnv.txt

            ${pkgs.ubootTools}/bin/mkimage -A arm -O linux -T script -C none -n "Ramdisk Fix" -d ${pkgs.writeText "boot.cmd" ''
              if test "$ramdisk_fixed" = "1"; then
                echo "Ramdisk fix already applied."
                exit
              fi
              setenv ramdisk_addr_r 0x0c000000
              setenv ramdisk_fixed 1
              bootflow scan mmc
            ''} ./files/boot.scr
            cp ./files/boot.scr ./files/boot/boot.scr
          '';

          # Inject Radxa Bootloader. skip/seek=64 preserves the NixOS GPT table.
          sdImage.postBuildCommands = ''
            dd if=${./rockpis-bootloader.bin} of=$img bs=512 skip=64 seek=64 count=32704 conv=notrunc
          '';

          users.users.root.initialPassword = "";
        })
      ];
    }).config.system.build.sdImage;
  };
}
