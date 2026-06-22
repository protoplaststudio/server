{ ... }:
{
  flake.nixosModules.server-configuration = { pkgs, config, lib, ... }: 
  {
    
    nix = {
      settings = { 
        experimental-features = [ 
          "nix-command"
          "flakes"
          "pipe-operators"
        ];
      };
    };
    nixpkgs.config.allowUnfree = true;
    programs.nix-ld.enable = true;
    system.stateVersion = "26.05";
    time.timeZone = "Asia/Kolkata";
    services.timesyncd.enable = true;
    i18n.defaultLocale = "en_US.UTF-8";
    console.keyMap = "us";
    virtualisation.docker = {
      enable = true;
      # Tell Docker to live entirely inside your persistent vault
      daemon.settings = {
        data-root = "/mnt/data/docker";
      };
    };
    services = {
      openssh.enable = true;
      pipewire = {
        enable = true;
        pulse.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        wireplumber.enable = true; 
      };
      avahi = {
        enable = true;
        nssmdns4 = true; 
      };
      
      postgresql = {
        enable = true;
        package = pkgs.postgresql_18;
        dataDir = "/mnt/data/postgresql/data";
        
        settings = {
          # Use the wildcard to avoid the Docker race condition on boot
          listen_addresses = lib.mkForce "*";
        };
  
        authentication = pkgs.lib.mkOverride 10 ''
          # TYPE  DATABASE        USER            ADDRESS                 METHOD
          
          # 1. ALLOW SYSTEM ADMIN: The 'postgres' superuser must use OS-level 'peer' auth
          local   all             postgres                                peer
          
          # 2. ALLOW LOCAL SCRIPTS: Let your systemd scripts (like tb-init) connect locally
          local   all             all                                     trust
          
          # 3. LOCK DOWN NETWORK: Require strict passwords for local TCP
          host    all             all             samehost                scram-sha-256
          
          # 4. LOCK DOWN DOCKER: Require strict passwords for containers
          host    all             all             172.17.0.0/16           scram-sha-256
        '';
      };
    };

    systemd.tmpfiles.rules = [
      "d /mnt/data/postgresql 0750 postgres postgres -"
      "d /mnt/data/postgresql/data 0700 postgres postgres -"      
      "d /mnt/data/docker 0711 root root -"
    ];
    
    environment.variables = {
      EDITOR = "nano"; VISUAL = "nano"; 
    };
    environment.systemPackages = with pkgs; [
      age age-plugin-tpm 
      bind
      cloudflared curl
      droidcam docker
      git gptfdisk
      home-manager htop
      jq
      mtr
      pciutils
      sbctl sops ssh-to-age
      tcpdump tree
      util-linux unzip
      vim
      wget
      yggdrasil
    ];
    networking = {
      
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
    networking.firewall = {
      trustedInterfaces = [ "docker0" ]; 
      allowedTCPPorts = [ 53535 9001 ];
      allowedUDPPorts = [ 53535 9001 ];
    };
  };
}

