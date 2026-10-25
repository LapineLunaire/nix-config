# Follow Sparkle's NTS-synchronised clock through PTP over KVM.
# Without a time source, a guest sets its clock only at boot, then drifts and misses host corrections.
{
  boot.kernelModules = ["ptp_kvm"];

  services.chrony = {
    enable = true;
    servers = [];
    # The guest RTC is emulated, so trimming it has no effect.
    enableRTCTrimming = false;
    # Step whenever the clock is off by more than a second, such as after a paused guest resumes.
    makestep.enable = false;
    extraConfig = ''
      refclock PHC /dev/ptp_kvm poll 2
      makestep 1 -1
    '';
  };
}
