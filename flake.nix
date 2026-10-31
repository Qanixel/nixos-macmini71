{
  description = "Qanix's Nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nixos-unstable 对应 home-manager 的 master 分支；
    # follows 让 home-manager 复用同一份 nixpkgs，避免两份依赖。
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    mirrors-nix.url = "github:luochen1990/mirrors-nix";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  # 注意：inputs 里新增的依赖，需要在下面 outputs 的参数里继承（inputs@ 已包含全部）。

  outputs = inputs@{ nixpkgs, home-manager, mirrors-nix, ... }: {
    nixosConfigurations = {
      Macmini = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
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
            home-manager.backupFileExtension = "backup";
          }
        ];
      };
    };
  };
}

