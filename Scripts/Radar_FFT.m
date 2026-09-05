% Plot FFT of FMCW Radar Signal
% Authored by Sai Machiraju

clear;
close all;

raw_text = readlines("Verified_Baseband.hex");
data = str2double(strip(split(raw_text, ",")));

% Trailing comma followed by no value appears as a NaN
data = data(~isnan(data));
fprintf("Data Length: %d\n", length(data));

L = length(data);
Fs = 25.6; % kHz
freqs = (-Fs/2):(Fs/L):(Fs/2 - Fs/L);

plot(freqs, 20 * log10(abs(fftshift(fft(data - mean(data))))));
xlabel("Frequency (kHz)");
ylabel("Magnitude (dBV)");
title("Baseband Signal FFT");
subtitle("DC component excluded");