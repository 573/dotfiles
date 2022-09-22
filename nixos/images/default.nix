{self, ...}: {
  perSystem = {
    inputs',
    pkgs,
    self',
    ...
  }: let
    inherit (self.inputs) nixos-generators nur nixpkgs;
    defaultModule = {config, ...}: {
      imports = [
        ./base-config.nix
        self.inputs.nur.nixosModules.nur
      ];
      _module.args.inputs = self.inputs;
      system.stateVersion = config.system.nixos.version;
    };
  in {
    packages = {
      # nix build '.#kexec'
      #kexec = nixos-generators.nixosGenerate {
      #  inherit pkgs;
      #  modules = [
      #    defaultModule
      #    ./kexec.nix
      #  ];
      #  format = "kexec";
      #};

      #kexec-aarch64 = nixos-generators.nixosGenerate {
      #  pkgs = nixpkgs.legacyPackages.aarch64-linux;
      #  modules = [
      #    defaultModule
      #    ./kexec.nix
      #  ];
      #  format = "kexec";
      #};

      matchbox-image = self.nixosConfigurations.matchbox.config.system.build.sdImage;

      sd-image = nixos-generators.nixosGenerate {
        inherit pkgs;
        modules = [
          defaultModule
        ];
        format = "install-iso";
      };

      netboot = pkgs.callPackage ./netboot.nix {
        inherit pkgs;
        inherit (nixpkgs.lib) nixosSystem;
        extraModules = [
          defaultModule
        ];
      };

      netboot-pixie-core = pkgs.callPackage ./netboot-pixie-core.nix {
        inherit (self'.packages) netboot;
      };

      nspawn-template = import ./nspawn-template.nix {
        inherit nixos-generators;
        inherit pkgs;
      };
    };
  };
}
