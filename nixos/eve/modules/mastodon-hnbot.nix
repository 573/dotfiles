{ pkgs, config, ... }: {

  systemd.services.mastodon-hnbot = {
    path = [
      pkgs.nur.repos.mic92.mastodon-hnbot
    ];
    script = ''
      exec hnbot \
        --points 50 \
        https://toot.matereal.eu \
        joerg.hackernews50@thalheim.io \
        "$(cat ${config.sops.secrets.hnbot-password.path})"
    '';
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = [
        "/var/lib/mastodon-hnbot"
      ];
      PermissionsStartOnly = true;
      ExecStopPost = pkgs.writeShellScript "update-health" ''
        cat > /var/log/telegraf/mastadon-hnbot <<EOF
        task,frequency=daily last_run=$(date +%s)i,state="$([[ $EXIT_CODE == exited ]] && echo ok || echo fail)"
        EOF
      '';
      StateDirectory = [ "mastodon-hnbot" ];
      User = "mastodon-hnbot";
    };
  };

  systemd.timers.mastodon-hnbot = {
    description = "Post hackernews posts to mastodon";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnUnitActiveSec = "5min";
      OnBootSec = "5min";
    };
  };

  users.users.mastodon-hnbot = {
    isSystemUser = true;
    createHome = true;
    home = "/var/lib/mastodon-hnbot";
    group = "mastodon-hnbot";
  };
  users.groups.mastodon-hnbot = { };

  sops.secrets.hnbot-password.owner = "mastodon-hnbot";
}
