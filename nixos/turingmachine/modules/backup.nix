{
  config,
  lib,
  pkgs,
  ...
}:
with builtins; let
  backupPath = "il1dsenixosbk@eva.r:/mnt/backup/turingmachine";
in {
  sops.secrets.borgbackup = {};
  sops.secrets.ssh-borgbackup = {};

  services.borgbackup.jobs.turingmachine = {
    paths = [
      "/home"
      "/etc"
      "/var"
      "/root"
    ];
    # runs borg list, which is really slow over sshfs
    doInit = false;
    repo = backupPath;
    exclude = [
      "*.pyc"
      "/home/*/.direnv"
      "/home/*/.emacs.d"
      "/home/*/.cache"
      "/home/*/.cargo"
      "/home/*/.npm"
      "/home/*/.m2"
      "/home/*/.gradle"
      "/home/*/.opam"
      "/home/*/.clangd"
      "/home/*/Android"
      "/home/*/.config/Ferdi/Partitions"
      "/home/*/.mozilla/firefox/*/storage"
      "/home/joerg/Musik/podcasts"
      "/home/joerg/gPodder/Downloads"
      "/home/joerg/sync"
      "/home/joerg/Videos"
      "/home/joerg/git/linux/*.qcow2"
      "/home/joerg/git/OSX-KVM/mac_hdd_ng.img"
      "/home/joerg/mnt"
      "/var/lib/containerd"
      "/var/log/journal"
      "/var/cache"
      "/var/tmp"
      "/var/log"
    ];
    encryption = {
      mode = "repokey";
      passCommand = "cat ${config.sops.secrets.borgbackup.path}";
    };
    preHook = ''
      set -x
      eval $(ssh-agent)
      ssh-add ${config.sops.secrets.ssh-borgbackup.path}
    '';
    postHook = ''
      cat > /var/log/telegraf/borgbackup-turingmachine <<EOF
      task,frequency=daily last_run=$(date +%s)i,state="$([[ $exitStatus == 0 ]] && echo ok || echo fail)"
      EOF
    '';

    prune.keep = {
      within = "1d"; # Keep all archives from the last day
      daily = 7;
      weekly = 4;
      monthly = 3;
    };
  };

  systemd.services.break-borgbackup-lock = {
    path = [pkgs.borgbackup pkgs.openssh];
    script = ''
      eval $(ssh-agent)
      ssh-add ${config.sops.secrets.ssh-borgbackup.path}
      export BORG_PASSCOMMAND='cat /run/secrets/borgbackup'
      export BORG_REPO='il1dsenixosbk@eva.r:/mnt/backup/turingmachine'
      borg break-lock
    '';
  };

  systemd.timers.borgbackup-job-turingmachine = {
    timerConfig.OnCalendar = lib.mkForce "13:00:00";
  };

  systemd.services.borgbackup-job-turingmachine.serviceConfig.ReadWritePaths = [
    "/var/log/telegraf"
  ];
}
