{...}: {
  additions = final: _prev: import ../pkgs final.pkgs;

  modifications = final: prev: {
    discord = prev.discord.override {
      commandLineArgs = "--force-device-scale-factor=1";
    };

    ffmpeg-full = prev.ffmpeg-full.override {
      withUnfree = true;
    };

    mpv = prev.mpv.override {
      mpv-unwrapped = prev.mpv-unwrapped.override {
        ffmpeg = final.ffmpeg-full;
      };
    };

    yt-dlp = prev.yt-dlp.override {
      ffmpeg-headless = final.ffmpeg-full;
    };
  };
}
