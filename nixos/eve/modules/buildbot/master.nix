{ config, lib, pkgs, ... }:

let
  # TODO: make this an option

  # https://github.com/organizations/numtide/settings/applications
  # Application name: BuildBot
  # Homepage URL: https://buildbot.numtide.com
  # Authorization callback URL: https://buildbot.numtide.com/auth/login
  # oauth_token:  2516248ec6289e4d9818122cce0cbde39e4b788d
  buildbotDomain = "buildbot.thalheim.io";
  githubOauthId = "8708f4aa8c622b010660";
in
{
  services.buildbot-master = {
    enable = true;
    masterCfg = "${./.}/master.py";
    dbUrl = "postgresql://@/buildbot";
    pythonPackages = ps: [
      ps.requests
      ps.treq
      ps.psycopg2
      ps.buildbot-worker
    ];
  };

  systemd.services.buildbot-master = {
    environment = {
      PORT   = "1810";
      DB_URL = config.services.buildbot-master.dbUrl;
      # Github app used for the login button
      GITHUB_OAUTH_ID = githubOauthId;
      GITHUB_ORG = "Mic92";
      GITHUB_REPO = "dotfiles";

      BUILDBOT_URL = "https://${buildbotDomain}/";
      BUILDBOT_GITHUB_USER = "mic92-buildbot";
      # comma seperated list of users that are allowed to login to buildbot and do stuff
      GITHUB_ADMINS = "Mic92";
    };
    serviceConfig = {
      # in master.py we read secrets from $CREDENTIALS_DIRECTORY
      LoadCredential = [
        "github-token:${config.sops.secrets.github-token.path}"
        "github-webhook-secret:${config.sops.secrets.github-webhook-secret.path}"
        "github-oauth-secret:${config.sops.secrets.github-oauth-secret.path}"
        "buildbot-nix-workers:${config.sops.secrets.buildbot-nix-workers.path}"
        "cachix-name:${config.sops.secrets.cachix-name.path}"
        "cachix-token:${config.sops.secrets.cachix-token.path}"
      ];
    };
  };
  sops.secrets = {
    github-token = {};
    github-webhook-secret = {};
    github-oauth-secret = {};
    buildbot-nix-workers = {};
    cachix-name = {};
    cachix-token = {};
  };

  services.postgresql = {
    ensureDatabases = ["buildbot"];
    ensureUsers = [
      {
        name = "buildbot";
        ensurePermissions."DATABASE buildbot" = "ALL PRIVILEGES";
      }
    ];
  };

  services.nginx.virtualHosts.${buildbotDomain} = {
    forceSSL = true;
    useACMEHost = "thalheim.io";
    locations."/".proxyPass = "http://127.0.0.1:1810/";
    locations."/sse" = {
      proxyPass = "http://127.0.0.1:1810/sse/";
      # proxy buffering will prevent sse to work
      extraConfig = "proxy_buffering off;";
    };
    locations."/ws" = {
      proxyPass = "http://127.0.0.1:1810/ws";
      proxyWebsockets = true;
      # raise the proxy timeout for the websocket
      extraConfig = "proxy_read_timeout 6000s;";
    };

    # In this directory we store the lastest build store paths for nix attributes
    locations."/nix-outputs".root = "/var/www/buildbot/";
  };

  # Allow buildbot-master to write to this directory
  systemd.tmpfiles.rules = [
    "d /var/www/buildbot/nix-outputs 0755 buildbot buildbot - -"
  ];
}
