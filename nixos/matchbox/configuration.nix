{ pkgs, ... }: {

  imports = [
    ../modules/users.nix
    ../modules/mosh.nix
    ../modules/tor-ssh.nix
    ../modules/telegraf.nix
    ../modules/rpi3.nix
    ../modules/promtail.nix

    ./modules/borgbackup.nix
    ./modules/samba.nix
    ./modules/rsyncd.nix
    ./modules/sops.nix
  ];

  documentation.enable = false;
  boot.initrd.includeDefaultModules = false;

  fileSystems."/mnt/hdd" = {
    device = "UUID=1d377ab7-65ca-492d-9ea4-620034230192";
    fsType = "ext4";
    options = [ "defaults" "nofail" "x-systemd.device-timeouts=2" ];
  };

  networking.retiolum.ipv6 = "42:0:3c46:6745:adf4:a844:26c4:bf91";

  networking.hostName = "matchbox";

  time.timeZone = "UTC";

  environment.systemPackages = with pkgs; [
    tmux
    htop
    iotop
    tcpdump
    strace
    ethtool
    usbutils
    vim
  ];

  system.stateVersion = "18.09";
  networking.dhcpcd.enable = true;
}
