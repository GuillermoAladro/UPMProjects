%% Gaussian white noise and FIR-coloured noise
% This script synthesises a complex random process from a constant-magnitude
% spectrum with independent random phases. The real and imaginary parts are
% approximately Gaussian and mutually uncorrelated. A low-pass FIR filter is
% then used to obtain coloured noise.

clear; clc; close all;
rng(11, 'twister');                 % Reproducible random experiment

%% General parameters
N = 1024;                           % Number of samples / DFT size
fs = N;                             % Sampling frequency [Hz]
Ts = 1/fs;                          % Sampling period [s]
t = (0:N-1)*Ts;                     % Time axis [s]
Z = 50;                             % Reference impedance [ohm]
N0 = 1e-6;                          % One-sided noise PSD [W/Hz]
Pn = N0*(fs/2);                     % Expected noise power [W]

%% Random-phase spectral synthesis
K = sqrt(Pn*Z*N);                   % Constant spectral magnitude
S = K*exp(1j*2*pi*rand(1,N));       % Random independent phases
x = ifft(S);                        % Complex time-domain noise
x1 = sqrt(2)*real(x);               % Real white-noise component
x2 = sqrt(2)*imag(x);               % Imaginary white-noise component

%% One-sided power spectral density of the real component
X = fft(x1)/N;
Pxx = abs(X).^2/Z;
PxxOne = Pxx(1:N/2);
PxxOne(2:end) = 2*PxxOne(2:end);    % One-sided correction except DC
f = (0:N/2-1)*(fs/N);

figure(1);
plot(t, x1, 'k'); grid on;
title('Real Part of Gaussian White Noise - Time Domain');
xlabel('Time (s)'); ylabel('Amplitude (V)');

figure(2);
plot(f, PxxOne, 'k'); grid on;
title('Real Part of Gaussian White Noise - One-Sided PSD');
xlabel('Frequency (Hz)'); ylabel('Power spectral density (W/Hz)');

%% Correlation analysis
[r1, lags1] = xcorr(x1);
[r2, lags2] = xcorr(x2);
[r12, lags12] = xcorr(x1, x2);

figure(3);
subplot(3,1,1);
plot(lags1, r1, 'k'); grid on;
title('Autocorrelation of the Real Component');
xlabel('Lag'); ylabel('Correlation'); xlim([-N N]);

subplot(3,1,2);
plot(lags2, r2, 'k'); grid on;
title('Autocorrelation of the Imaginary Component');
xlabel('Lag'); ylabel('Correlation'); xlim([-N N]);

subplot(3,1,3);
plot(lags12, r12, 'k'); grid on;
title('Cross-Correlation between Real and Imaginary Components');
xlabel('Lag'); ylabel('Correlation'); xlim([-N N]);

%% FIR low-pass colouring filter
fc = N/8;                           % Cut-off frequency [Hz]
Wn = fc/(fs/2);                     % Normalised cut-off frequency
filterOrder = 30;
b = fir1(filterOrder, Wn, 'low');   % Hamming-window FIR design

y1 = filter(b, 1, x1);              % Coloured real component
y2 = filter(b, 1, x2);              % Coloured imaginary component

Y = fft(y1)/N;
Pyy = abs(Y).^2/Z;
PyyOne = Pyy(1:N/2);
PyyOne(2:end) = 2*PyyOne(2:end);

figure(4);
plot(f, PxxOne, 'k', 'LineWidth', 1); hold on;
plot(f, PyyOne, '--k', 'LineWidth', 1.5); grid on;
title('White Noise and FIR-Coloured Noise');
xlabel('Frequency (Hz)'); ylabel('Power spectral density (W/Hz)');
legend('White noise', 'FIR-coloured noise', 'Location', 'northeast');

figure(5);
subplot(2,1,1);
plot(t, y1, 'k'); grid on;
title('FIR-Coloured Noise - Time Domain');
xlabel('Time (s)'); ylabel('Amplitude (V)');
subplot(2,1,2);
plot(f, PyyOne, 'k'); grid on;
title('FIR-Coloured Noise - One-Sided PSD');
xlabel('Frequency (Hz)'); ylabel('Power spectral density (W/Hz)');

%% Correlation analysis after FIR filtering
[r1c, lags1c] = xcorr(y1);
[r2c, lags2c] = xcorr(y2);
[r12c, lags12c] = xcorr(y1, y2);

figure(6);
subplot(3,1,1);
plot(lags1c, r1c, 'k'); grid on;
title('Autocorrelation of FIR-Coloured Real Component');
xlabel('Lag'); ylabel('Correlation'); xlim([-N N]);

subplot(3,1,2);
plot(lags2c, r2c, 'k'); grid on;
title('Autocorrelation of FIR-Coloured Imaginary Component');
xlabel('Lag'); ylabel('Correlation'); xlim([-N N]);

subplot(3,1,3);
plot(lags12c, r12c, 'k'); grid on;
title('Cross-Correlation after FIR Filtering');
xlabel('Lag'); ylabel('Correlation'); xlim([-N N]);

%% Numerical checks
estimatedWhitePower = mean(x1.^2)/Z;
estimatedFIRPower = mean(y1.^2)/Z;
expectedIdealFIRPower = N0*fc;

fprintf('Expected white-noise power:       %.6e W\n', Pn);
fprintf('Estimated white-noise power:      %.6e W\n', estimatedWhitePower);
fprintf('Ideal low-pass output power:       %.6e W\n', expectedIdealFIRPower);
fprintf('Estimated FIR-coloured power:      %.6e W\n', estimatedFIRPower);
