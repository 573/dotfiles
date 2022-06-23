# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./modules/sshd.nix

    ../modules/gnome.nix
    ../modules/rock-rdp.nix
    ../modules/hass-agent.nix
    ../modules/ip-update.nix
    ../modules/packages.nix
    ../modules/powertop.nix
    ../modules/promtail.nix
    ../modules/users.nix
    ../modules/zfs.nix
    ../modules/tracing.nix
    ../modules/telegraf.nix
    ../modules/pipewire.nix
  ];

  boot.zfs.requestEncryptionCredentials = ["zroot/root"];
  boot.zfs.enableUnstable = true;
  boot.loader.systemd-boot.enable = true;
  # when installing toggle this
  boot.loader.efi.canTouchEfiVariables = false;

  users.users.shannan = {
    isNormalUser = true;
    home = "/home/shannan";
    extraGroups = ["wheel" "plugdev" "adbusers" "input" "kvm" "networkmanager"];
    shell = "/run/current-system/sw/bin/zsh";
    uid = 1001;
    inherit (config.users.users.joerg) openssh;
  };
  networking.hostName = "bernie";
  networking.hostId = "ac174b52";

  networking.networkmanager.enable = true;
  time.timeZone = null;
  services.geoclue2.enable = true;
  i18n.defaultLocale = "en_DK.UTF-8";

  programs.vim.defaultEditor = true;

  environment.systemPackages = with pkgs; [
    #(pkgs.callPackage (pkgs.fetchFromGitHub {
    #    owner = "Mic92";
    #    repo = "tts-app";
    #    rev = "0.0.2";
    #    sha256 = "sha256-QnGYwN3+Qul2jItK7NvKMc6rbtT+f1qXJF542s3EvTQ=";
    #  }) {
    #    defaultHost = "tts.r";
    #    defaultPort = "80";
    #  })
    firefox-wayland
    chromium
    celluloid
    vscode
    mpv
    inkscape
    yt-dlp
    calibre
    ubuntu_font_family
    aspell
    aspellDicts.de
    aspellDicts.fr
    aspellDicts.en
    hunspell
    hunspellDicts.en-gb-ise
    calibre
    evolution
    signal-desktop
    gimp
    wl-clipboard
    poppler_utils
    focuswriter
  ];

  documentation.doc.enable = false;
  documentation.man.enable = false;

  services.openssh.enable = true;
  services.printing = {
    enable = true;
    browsing = true;
    drivers = [pkgs.gutenprint];
  };
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  system.stateVersion = "21.11";
}
