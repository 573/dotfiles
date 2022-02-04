{ config, pkgs, lib, ... }: {
  services.gitea = {
    enable = true;
    database = {
      type = "postgres";
      host = "/run/postgresql";
      port = 5432;
    };
    log.level = "Error";
    domain = "git.thalheim.io";
    rootUrl = "https://git.thalheim.io";
    mailerPasswordFile = config.sops.secrets.gitea-mail.path;
    disableRegistration = true;
    settings.mailer = {
      ENABLED = true;
      FROM = "gitea@thalheim.io";
      USER = "gitea@thalheim.io";
      HOST = "mail.thalheim.io:587";
    };
    settings.metrics.ENABLED = true;
    settings.server.DISABLE_ROUTER_LOG = true;
    httpPort = 3002;
  };

  systemd.services.gitea = {
    path = [ pkgs.bash ];
    serviceConfig.LimitNOFILE = 65536;
  };

  systemd.tmpfiles.rules = let
    hooks = pkgs.runCommand "hooks" {
      buildInputs = [ pkgs.bash ];
      nativeBuildInputs = [ pkgs.makeWrapper pkgs.shellcheck ];
    } ''
    install -D -m755 ${./retiolum-hook.sh} $out/bin/retiolum
    install -D -m755 ${./irc-hook.sh} $out/bin/irc-notify
    wrapProgram $out/bin/retiolum \
      --set PATH ${lib.makeBinPath (with pkgs; [ git gnutar coreutils nix coreutils bzip2 jq bash ])}
    wrapProgram $out/bin/irc-notify \
      --set PATH ${lib.makeBinPath (with pkgs; [ git coreutils gnugrep gnused nur.repos.mic92.ircsink bash ])}
    cat > $out/bin/irc-stockholm <<EOF
    #!/usr/bin/env bash
    export GIT_URL=https://git.thalheim.io/Mic92/stockholm
    exec $out/bin/irc-notify --server=irc.r --nick=gitea --target="#xxx"
    EOF
    chmod +x $out/bin/irc-stockholm

    for bin in $out/bin/*; do
      patchShebangs $bin
      shellcheck $bin
    done
  '';
  in [
    "L+ /var/lib/gitea/repositories/mic92/stockholm.git/hooks/post-receive.d/retiolum - - - - ${hooks}/bin/retiolum"
    "L+ /var/lib/gitea/repositories/mic92/stockholm.git/hooks/post-receive.d/irc-stockholm - - - - ${hooks}/bin/irc-stockholm"
  ];

  sops.secrets.gitea-mail.owner = config.systemd.services.gitea.serviceConfig.User;

  nix.settings.allowed-users = [ "gitea" ];

  services.nginx.virtualHosts."git.thalheim.io" = {
    useACMEHost = "thalheim.io";
    forceSSL = true;
    locations."/".extraConfig = ''
      proxy_pass http://localhost:3002;
    '';
  };
}
