% Plot FFT of FMCW Radar Signal
% Authored by Sai Machiraju

clear;
close all;

searchPath = fullfile("..", '**', "SaiTest1_*.hex");
files = dir(searchPath);

i = 0;
data = zeros(256, 1);

for file = {files.name}
    fprintf("Reading: " + file{1,1} + "\n");
    
    raw_text = readlines("../Data/" + file{1,1});
    file_data = str2double(strip(split(raw_text, ",")));
    
    % Trailing comma followed by no value appears as a NaN
    file_data = file_data(~isnan(file_data));
    fprintf("Data Length: %d\n", length(file_data));

    data = (i * data + file_data) / (i + 1);
    i = i + 1;
end

scaling_factor = 3.3 / 4096;
scaled_ac_signal = scaling_factor * (data - mean(data));
dc_component = scaling_factor * mean(data);
Fs = 51.2; % kHz
L = length(data);

figure(1);
plot((0:(L - 1)) / Fs, scaled_ac_signal);
xlabel("Time (ms)");
ylabel("Swing from DC (V)");
title("Baseband Signal");
subtitle(sprintf("DC Component: %.2f V | Sampling Rate: %.1f kHz", dc_component, Fs));
xlim([0, L / Fs]);
set(gca, 'FontSize', 16);

figure(2);
freqs = (0:L/2) * Fs / L;
w = hann(L);
windowed_ac_signal = w .* scaled_ac_signal;
signal_fft = abs(fft(windowed_ac_signal));
signal_fft = abs(signal_fft(1:L/2+1)) / sum(w);    % amplitude per bin
signal_fft(2:end-1) = 2 * signal_fft(2:end-1);     % single-sided
signal_fft_rms = signal_fft / sqrt(2);             % peak -> rms
signal_fft_rms(1) = signal_fft(1);                 % DC isn't sinusoidal; no sqrt(2)

dBV = 20*log10(signal_fft_rms + eps);              % eps avoids log(0)
plot(freqs, dBV, "HandleVisibility", "off");
xlabel("Frequency (kHz)");
ylabel("Magnitude (dBV)");
title("Baseband Signal FFT");
set(gca, 'FontSize', 16);