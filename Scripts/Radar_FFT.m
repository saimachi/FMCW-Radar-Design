% Plot FFT of FMCW Radar Signal
% Authored by Sai Machiraju

clear;
close all;

searchPath = fullfile("..", '**', "Acq_Webpage_*.hex");
files = dir(searchPath);

i = 0;
data = zeros(256, 1);

for file = {files.name}
    fprintf("Reading: " + file{1,1} + "\n");
    
    raw_text = readlines("../" + file{1,1});
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

freqs = (-Fs/2):(Fs/L):(Fs/2 - Fs/L);

figure(2);
signal_fft = abs(fftshift(fft(scaled_ac_signal)));
signal_fft = [signal_fft(1:L / 2)', signal_fft(L / 2 + 2:end)'];
freqs = [freqs(1:L / 2), freqs(L / 2 + 2:end)];
plot(freqs, 20 * log10(signal_fft), "HandleVisibility", "off");
yline(20 * log10(median(signal_fft)), "--", "DisplayName", "Noise Floor");
xlabel("Frequency (kHz)");
ylabel("Magnitude (dBV)");
title("Baseband Signal FFT");
subtitle("DC Component Excluded");
legend("show");