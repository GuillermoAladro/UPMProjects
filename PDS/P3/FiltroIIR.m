clear;
close all;
clc;

% IIR LOW-PASS FILTER DESIGN
% This script designs Butterworth and Chebyshev Type-I digital filters by:
%   1. Prewarping the digital edge frequencies.
%   2. Designing analog low-pass prototypes.
%   3. Applying the bilinear transformation.

fs = 20000;
fp = 750;
fa = 1500;

% Digital angular-frequency specifications.
omega_p = 2*pi*fp/fs;
omega_a = 2*pi*fa/fs;

% Linear passband and stopband tolerances.
delta_p = 1 - 10^(-0.9151/20);
delta_a = 10^(-60/20);

% Bilinear-transform sampling interval.
Td = 1;

% Prewarp the digital frequencies.
Omega_p = (2/Td)*tan(omega_p/2);
Omega_a = (2/Td)*tan(omega_a/2);

% Convert the tolerances to decibel specifications.
Rp = -20*log10(1 - delta_p);
Rs = -20*log10(delta_a);

%% Butterworth prototype
[order_butter, Omega_c_butter] = ...
    buttord(Omega_p, Omega_a, Rp, Rs, 's');

[b_butter_analog, a_butter_analog] = ...
    butter(order_butter, Omega_c_butter, 'low', 's');

[b_butter, a_butter] = ...
    bilinear(b_butter_analog, a_butter_analog, 1/Td);

%% Chebyshev Type-I prototype
[order_cheby, Omega_p_cheby] = ...
    cheb1ord(Omega_p, Omega_a, Rp, Rs, 's');

[b_cheby_analog, a_cheby_analog] = ...
    cheby1(order_cheby, Rp, Omega_p_cheby, 'low', 's');

[b_cheby, a_cheby] = ...
    bilinear(b_cheby_analog, a_cheby_analog, 1/Td);

%% Frequency responses
N = 2000;
[H_butter, omega] = freqz(b_butter, a_butter, N, 2*pi);
[H_cheby, ~] = freqz(b_cheby, a_cheby, N, 2*pi);

H_butter_dB = 20*log10(abs(H_butter) + eps);
H_cheby_dB = 20*log10(abs(H_cheby) + eps);

% Plot both responses over the specification mask.
figure;
dibuja_plantilla(omega_p, omega_a, delta_p, delta_p, delta_a, 'log');
hold on;
plot(omega, H_butter_dB, 'LineWidth', 1.2);
plot(omega, H_cheby_dB, 'LineWidth', 1.2);
hold off;
ylim([-90 5]);
grid on;
xlabel('\omega (rad/sample)');
ylabel('Magnitude (dB)');
title('Butterworth and Chebyshev Type-I low-pass filters');
legend('Specification mask', 'Butterworth', 'Chebyshev Type I', ...
       'Location', 'best');

% Plot the same responses using normalized angular frequency and hertz.
frequency_hz = omega*fs/(2*pi);

figure;
subplot(2,1,1);
plot(omega, H_butter_dB, 'LineWidth', 1.2);
hold on;
plot(omega, H_cheby_dB, 'LineWidth', 1.2);
hold off;
xlim([0 pi]);
ylim([-90 5]);
grid on;
xlabel('\omega (rad/sample)');
ylabel('Magnitude (dB)');
title('Frequency response in rad/sample');
legend('Butterworth', 'Chebyshev Type I', 'Location', 'best');

subplot(2,1,2);
plot(frequency_hz, H_butter_dB, 'LineWidth', 1.2);
hold on;
plot(frequency_hz, H_cheby_dB, 'LineWidth', 1.2);
hold off;
xlim([0 fs/2]);
ylim([-90 5]);
grid on;
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('Frequency response in hertz');
legend('Butterworth', 'Chebyshev Type I', 'Location', 'best');

fprintf('Butterworth order: %d\n', order_butter);
fprintf('Chebyshev Type-I order: %d\n', order_cheby);
