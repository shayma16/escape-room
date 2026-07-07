# Feedback round 1 audio generation (2026-07-07).
#
# 1:1 PowerShell/C# port of the audio-synthesis functions in tools/build_game_assets.py
# (gen_sfx additions + the re-written quieter gen_ambients). The Python tool remains the
# canonical pipeline definition, but this development machine has no Python runtime
# (same constraint as the BUG-004 staging pass), so the shipped WAVs are produced by
# this port. All output is wholly original synthesized audio (sine/noise/envelope
# math) — no sampled or third-party material, hence no license obligations.
#
# Usage: pwsh tools/generate_audio_round1.ps1
# Writes into EscapeRoom/Resources/Audio/.

$ErrorActionPreference = "Stop"
$outDir = Join-Path $PSScriptRoot "..\EscapeRoom\Resources\Audio"
$outDir = (Resolve-Path $outDir).Path

Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.IO;

public static class AudioGen
{
    public const int SR = 22050;

    public static void WriteWav(string path, double[] samples)
    {
        using (var fs = new FileStream(path, FileMode.Create))
        using (var w = new BinaryWriter(fs))
        {
            int n = samples.Length;
            int dataLen = n * 2;
            w.Write(new[] { 'R', 'I', 'F', 'F' });
            w.Write(36 + dataLen);
            w.Write(new[] { 'W', 'A', 'V', 'E' });
            w.Write(new[] { 'f', 'm', 't', ' ' });
            w.Write(16);
            w.Write((short)1);        // PCM
            w.Write((short)1);        // mono
            w.Write(SR);
            w.Write(SR * 2);          // byte rate
            w.Write((short)2);        // block align
            w.Write((short)16);       // bits
            w.Write(new[] { 'd', 'a', 't', 'a' });
            w.Write(dataLen);
            foreach (var s in samples)
            {
                double c = Math.Max(-1.0, Math.Min(1.0, s));
                w.Write((short)(c * 32000));
            }
        }
    }

    public static double Env(int i, int n, double a, double r)
    {
        int at = Math.Max(1, (int)(n * a));
        int rt = Math.Max(1, (int)(n * r));
        if (i < at) return (double)i / at;
        if (i > n - rt) return Math.Max(0.0, (double)(n - i) / rt);
        return 1.0;
    }

    // One-pole lowpassed white noise (mirrors lp_noise in the Python tool).
    public static double[] LpNoise(int n, double cutoff, int seed, double gain)
    {
        var rng = new Random(seed);
        double a = Math.Exp(-2 * Math.PI * cutoff / SR);
        double y = 0.0;
        var outp = new double[n];
        for (int i = 0; i < n; i++)
        {
            y = a * y + (1 - a) * (rng.NextDouble() * 2 - 1);
            outp[i] = y * gain;
        }
        return outp;
    }

    public static double[] Sine(int n, double f0, double f1, double amp)
    {
        var outp = new double[n];
        double ph = 0.0;
        for (int i = 0; i < n; i++)
        {
            double f = f0 + (f1 - f0) * ((double)i / n);
            ph += 2 * Math.PI * f / SR;
            outp[i] = Math.Sin(ph) * amp;
        }
        return outp;
    }

    // Crossfade tail into head for a seamless loop (mirrors loopable()).
    public static double[] Loopable(double[] samples, double fade)
    {
        int nf = (int)(fade * SR);
        int n = samples.Length;
        var outp = new List<double>(n);
        for (int i = 0; i < n - nf; i++) outp.Add(samples[i]);
        for (int i = 0; i < nf; i++)
        {
            double t = (double)i / nf;
            outp.Add(samples[n - nf + i] * (1 - t) + samples[i] * t);
        }
        return outp.ToArray();
    }

    public static void GenerateAll(string dir)
    {
        int n; double[] ns, tone; double[] outp;

        // page turn: two overlapping soft paper swishes
        n = (int)(0.22 * SR);
        ns = LpNoise(n, 1800, 21, 2.2);
        outp = new double[n];
        for (int i = 0; i < n; i++)
        {
            double g1 = i < 0.10 * SR ? Math.Sin(Math.PI * Math.Min(1.0, i / (0.10 * SR))) : 0.0;
            double j = i - (int)(0.06 * SR);
            double g2 = (j > 0 && j < 0.14 * SR) ? Math.Sin(Math.PI * Math.Min(1.0, j / (0.14 * SR))) : 0.0;
            outp[i] = ns[i] * (g1 * 0.5 + g2 * 0.4) * 0.5;
        }
        WriteWav(Path.Combine(dir, "sfx-page.wav"), outp);

        // stone tile press
        n = (int)(0.22 * SR);
        var thud = Sine(n, 180, 120, 0.8);
        ns = LpNoise(n, 420, 22, 1.4);
        outp = new double[n];
        for (int i = 0; i < n; i++)
            outp[i] = (thud[i] + ns[i] * 0.4) * Math.Exp(-i / (0.06 * SR)) * 0.7;
        WriteWav(Path.Combine(dir, "sfx-stone.wav"), outp);

        // ratchet tick
        n = (int)(0.08 * SR);
        ns = LpNoise(n, 1400, 23, 2.0);
        tone = Sine(n, 520, 520, 0.25);
        outp = new double[n];
        for (int i = 0; i < n; i++)
            outp[i] = (ns[i] * 0.6 + tone[i]) * Math.Exp(-i / (0.014 * SR)) * 0.5;
        WriteWav(Path.Combine(dir, "sfx-tick.wav"), outp);

        // mirror detent grind
        n = (int)(0.35 * SR);
        ns = LpNoise(n, 300, 24, 5.0);
        var rough = LpNoise(n, 28, 25, 1.0);
        outp = new double[n];
        for (int i = 0; i < n; i++)
            outp[i] = ns[i] * (0.5 + 0.5 * Math.Abs(rough[i])) * Env(i, n, 0.15, 0.35) * 0.5;
        WriteWav(Path.Combine(dir, "sfx-grind.wav"), outp);

        // bellows air puff
        n = (int)(0.45 * SR);
        ns = LpNoise(n, 1000, 26, 2.6);
        outp = new double[n];
        for (int i = 0; i < n; i++)
            outp[i] = ns[i] * Env(i, n, 0.30, 0.50) * 0.55;
        WriteWav(Path.Combine(dir, "sfx-bellows.wav"), outp);

        // ladle stir swish
        n = (int)(0.5 * SR);
        ns = LpNoise(n, 600, 27, 3.0);
        outp = new double[n];
        for (int i = 0; i < n; i++)
        {
            double s = Math.Sin(Math.PI * i / (double)n);
            outp[i] = ns[i] * s * s * 0.5;
        }
        WriteWav(Path.Combine(dir, "sfx-stir.wav"), outp);

        // rug/cloth slide
        n = (int)(0.4 * SR);
        ns = LpNoise(n, 800, 28, 2.6);
        outp = new double[n];
        for (int i = 0; i < n; i++)
            outp[i] = ns[i] * Math.Sin(Math.PI * Math.Min(1.0, i / (n * 0.85))) * 0.45;
        WriteWav(Path.Combine(dir, "sfx-cloth.wav"), outp);

        // wood slide/settle: two soft wooden pulses
        n = (int)(0.3 * SR);
        ns = LpNoise(n, 900, 29, 2.2);
        tone = Sine(n, 200, 200, 0.5);
        outp = new double[n];
        for (int i = 0; i < n; i++)
        {
            double g = 0.0;
            foreach (double t0 in new[] { 0.02, 0.15 })
            {
                double j = i - (int)(t0 * SR);
                if (j > 0) g += Math.Exp(-j / (0.035 * SR));
            }
            outp[i] = (ns[i] * 0.5 + tone[i] * 0.5) * g * 0.5;
        }
        WriteWav(Path.Combine(dir, "sfx-wood.wav"), outp);

        // level-entry swell (F-002)
        n = (int)(7.0 * SR);
        ns = LpNoise(n, 250, 30, 4.0);
        var low = Sine(n, 58, 58, 0.10);
        outp = new double[n];
        for (int i = 0; i < n; i++)
        {
            double t = (double)i / SR;
            double swell = t < 4.0 ? Math.Sin(Math.PI * Math.Min(1.0, t / 4.0)) : 0.0;
            double tail = t >= 4.0 ? Math.Exp(-(t - 4.0) / 1.2) : 1.0;
            outp[i] = (ns[i] + low[i]) * (0.06 + 0.22 * swell) * tail;
        }
        WriteWav(Path.Combine(dir, "sfx-entry.wav"), outp);

        // ---- ambient loops (quieter/sparser, F-002) ----
        int dur = 24;
        int nTot = dur * SR;
        int nArr = nTot + SR;

        // z1: two soft wind swells over near-silence
        var baseN = LpNoise(nArr, 300, 10, 4.0);
        outp = new double[nArr];
        for (int i = 0; i < nArr; i++)
        {
            double t = (double)(i % nTot) / SR;
            double g = 0.0;
            foreach (var pair in new[] { new[] { 4.0, 5.0 }, new[] { 15.0, 4.0 } })
            {
                if (t >= pair[0] && t < pair[0] + pair[1])
                {
                    double s = Math.Sin(Math.PI * (t - pair[0]) / pair[1]);
                    g += s * s;
                }
            }
            outp[i] = baseN[i] * (0.010 + 0.055 * g);
        }
        WriteWav(Path.Combine(dir, "amb-z1.wav"), Loopable(outp, 1.0));

        // z2: sparse faint ember pops + very low hum
        var hum = Sine(nArr, 98, 98, 0.012);
        var rng2 = new Random(20);
        var pops = new double[nArr];
        for (int k = 0; k < 24; k++)
        {
            int t = rng2.Next(0, nTot - 1);
            int ln = rng2.Next(60, 240);
            double amp = 0.05 + rng2.NextDouble() * 0.11;
            for (int j = 0; j < ln; j++)
                if (t + j < nArr)
                    pops[t + j] += Math.Exp(-j / 40.0) * amp * (rng2.NextDouble() * 2 - 1);
        }
        outp = new double[nArr];
        for (int i = 0; i < nArr; i++) outp[i] = pops[i] + hum[i];
        WriteWav(Path.Combine(dir, "amb-z2.wav"), Loopable(outp, 1.0));

        // z3: whisper 55 Hz drone + three sparse drips
        var drone = Sine(nArr, 55, 55, 0.020);
        var rng3 = new Random(30);
        var drips = new double[nArr];
        foreach (double t0 in new[] { 5.2, 13.6, 20.9 })
        {
            int t = (int)(t0 * SR);
            double f = 1400 + rng3.NextDouble() * 700;
            for (int j = 0; j < (int)(0.09 * SR); j++)
                if (t + j < nArr)
                    drips[t + j] += Math.Sin(2 * Math.PI * f * j / SR) * Math.Exp(-j / (0.012 * SR)) * 0.10;
        }
        outp = new double[nArr];
        for (int i = 0; i < nArr; i++)
            outp[i] = drone[i] * (0.7 + 0.3 * Math.Sin(2 * Math.PI * 2 * i / (double)nTot)) + drips[i];
        WriteWav(Path.Combine(dir, "amb-z3.wav"), Loopable(outp, 1.0));

        // z4: faint reverent triad with slow beating
        var t1 = Sine(nArr, 196.0, 196.0, 0.014);
        var t2 = Sine(nArr, 294.3, 294.3, 0.011);
        var t3 = Sine(nArr, 392.4, 392.4, 0.008);
        var air = LpNoise(nArr, 1200, 13, 0.5);
        outp = new double[nArr];
        for (int i = 0; i < nArr; i++)
            outp[i] = (t1[i] + t2[i] + t3[i]) * (0.7 + 0.3 * Math.Sin(2 * Math.PI * 4 * i / (double)nTot))
                      + air[i] * 0.006;
        WriteWav(Path.Combine(dir, "amb-z4.wav"), Loopable(outp, 1.0));
    }
}
"@

[AudioGen]::GenerateAll($outDir)
Write-Host "Wrote round-1 audio into $outDir"
Get-ChildItem $outDir -Filter *.wav | Sort-Object Name | Format-Table Name, Length
