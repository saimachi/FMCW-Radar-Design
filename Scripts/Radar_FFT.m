% Plot FFT of FMCW Radar Signal
% Authored by Sai Machiraju

clear;
close all;

raw_text = readlines("Verified_Baseband.hex");
data = str2double(strip(split(raw_text, ",")));

% Trailing comma followed by no value appears as a NaN
data = data(~isnan(data));
fprintf("Data Length: %d\n", length(data));

scaling_factor = 3.3 / 4096;
scaled_ac_signal = scaling_factor * (data - mean(data));
dc_component = scaling_factor * mean(data);
Fs = 25.6; % kHz
L = length(data);

figure(1);
plot((0:(L - 1)) / Fs, scaled_ac_signal);
xlabel("Time (ms)");
ylabel("Swing from DC (V)");
title("Baseband Signal");
subtitle(sprintf("DC Component: %.2f V | Sampling Rate: %.1f kHz", dc_component, Fs));
xlim([0, 10]);

freqs = (-Fs/2):(Fs/L):(Fs/2 - Fs/L);

figure(2);
signal_fft = abs(fftshift(fft(scaled_ac_signal)));
plot(freqs, 20 * log10(signal_fft), "HandleVisibility", "off");
yline(20 * log10(median(signal_fft)), "--", "DisplayName", "Noise Floor");
xlabel("Frequency (kHz)");
ylabel("Magnitude (dBV)");
title("Baseband Signal FFT");
subtitle("DC Component Excluded");
legend("show");