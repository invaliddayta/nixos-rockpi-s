{
  description = "Rock Pi S NixOS Flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.rockpis = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [ ./configuration.nix ];
    };
  };
}
