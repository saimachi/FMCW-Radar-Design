% Authored by Sai Machiraju
% Solver to achieve a 50 ohm characteristic impedance
% Source: https://eng.libretexts.org/Bookshelves/Electrical_Engineering/Electronics/Microwave_and_RF_Design_II_-_Transmission_Lines_(Steer)/03%3A_Planar_Transmission_Lines/3.05%3A_Microstrip_Transmission_Lines

epsilon_r = 4.5;
h = 0.0994E-3; % 0.0994 mm

syms w
u = w / h;
a = 1 + (1 / 49) * log((u ^ 4 + (u / 52) ^ 2) / (u ^ 4 + 0.432)) + (1 / 18.7) * log(1 + (u / 18.1) ^ 3);
b = 0.564 * ((epsilon_r - 0.9) / (epsilon_r + 3)) ^ 0.053;
epsilon_e = (epsilon_r + 1) / 2 + ((epsilon_r - 1) / 2) * (1 + 10 * h / w) ^ (-a * b);
F1 = 6 + (2 * pi - 6) * exp(-(30.666 * h / w) ^ 0.7528);
Z01 = 60 * log(F1 * h / w + sqrt(1 + (2 * h / w) ^ 2));

w_sol = solve(Z01 / sqrt(epsilon_e) == 50, w);

fprintf("Width: %f mm (%f mil)\n", w_sol / 1E-3, (w_sol / 1E-3) * 39.37);

% Wavelength in line
lambda_free_space = 3E8 / 2.4E9;
fprintf("Wavelength in TX Line: %f m\n", lambda_free_space / sqrt(subs(epsilon_e, w, w_sol)));