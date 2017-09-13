{...}:
# build openstack image:
# $ nix-build '<nixpkgs/nixos>' -A config.system.build.novaImage --arg configuration "{ imports = [ ./nova-image.nix ]; }"
{
  imports = [
    <nixpkgs/nixos/maintainers/scripts/openstack/nova-image.nix>
    ./base-config.nix
  ];

  # Automatically log in at the virtual consoles.
  services.mingetty.autologinUser = "root";
  # Some more help text.
  services.mingetty.helpLine = ''
    The "root" account has an empty password.
  '';
   # Allow the user to log in as root without a password.
  users.extraUsers.root.initialHashedPassword = "";
}
