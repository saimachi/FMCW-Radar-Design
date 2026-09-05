% Authored by Sai Machiraju
% FMCW Radar Design

R = 0:1:112;
% 18 dBm
Ps = 0.001 * 10^(18 / 10);

lambda = 3E8 / 2.4E9;
% D = 83 mm
D = 0.083;
% Gain (non-dBi): (pi * D / lambda)^2
G = (pi * D / lambda) ^ 2;

rcs = 1; % 1 m^2

Pe = (Ps * G^2 * lambda^2 * rcs) ./ (R .^ 4 * (4 * pi)^3);
P_signal_dBm = 10 * log10(Pe / 0.001);

figure(1);
plot(R, P_signal_dBm);
title("Received Power with Distance");
subtitle("1 m^{2} RCS");
xlabel("Range (m)");
ylabel("Received Power (dBm)");

% PA + Mixer Conversion Loss
P_signal_mixer_output = P_signal_dBm + 21 - 6.79;

P_watts = 0.001 * 10 .^ (P_signal_mixer_output / 10);

figure(2);
% System has 50 ohm impedance
plot(R, 20 * log10(sqrt(P_watts * 50)));
title("RMS AC Voltage at Amplifier Input");
xlabel("Range (m)");
ylabel("AC RMS Voltage (dBV)");