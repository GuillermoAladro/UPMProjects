clear;
close all;
clc;

% SPECTRAL RESOLUTION AND SPECTRAL LEAKAGE
% The signal contains two tones with very different amplitudes.
% A rectangular window may hide the weaker tone because its sidelobes are
% too high. A Hamming window reduces sidelobes and makes the weak component
% easier to detect.

n = 0:9999;

% Strong tone amplitude = 1
% Weak tone amplitude   = 0.02
x = cos(3*pi*n/5) + 0.02*cos(pi*n/2);

L = 80;          % Observation-window length
N = 250;         % FFT length
omega = 2*pi*(0:N-1)/N;

%% Rectangular window
w_rect = [rectwin(L).' zeros(1, length(x)-L)];
x_rect = x .* w_rect;

X_rect = fft(x_rect, N);
X_rect_dB = 20*log10(abs(X_rect) + eps);

figure;
plot(omega, X_rect_dB, 'LineWidth', 1);
xlim([0 2*pi]);
ylim([-40 1.1*max(X_rect_dB)]);
grid on;
xlabel('\omega (rad/sample)');
ylabel('Magnitude (dB)');
title('Rectangular window: strong spectral leakage');

% The relative level of the weak tone is:
%
%   20*log10(0.02/1) approximately -34 dB
%
% The rectangular window has relatively high sidelobes. These sidelobes can
% mask the weak sinusoid, even when the main-lobe width is narrow enough.

%% Hamming window
% A Hamming window has much lower sidelobes than a rectangular window.
% This reduces leakage from the strong tone into nearby frequencies.
w_hamming = [hamming(L).' zeros(1, length(x)-L)];
x_hamming = x .* w_hamming;

X_hamming = fft(x_hamming, N);
X_hamming_dB = 20*log10(abs(X_hamming) + eps);

figure;
plot(omega, X_hamming_dB, 'LineWidth', 1);
xlim([0 2*pi]);
ylim([-60 1.1*max(X_hamming_dB)]);
grid on;
xlabel('\omega (rad/sample)');
ylabel('Magnitude (dB)');
title('Hamming window: reduced spectral leakage');
