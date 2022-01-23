{ pkgs, lib, ... }:
{
  imports = [
    ./xserver.nix
    ./high-dpi.nix
    ./flameshot.nix
  ];
  services.xserver.windowManager.i3.enable = true;
  services.xserver.displayManager.defaultSession = "none+i3";

  environment.systemPackages = with pkgs; [
    xorg.xmodmap
    firefox
    chromium
    # autostart stuff
    dex
    brightnessctl
    pavucontrol
    lightlocker
    lxappearance
    scrot
    evince
    rofi
    gnome3.eog
    libnotify
    dunst
    pamixer
    mpc_cli
    clipit
    picom
    xclip
    xorg.xev
    xorg.xprop
    alacritty
    (i3pystatus.override {
      extraLibs = with python3.pkgs; [ keyrings-alt paho-mqtt ];
    })
    gnome3.networkmanagerapplet
    gnome3.file-roller
    gnome3.nautilus
  ];

  services.gvfs.enable = true;

  services.autorandr.enable = true;
  programs.nm-applet.enable = true;
}
