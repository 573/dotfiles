{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    #../modules/libvirt.nix
    ./modules/caddy.nix
    ./modules/dice.nix
    ./modules/eve-rdp.nix
    ./modules/backup.nix
    ./modules/hass-agent.nix
    ./modules/nfs.nix
    ./modules/remote-builder.nix
    #./modules/minidlna.nix
    ./modules/networkmanager.nix
    ./modules/packages.nix
    ./modules/gnome-pim.nix
    ./modules/sops.nix
    ./modules/sshd.nix
    ./modules/cntr.nix
    #./modules/minidlna.nix

    #../modules/podman.nix
    ../modules/pipewire.nix
    ../modules/jarvis-rdp.nix
    ../modules/ip-update.nix
    #../modules/iwd.nix
    ../modules/dnsmasq.nix
    ../modules/promtail.nix
    ../modules/powertop.nix
    #../modules/macos-kvm.nix
    ../modules/mosh.nix
    ../modules/networkd.nix
    ../modules/wireguard.nix
    ../modules/tracing.nix
    ../modules/telegraf.nix
    #./kde.nix
    #../modules/samba-dl.nix
    ../modules/sway.nix
    #../modules/awesome.nix
    #../modules/gnome.nix
    ../modules/pki
    #../modules/yubikey.nix
    ../modules/zfs.nix
    ../modules/users.nix
    #../modules/k3s/server.nix
  ];

  #services.udev.packages = [ pkgs.platformio ];

  hardware.video.hidpi.enable = true;

  boot = {
    zfs.requestEncryptionCredentials = ["zroot/root"];

    loader.systemd-boot.enable = true;
    # when installing toggle this
    loader.efi.canTouchEfiVariables = false;

    # It may leak your data, but look how FAST it is!1!!
    # https://make-linux-fast-again.com/
    kernelParams = [
      "noibrs"
      "noibpb"
      "nopti"
      "nospectre_v2"
      "nospectre_v1"
      "l1tf=off"
      "nospec_store_bypass_disable"
      "no_stf_barrier"
      "mds=off"
      "tsx=on"
      "tsx_async_abort=off"
      "mitigations=off"
    ];
  };

  networking.hostName = "turingmachine";

  console.keyMap = "us";

  i18n.defaultLocale = "en_DK.UTF-8";

  # Manual timezones, also see modules/networkmanager.py
  time.timeZone = null;

  services = {
    gpm.enable = true;
    upower.enable = true;
    openssh = {
      enable = true;
      forwardX11 = true;
    };

    avahi.enable = true;
    avahi.nssmdns = true;

    printing = {
      enable = true;
      browsing = true;
      drivers = [pkgs.gutenprint]; # pkgs.hplip
    };

    logind.extraConfig = ''
      LidSwitchIgnoreInhibited=no
      HandlePowerKey=ignore
    '';
    journald.extraConfig = "SystemMaxUse=1G";
  };

  systemd.services.audio-off = {
    description = "Mute audio before suspend";
    wantedBy = ["sleep.target"];
    serviceConfig = {
      Type = "oneshot";
      Environment = "XDG_RUNTIME_DIR=/run/user/1000";
      User = "joerg";
      RemainAfterExit = "yes";
      ExecStart = "${pkgs.pamixer}/bin/pamixer --mute";
    };
  };

  virtualisation = {
    #anbox.enable = true;
    #lxc.enable = true;
    #lxd.enable = true;
    #rkt.enable = true;
    #rkt.enable = true;
    virtualbox.host.enable = false;
    docker.enable = true;
    docker.storageDriver = "zfs";
    docker.extraOptions = "--storage-opt=zfs.fsname=zroot/docker";
  };

  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -p tcp -d 88.99.244.96 --dport 53 -j DNAT --to-destination 172.17.0.1
  '';

  environment.etc."docker/daemon.json".text = builtins.toJSON {
    dns = ["8.8.8.8" "8.8.4.4"];
  };

  fonts.fontDir.enable = true;

  environment.variables.SSH_ASKPASS = lib.mkForce "${pkgs.lxqt.lxqt-openssh-askpass}/bin/lxqt-openssh-askpass";
  programs = {
    ssh = {
      startAgent = true;
      askPassword = "${pkgs.lxqt.lxqt-openssh-askpass}/bin/lxqt-openssh-askpass";
      extraConfig = ''
        SendEnv LANG LC_*
      '';
    };
    adb.enable = true;
    bash.enableCompletion = true;
    zsh = {
      enable = true;
      promptInit = "";
    };
  };

  security.audit.enable = false;
  nixpkgs.config = {
    allowUnfree = true;
    android_sdk.accept_license = true;
  };

  services.tor.client.enable = true;

  #services.samba = {
  #  enable = true;
  #  securityType = "user";
  #  enableWinbindd = false;
  #  extraConfig = ''
  #    workgroup = WORKGROUP
  #    server string = smbnix
  #    netbios name = smbnix
  #    security = user
  #    hosts allow = 0.0.0.0/0
  #    guest account = nobody
  #    map to guest = bad user
  #    # Use sendfile() for performance gain
  #    use sendfile = true

  #    # No NetBIOS is needed
  #    disable netbios = true

  #    # Only mangle non-valid NTFS names, don't care about DOS support
  #    mangled names = illegal

  #    # Performance optimizations
  #    socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=65536 SO_SNDBUF=65536

  #    # Disable all printing
  #    load printers = false
  #    disable spoolss = true
  #    printcap name = /dev/null
  #  '';
  #  shares = {
  #    public = {
  #      path = "/home/joerg/web/upload";
  #      browseable = "yes";
  #      "read only" = "no";
  #      "guest ok" = "yes";
  #      "create mask" = "0644";
  #      "directory mask" = "0755";
  #      "force user" = "joerg";
  #      "force group" = "users";
  #    };
  #  };
  #};
  networking.firewall.interfaces."virbr1".allowedTCPPorts = [
    445
    139
  ];
  networking.firewall.interfaces."virbr1".allowedUDPPorts = [
    445
    139
  ];

  system.stateVersion = "18.03";
  networking.extraHosts = ''
    127.0.0.1 app.stagsecurities.com
    127.0.0.1 staging.stagsecurities.com
    2600:1f16:d7a:b302:845b:4213:4451:345b dev01
  '';
}
