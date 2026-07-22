clear;
close all;
clc;

% ANALYSIS OF A DISCRETE-TIME SINUSOIDAL SEQUENCE
% The signal is a cosine with normalized angular frequency 3*pi/5 rad/sample.
% A rectangular window limits the observation to L = 45 samples.
% The script compares a dense FFT with the minimum suitable DFT length.

n = 0:9999;
x = cos(3*pi*n/5);

L = 45;          % Observation-window length
N = 10000;       % Dense FFT length

% Keep the first 45 samples and set the rest to zero
w = [rectwin(L).' zeros(1, length(x)-L)];
h = x .* w;

% Dense FFT
H = fft(h, N);
omega = 2*pi*(0:N-1)/N;

figure;
plot(omega, abs(H), 'LineWidth', 1);
xlim([0 2*pi]);
grid on;
xlabel('\omega (rad/sample)');
ylabel('|H(e^{j\omega})|');
title('Magnitude spectrum of the windowed sinusoid');

% The sinusoid has a fundamental discrete-time period of 10 samples.
% To include the complete 45-sample observation interval, the DFT length
% must satisfy:
%   1) N_DFT >= L
%   2) N_DFT is a multiple of the signal period, 10
%
% The smallest value satisfying both conditions is 50.
Nmin = 50;
H_min = fft(h, Nmin);
omega_min = 2*pi*(0:Nmin-1)/Nmin;

figure;
plot(omega, abs(H), 'LineWidth', 1);
hold on;
stem(omega_min, abs(H_min), 'filled');
hold off;
xlim([0 2*pi]);
grid on;
xlabel('\omega (rad/sample)');
ylabel('Magnitude');
title('Dense FFT and minimum 50-point DFT');
legend('10,000-point FFT', '50-point DFT', 'Location', 'best');
