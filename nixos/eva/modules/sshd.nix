{
  imports = [../../modules/sshd.nix];
  services.openssh.extraConfig = ''
    HostCertificate ${./eva-cert.pub}
    ListenAddress 10.243.29.185
    ListenAddress [42:0:3c46:8a42:2b1:5ef8:7562:676a]
  '';
  services.openssh.startWhenNeeded = false;
}
