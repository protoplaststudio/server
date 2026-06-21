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

        networking.firewall = {
          allowedTCPPorts = [ 53535 9001];
          allowedUDPPorts = [ 53535 9001];
        };
      
        services.yggdrasil = {
          enable = true;
          openMulticastPort = true;
          settings = {
            IfName = "ygg0";
            Listen = [ "tcp://0.0.0.0:53535" ];
            PrivateKeyPath = config.sops.secrets."yggdrasil".path; 
            NodeInfoPrivacy = true;
            Peers = [          # inputs.opinions.nixosModules.erpnext
    
              #india
              "tls://ins.8px.sk:4321"
              "quic://ins.8px.sk:4321"
              #hongkong
              "tcp://ygg5.mk16.de:1337?key=0000009611ae5391dc0aceea9f3fa6a0dc1279f4306059339e84bfb8b74d2f9b"
              "tls://ygg5.mk16.de:1338?key=0000009611ae5391dc0aceea9f3fa6a0dc1279f4306059339e84bfb8b74d2f9b"
              "quic://ygg5.mk16.de:1339?key=0000009611ae5391dc0aceea9f3fa6a0dc1279f4306059339e84bfb8b74d2f9b"
              "ws://ygg5.mk16.de:1340?key=0000009611ae5391dc0aceea9f3fa6a0dc1279f4306059339e84bfb8b74d2f9b"
              #singapore
              "tls://asia.deinfra.org:15015"
              "quic://asia.deinfra.org:15015"
              "tcp://yg-sin.magicum.net:23901"
              "tls://yg-sin.magicum.net:23900"
            ];
            MulticastInterfaces = [
              {
                Regex = ".*";  
                Beacon = true; 
                Listen = true; 
                Port = 9001;   
              }
            ];
          };
        };
      }; 
    }; 
  };
}

