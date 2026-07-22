clear;
close all;
clc;

% FIR LOW-PASS FILTER DESIGN USING A KAISER WINDOW
% Specifications:
%   Sampling frequency: 20 kHz
%   Passband edge:      750 Hz
%   Stopband edge:      1500 Hz
%   Maximum passband attenuation: 0.9151 dB
%   Minimum stopband attenuation: 60 dB

fs = 20000;
fp = 750;
fa = 1500;

% Convert physical frequencies to digital angular frequencies.
omega_p = 2*pi*fp/fs;
omega_a = 2*pi*fa/fs;

% Convert the specifications from decibels to linear tolerances.
delta_p = 1 - 10^(-0.9151/20);
delta_a = 10^(-60/20);

% Plot the required low-pass specification mask.
figure;
dibuja_plantilla(omega_p, omega_a, delta_p, delta_p, delta_a, 'log');
title('Low-pass filter specification mask');

% Estimate the FIR order and Kaiser-window parameter.
[order, Wn, beta, filter_type] = ...
    kaiserord([omega_p omega_a], [1 0], [delta_p delta_a], 2*pi);

% A symmetric Type-I FIR low-pass filter requires an even order.
order = order + rem(order, 2);

% Construct the Kaiser window.
window = kaiser(order + 1, beta).';

% Use the center of the transition band as the ideal cutoff frequency.
omega_c = (omega_p + omega_a)/2;

% Symmetric sample index for a linear-phase impulse response.
n = -order/2:order/2;

% Ideal low-pass impulse response.
h_ideal = (omega_c/pi) * sinc((omega_c/pi).*n);

% Apply the Kaiser window.
h_fir = h_ideal .* window;

% Display the ideal and windowed impulse responses.
figure;
subplot(2,1,1);
stem(n, h_ideal, 'filled');
grid on;
xlabel('n');
ylabel('Amplitude');
title('Ideal low-pass impulse response');

subplot(2,1,2);
stem(n, h_fir, 'filled');
grid on;
xlabel('n');
ylabel('Amplitude');
title('Kaiser-windowed FIR impulse response');

% Calculate the digital frequency response.
N = 2000;
[H_fir, omega] = freqz(h_fir, 1, N, 2*pi);

% Compare the designed response with the specification mask.
figure;
dibuja_plantilla(omega_p, omega_a, delta_p, delta_p, delta_a, 'log');
hold on;
plot(omega, 20*log10(abs(H_fir) + eps), 'LineWidth', 1.2);
hold off;
ylim([-90 5]);
grid on;
xlabel('\omega (rad/sample)');
ylabel('Magnitude (dB)');
title('Magnitude response of the Kaiser-window FIR filter');

% Display useful design information.
fprintf('FIR filter order: %d\n', order);
fprintf('Number of FIR coefficients: %d\n', length(h_fir));
fprintf('Kaiser beta parameter: %.4f\n', beta);
