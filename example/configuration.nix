{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # U-Boot standard bootflow requires extlinux
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # RK3308 native baud rate is 1.5M; required to maintain serial output after handoff
  boot.kernelParams = [ "console=ttyS0,1500000n8" ];

  # Memory optimizations for low-RAM hardware
  zramSwap.enable = true;
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 1024; # 1GB swap safety net for OOM errors
  }];

  networking.hostName = "rockpis";
  networking.networkmanager.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "YOURSSHKEY"
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };

  environment.systemPackages = with pkgs; [ vim curl git ];

  system.stateVersion = "25.11"; 
}
