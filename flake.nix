{
  description = "A simple flake.nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {
      # Macmini is the host name definded in configration.nix
      Macmini = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Match the system strugles
        modules = [
          ./hardware-configuration.nix
          ./configuration.nix
        ];
      };
    };
  };
}

