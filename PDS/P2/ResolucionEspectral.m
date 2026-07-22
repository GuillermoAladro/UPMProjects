clear;
close all;
clc;

% SPECTRAL RESOLUTION
% This script shows how the observation-window length determines whether two
% nearby sinusoidal components can be distinguished in the spectrum.
% Increasing only the FFT length does not improve the true spectral
% resolution; increasing the number of observed signal samples does.

n = 0:9999;
x = cos(3*pi*n/5) + cos(pi*n/2);

N = 250;         % FFT length
omega = 2*pi*(0:N-1)/N;

%% Case 1: Short rectangular window
L1 = 10;
w1 = [rectwin(L1).' zeros(1, length(x)-L1)];
xw1 = x .* w1;

X1 = fft(xw1, N);
X1_dB = 20*log10(abs(X1) + eps);

figure;
plot(omega, X1_dB, 'LineWidth', 1);
xlim([0 2*pi]);
ylim([0 30]);
grid on;
xlabel('\omega (rad/sample)');
ylabel('Magnitude (dB)');
title('Poor spectral resolution with L = 10');

% With L = 10, the main lobes are too wide and the two tones cannot be
% clearly separated. This is a spectral-resolution problem.

%% Case 2: Longer rectangular window
% A longer window narrows the main lobe. For these two frequencies, a
% practical minimum length can be estimated from their separation.
L2 = 40;
w2 = [rectwin(L2).' zeros(1, length(x)-L2)];
xw2 = x .* w2;

X2 = fft(xw2, N);
X2_dB = 20*log10(abs(X2) + eps);

figure;
plot(omega, X2_dB, 'LineWidth', 1);
xlim([0 2*pi]);
ylim([0 30]);
grid on;
xlabel('\omega (rad/sample)');
ylabel('Magnitude (dB)');
title('Improved spectral resolution with L = 40');
