flakeContext@{ inputs, ... }:
{
  imports = [
    inputs.cosmic.flakeModules.default
  ];

  configurations.nixos = {
    "protoplast-server" = {
      system = "x86_64-linux";
      module = { config, pkgs, ... }:
      let
        hostName = "server";
      in
      {
        networking = {
          inherit hostName;
          networkmanager.enable = true;
          firewall.enable = true;
        };
        imports =   
        [ 
          inputs.sops-nix.nixosModules.sops
          inputs.self.nixosModules."${hostName}-hardware"
          inputs.self.nixosModules."${hostName}-configuration"
          inputs.opinions.nixosModules.protoplast_tb_postgres
          # inputs.opinions.nixosModules.protoplast_erpnext
        ];
        sops.age.keyFile = "/etc/${hostName}boot.txt";
        sops.secrets."ssh/ssh_host_ed25519_key" = {
          sopsFile = "${inputs.self}/secrets/${hostName}.yaml";
          format = "yaml";
          path = "/etc/ssh/ssh_host_ed25519_key"; # This is the symlink location
        };
        sops.secrets."tb_db_password" = {
          sopsFile = "${inputs.self}/secrets/${hostName}.yaml";
          format = "yaml";
        };
        users.users.sudha = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];          
          # hashedPasswordFile = config.sops.secrets."sudha-login-password".path;
        };
        sops.secrets."cloudflare" = {
          sopsFile = "${inputs.self}/secrets/${hostName}.yaml";
          format = "yaml";
          owner = config.users.users.cloudflared.name;
          group = config.users.groups.cloudflared.name;
        };
        # command to generate yggdrasil key
        # nix run nixpkgs#yggdrasil -- -useconffile <(yggdrasil -genconf -json) -exportkey
        sops.secrets."yggdrasil" = {
          sopsFile = "${inputs.self}/secrets/${hostName}.yaml";
          format = "yaml";
        };
        sops.secrets."protoplpast_erpnext" = {
          sopsFile = "${inputs.self}/secrets/${hostName}.yaml";
          format = "yaml";
        };
        systemd.tmpfiles.rules = [
          # f = create a file if it doesn't exist
          # 0400 = Read-only for owner, nothing for others
          # root = owner
          # root = group
          "f /etc/${config.networking.hostName}boot.txt 0400 root root -"
        ];
      }; 
    }; 
  };
}

