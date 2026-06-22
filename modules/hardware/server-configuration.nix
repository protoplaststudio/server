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
    virtualisation.docker.enable = true;
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
          # Listen on localhost and the Docker bridge specifically
          listen_addresses = lib.mkForce "127.0.0.1, 172.17.0.1";
        };
  
        authentication = pkgs.lib.mkOverride 10 ''
          # TYPE  DATABASE        USER            ADDRESS                 METHOD
           local   all             all                                     trust
         
           # Matches any address currently bound to this host's own interfaces —
           # no need to hardcode LAN subnet, VPN subnet, etc.
           host    all             all             samehost                trust
         
           # Docker container subnet — this is Docker's own internal addressing,
           # not your LAN, so it's not the kind of hardcoding you're trying to avoid.
           host    all             all             172.17.0.0/16            trust
        '';
      };
    };

    systemd.tmpfiles.rules = [
      # The 'z' type ensures permissions are applied recursively 
      # and sets the folder up before the service starts.
      "d /mnt/data/postgresql 0750 postgres postgres -"
      "d /mnt/data/postgresql/data 0700 postgres postgres -"
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

