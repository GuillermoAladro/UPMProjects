clear; clc; close all;

% White Gaussian noise and low-pass coloured noise
% Digital Signal Processing laboratory practice
rng(7, 'twister');                 % Reproducible random sequence

N  = 1024;                         % Number of samples
fs = N;                            % Sampling frequency [Hz]
Ts = 1/fs;
t  = (0:N-1)*Ts;
Z  = 50;                           % Reference impedance [ohm]
N0 = 1e-6;                         % One-sided target noise PSD [W/Hz]
df = fs/N;                         % DFT-bin spacing [Hz]

% Total noise power over the positive-frequency Nyquist band.
Pn = N0*(fs/2);

% Constant spectral magnitude and independent random phase.
% The IFFT produces a complex, approximately Gaussian time sequence.
K = sqrt(Pn*Z*N);
S = K*exp(1i*2*pi*rand(1,N));
x = ifft(S);

% The square-root-of-two factor assigns the complete target power to
% each real-valued realization obtained from the complex sequence.
x1 = sqrt(2)*real(x);
x2 = sqrt(2)*imag(x);

% One-sided power spectral density of the real component.
X = fft(x1)/N;
Pxx = (abs(X).^2)/Z;               % Power in every two-sided DFT bin
Pxx_one = [Pxx(1), 2*Pxx(2:N/2)]/df;
f = (0:N/2-1)*df;

estimated_white_power = mean(x1.^2)/Z;
spectral_white_power  = sum(Pxx_one)*df;

figure(1);
plot(t, x1, 'LineWidth', 0.8);
grid on;
title('White Gaussian noise - time domain');
xlabel('Time [s]'); ylabel('Voltage [V]');

figure(2);
plot(f, Pxx_one, 'LineWidth', 1.0);
grid on;
title('White Gaussian noise - one-sided PSD');
xlabel('Frequency [Hz]'); ylabel('PSD [W/Hz]');

% Biased estimates are used so that every lag has the same normalization.
[r1,lags1]   = xcorr(x1, 'biased');
[r2,lags2]   = xcorr(x2, 'biased');
[r12,lags12] = xcorr(x1, x2, 'biased');

figure(3);
subplot(3,1,1);
plot(lags1, r1); grid on;
title('Autocorrelation of the real component');
xlabel('Lag [samples]'); ylabel('R_{x_1x_1}');

subplot(3,1,2);
plot(lags2, r2); grid on;
title('Autocorrelation of the imaginary component');
xlabel('Lag [samples]'); ylabel('R_{x_2x_2}');

subplot(3,1,3);
plot(lags12, r12); grid on;
title('Cross-correlation between real and imaginary components');
xlabel('Lag [samples]'); ylabel('R_{x_1x_2}');

% FIR low-pass colouring filter.
fc = N/8;                          % Cutoff frequency [Hz]
Wn = fc/(fs/2);                    % Normalized cutoff
filter_order = 30;
b = fir1(filter_order, Wn, 'low', hamming(filter_order+1));

y1 = filter(b, 1, x1);
y2 = filter(b, 1, x2);

Y = fft(y1)/N;
Pyy = (abs(Y).^2)/Z;
Pyy_one = [Pyy(1), 2*Pyy(2:N/2)]/df;

[Hfir, fH] = freqz(b, 1, 8192, fs);
equivalent_noise_bandwidth = trapz(fH, abs(Hfir).^2);
expected_coloured_power = N0*equivalent_noise_bandwidth;
estimated_coloured_power = mean(y1.^2)/Z;

figure(4);
plot(f, Pxx_one, 'LineWidth', 0.9); hold on;
plot(f, Pyy_one, 'LineWidth', 1.3);
grid on;
title('White noise and FIR-coloured noise');
xlabel('Frequency [Hz]'); ylabel('PSD [W/Hz]');
legend('White noise', 'FIR low-pass coloured noise', 'Location', 'best');

figure(5);
plot(t, y1, 'LineWidth', 0.8);
grid on;
title('FIR-coloured noise - time domain');
xlabel('Time [s]'); ylabel('Voltage [V]');

[r1c,lags1c]   = xcorr(y1, 'biased');
[r2c,lags2c]   = xcorr(y2, 'biased');
[r12c,lags12c] = xcorr(y1, y2, 'biased');

figure(6);
subplot(3,1,1);
plot(lags1c, r1c); grid on;
title('Autocorrelation of FIR-coloured real component');
xlabel('Lag [samples]'); ylabel('R_{y_1y_1}');

subplot(3,1,2);
plot(lags2c, r2c); grid on;
title('Autocorrelation of FIR-coloured imaginary component');
xlabel('Lag [samples]'); ylabel('R_{y_2y_2}');

subplot(3,1,3);
plot(lags12c, r12c); grid on;
title('Cross-correlation of FIR-coloured components');
xlabel('Lag [samples]'); ylabel('R_{y_1y_2}');

fprintf('Expected white-noise power:       %.6e W\n', Pn);
fprintf('Estimated white-noise power:      %.6e W\n', estimated_white_power);
fprintf('PSD-integrated white-noise power: %.6e W\n', spectral_white_power);
fprintf('FIR equivalent noise bandwidth:   %.3f Hz\n', equivalent_noise_bandwidth);
fprintf('Expected FIR output power:         %.6e W\n', expected_coloured_power);
fprintf('Estimated FIR output power:        %.6e W\n', estimated_coloured_power);
