{
  # Declares flake inputs
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    cosmic = {
      url = "github:0xnryn/cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opinions = {
      url = "github:0xnryn/opinions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sudha = {
      url = "github:0xnryn/sudha";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree = {
      url = "github:vic/import-tree";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs:
  inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [ 
      (inputs.import-tree ./modules) 
      inputs.cosmic.flakeModules.default
    ];
  };
}



