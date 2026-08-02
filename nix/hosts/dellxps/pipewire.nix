# Dell XPS 9510 speaker distortion fix.
#
# (1) Issue.
# Playing audio through the built-in speakers produces severe distortion in the
# 300Hz-4kHz range.
# The distortion is especially noticeable on vocals, speech, and instruments in
# the midrange.
#
# (2) How it appears on a sound sweep test.
# A sine sweep from 20Hz to 20kHz played through the built-in speakers sounds
# clean below ~150Hz and above ~4kHz, but in the 300Hz-4kHz range the output
# contains loud parasitic tones — most prominently a harsh peak around 10kHz —
# that track the sweep frequency.
# This is a textbook intermodulation distortion (IMD) signature: a driver being
# fed frequencies it cannot reproduce generates harmonic and intermodulation
# artifacts far above its mechanical bandwidth.
#
# (3) Root cause.
# The Dell XPS 9510 has a two-way speaker system: tweeters (driven by a Class-D
# amplifier on the ALC289 codec) and a woofer (TAS2770 amplifier, a separate IC).
# On Windows, Waves MaxxAudio applies a software crossover: a low-pass signal goes
# to the woofer and a high-pass signal goes to the tweeters.
# On Linux, the `ALC289_FIXUP_DUAL_SPK` kernel quirk (sound/pci/hda/patch_realtek.c)
# calls `alc285_fixup_speaker2_to_dac1()`, which hard-wires the woofer pin (node 0x17)
# to the same DAC (node 0x02, stream 1) as the tweeters — the only stereo DAC exposed
# by the SOF topology (`sof-hda-generic.tplg`, pipeline PIPELINE.1.HDA0.OUT → PCM0P). # typos: ignore
# Both drivers therefore receive the same full-range FL/FR signal with no crossover.
# The TAS2770 woofer amp cannot handle frequencies above ~200Hz and produces severe
# intermodulation distortion when driven with midrange content.
#
# (4) Fix.
# Two complementary measures are applied:
#   a. The woofer is disabled at boot via a systemd one-shot service that clears the
#      `Bass Speaker Playback Switch` ALSA control (`amixer cset name='Bass Speaker
#      Playback Switch' off,off`).
#      This control is only available with the SOF DSP driver, so `snd_intel_dspcfg.
#      dsp_driver=3` is added to kernel parameters to force SOF instead of snd_hda_intel. # typos: ignore
#   b. A PipeWire filter-chain module creates a virtual speaker sink with a biquad
#      low-shelf boost (+4dB at 120Hz, Q=0.7) and routes it to the hardware sink.
#      This compensates for the lost bass output that the woofer would have provided.
#      The virtual sink is given a higher session priority (1100 vs 1000) so that
#      applications default to it rather than the raw hardware sink.
#
# (5) Why we cannot fix it without disabling the woofer.
# A true crossover (high-pass to tweeters, low-pass to woofer) would require two
# independent PCM streams — one per driver.
# The SOF topology exposes only a single stereo PCM for speaker output (PCM0P).
# There is no separate HDA stream, DAC, or mixer path for the woofer; # typos: ignore
# the codec routes both pins to the same DAC unconditionally via the kernel quirk.
# PipeWire and ALSA see a single FL/FR sink with no way to address the woofer
# independently.
# Even on Windows, the crossover is done entirely in Waves MaxxAudio software on
# the same single PCM — there is no hardware crossover.
# Without a separate stream, any filter applied to the sink affects both drivers
# equally, making a crossover impossible.
# The only viable fix on Linux is to silence the woofer and compensate with EQ on
# the tweeter path.
{ lib, pkgs, ... }:

{
  # Force the SOF DSP driver so the `Bass Speaker Playback Switch` control exists (see 4a above).
  boot.kernelParams = [ "snd_intel_dspcfg.dsp_driver=3" ];

  # Bass shelf EQ to compensate for the disabled woofer (see 4b above).
  services.pipewire.extraConfig.pipewire."99-dell-xps-speaker-eq" = {
    "context.modules" = [
      {
        name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "Dell XPS Speaker EQ";
          "media.name" = "Dell XPS Speaker EQ";
          "filter.graph" = {
            nodes = [
              {
                type = "builtin";
                name = "eq_bass_L";
                label = "bq_lowshelf";
                control = {
                  "Freq" = 120.0;
                  "Q" = 0.7;
                  "Gain" = 4.0;
                };
              }
              {
                type = "builtin";
                name = "eq_bass_R";
                label = "bq_lowshelf";
                control = {
                  "Freq" = 120.0;
                  "Q" = 0.7;
                  "Gain" = 4.0;
                };
              }
            ];
            inputs = [
              "eq_bass_L:In"
              "eq_bass_R:In"
            ];
            outputs = [
              "eq_bass_L:Out"
              "eq_bass_R:Out"
            ];
          };
          "audio.channels" = 2;
          "audio.position" = [
            "FL"
            "FR"
          ];
          "capture.props" = {
            "node.name" = "effect_input.dell-xps-speaker-eq";
            "media.class" = "Audio/Sink";
            "node.description" = "Dell XPS Speaker (EQ)";
            "priority.session" = 1100;
          };
          "playback.props" = {
            "node.name" = "effect_output.dell-xps-speaker-eq";
            "node.passive" = true;
            "node.target" = "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink"; # typos: ignore
          };
        };
      }
    ];
  };

  # Disable the woofer at boot (see 4a above).
  systemd.services.disable-dell-xps-woofer = {
    description = "Disable Dell XPS 9510 woofer (Bass Speaker Playback Switch)";
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${lib.getExe' pkgs.alsa-utils "amixer"} -c sofhdadsp cset name='Bass Speaker Playback Switch' off,off";
    };
  };
}
