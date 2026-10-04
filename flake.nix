{
  description = "Qanix's Nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    mirrors-nix.url = "github:luochen1990/mirrors-nix";
  };
  
  # homemanager 的说明： follow 关键字用于继承，release-26.05 用于 与 nixos 保持一致
  # 记得inputs里写完后下面output要继承

  outputs = inputs@{ self, nixpkgs, home-manager, mirrors-nix, ... }: {
    nixosConfigurations = {
      Macmini = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ./configuration.nix
          mirrors-nix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs ; };
            home-manager.users.qanix = ./home.nix;
          }
        ];
      };
    };
  };
}

