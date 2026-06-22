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
          networkmanager.enable = true;
          inherit hostName;
        };
        imports =   
        [ 
          inputs.sops-nix.nixosModules.sops
          inputs.self.nixosModules."${hostName}-hardware"
          inputs.self.nixosModules."${hostName}-configuration"
          inputs.opinions.nixosModules.protoplast_tb
          # inputs.opinions.nixosModules.erpnext
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

        users.groups.cloudflared = {};
        users.users.cloudflared = {
          isSystemUser = true;
          group = "cloudflared";
        };
        sops.secrets."cloudflare" = {
          sopsFile = "${inputs.self}/secrets/${hostName}.yaml";
          format = "yaml";
          owner = config.users.users.cloudflared.name;
          group = config.users.groups.cloudflared.name;
        };
      
        systemd.services.cloudflared-tunnel = {
          description = "Cloudflared Remotely Managed Tunnel";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          serviceConfig = {
            User = "cloudflared"; Group = "cloudflared";
            ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run";
            # "TUNNEL_TOKEN=...", cloudflared will pick it up automatically
            EnvironmentFile = config.sops.secrets."cloudflare".path;
            Restart = "always";
            RestartSec = "5s";
            # Extra security hardening (optional but recommended since we removed DynamicUser)
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
          };
        };
        
        # command to generate yggdrasil key
        # nix run nixpkgs#yggdrasil -- -useconffile <(yggdrasil -genconf -json) -exportkey
        sops.secrets."yggdrasil" = {
          sopsFile = "${inputs.self}/secrets/${hostName}.yaml";
          format = "yaml";
        };
      }; 
    }; 
  };
}

