{ pkgs, ... }:

# Diagnostic tools that have to exist *before* something breaks. They are
# shared on purpose: the workstation uses them to look outward at the LAN, and
# the servers use the same set to look inward at themselves, so keeping them in
# one module means a new host gets them by importing the profile.
{
  environment.systemPackages = with pkgs; [
    bind.dnsutils # dig: query one specific resolver instead of the local one
    mtr # per-hop loss/latency; ping and traceroute lie on flaky WiFi
    tcpdump # packet-level proof of which side drops the traffic
    iperf3 # real throughput and loss over WiFi, LAN and NFS
    openssl # TLS chains, SANs and handshakes by hand
    ethtool # link speed, errors and driver state (wlo1, enp*/eno*)
    smartmontools # smartctl: disk health before trusting a disk
    nfs-utils # showmount: what the NFS server actually exports
    postgresql # psql: ad-hoc queries against the Immich database
    ncdu # where the disk went
    lsof # who holds that port or file
    strace # what a process is doing while it hangs
  ];
}
