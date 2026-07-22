clear;
close all;
clc;

% DISCRETE SPECTRAL ANALYSIS USING THE DFT
% This script analyzes a signal composed of two discrete-time sinusoids.
% A rectangular window keeps only the first L samples. The spectrum is first
% evaluated with a large FFT and then with a shorter DFT to show the effect
% of frequency-grid spacing.

n = 0:9999;

% Signal frequencies:
% omega_1 = 3*pi/5 rad/sample
% omega_2 = pi/2 rad/sample
x = cos(3*pi*n/5) + cos(pi*n/2);

L = 50;          % Number of nonzero time-domain samples
N = 10000;       % FFT length used as a dense frequency grid

% Rectangular window followed by zero padding
w = [rectwin(L).' zeros(1, length(x)-L)];
xw = x .* w;

% Dense FFT representation
X = fft(xw, N);
omega = 2*pi*(0:N-1)/N;

figure;
plot(omega, abs(X), 'LineWidth', 1);
xlim([0 2*pi]);
grid on;
xlabel('\omega (rad/sample)');
ylabel('|X(e^{j\omega})|');
title('Magnitude spectrum using a 10,000-point FFT');

% A shorter DFT provides fewer frequency samples.
Nmin = 60;
X_short = fft(xw, Nmin);
omega_short = 2*pi*(0:Nmin-1)/Nmin;

figure;
plot(omega, abs(X), 'LineWidth', 1);
hold on;
stem(omega_short, abs(X_short), 'filled');
hold off;
xlim([0 2*pi]);
grid on;
xlabel('\omega (rad/sample)');
ylabel('Magnitude');
title('Dense FFT and 60-point DFT samples');
legend('10,000-point FFT', '60-point DFT', 'Location', 'best');
