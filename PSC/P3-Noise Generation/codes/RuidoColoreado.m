clear; clc; close all;

% Band-pass coloured noise using an IIR filter and an ideal FFT mask
% Digital Signal Processing laboratory practice
rng(11, 'twister');                % Reproducible random sequence

N  = 2^11;
fs = N/4;                          % Sampling frequency [Hz]
Ts = 1/fs;
t  = (0:N-1)*Ts;
Z  = 1;                            % Reference impedance [ohm]
N0 = 5e-6;                         % One-sided target noise PSD [W/Hz]
df = fs/N;

Pn = N0*(fs/2);
K = sqrt(Pn*Z*N);
S = K*exp(1i*2*pi*rand(1,N));
x = ifft(S);

% Band edges: Wn = [1/3, 2/3] of the Nyquist frequency.
Wn = [1/3, 2/3];
filter_order = 4;
[b,a] = butter(filter_order, Wn, 'bandpass');

% Filter the complex process and extract two independent real realizations.
y_iir = filter(b, a, x);
y1_iir = sqrt(2)*real(y_iir);
y2_iir = sqrt(2)*imag(y_iir);

f = (0:N/2-1)*df;
Y_iir = fft(y1_iir)/N;
P_iir = (abs(Y_iir).^2)/Z;
PSD_iir = [P_iir(1), 2*P_iir(2:N/2)]/df;

figure(1);
subplot(2,1,1);
plot(t, y1_iir, 'LineWidth', 0.8); grid on;
title('IIR band-pass coloured noise - time domain');
xlabel('Time [s]'); ylabel('Voltage [V]');

subplot(2,1,2);
plot(f, PSD_iir, 'LineWidth', 1.0); grid on;
title('IIR band-pass coloured noise - one-sided PSD');
xlabel('Frequency [Hz]'); ylabel('PSD [W/Hz]');

% Ideal spectral mask.  The two passbands are symmetric so that the IFFT
% has statistically equivalent real and imaginary components.
fmin = (1/3)*(fs/2);               % fs/6
fmax = (2/3)*(fs/2);               % fs/3
f_fft = (0:N-1)*df;
mask_positive = (f_fft >= fmin) & (f_fft < fmax);
mask_negative = (f_fft >= fs-fmax) & (f_fft < fs-fmin);
mask = double(mask_positive | mask_negative);

S_masked = S.*mask;
y_mask = ifft(S_masked);
y1_mask = sqrt(2)*real(y_mask);
y2_mask = sqrt(2)*imag(y_mask);

Y_mask = fft(y1_mask)/N;
P_mask = (abs(Y_mask).^2)/Z;
PSD_mask = [P_mask(1), 2*P_mask(2:N/2)]/df;

figure(2);
subplot(2,1,1);
plot(t, y1_mask, 'LineWidth', 0.8); grid on;
title('Ideal-mask coloured noise - time domain');
xlabel('Time [s]'); ylabel('Voltage [V]');

subplot(2,1,2);
plot(f, PSD_mask, 'LineWidth', 1.0); grid on;
title('Ideal-mask coloured noise - one-sided PSD');
xlabel('Frequency [Hz]'); ylabel('PSD [W/Hz]');

figure(3);
plot(f, PSD_iir, 'LineWidth', 1.0); hold on;
plot(f, PSD_mask, 'LineWidth', 1.2);
grid on;
title('Butterworth band-pass filter and ideal spectral mask');
xlabel('Frequency [Hz]'); ylabel('PSD [W/Hz]');
legend('4th-order Butterworth', 'Ideal FFT mask', 'Location', 'best');

[ry1,lags1]   = xcorr(y1_mask, 'biased');
[ry2,lags2]   = xcorr(y2_mask, 'biased');
[ry12,lags12] = xcorr(y1_mask, y2_mask, 'biased');

figure(4);
subplot(3,1,1);
plot(lags1, ry1); grid on;
title('Autocorrelation of ideal-mask real component');
xlabel('Lag [samples]'); ylabel('R_{y_1y_1}');

subplot(3,1,2);
plot(lags2, ry2); grid on;
title('Autocorrelation of ideal-mask imaginary component');
xlabel('Lag [samples]'); ylabel('R_{y_2y_2}');

subplot(3,1,3);
plot(lags12, ry12); grid on;
title('Cross-correlation of ideal-mask components');
xlabel('Lag [samples]'); ylabel('R_{y_1y_2}');

% Power validation.
bandwidth = fmax-fmin;
expected_mask_power = N0*bandwidth;
estimated_mask_power = mean(y1_mask.^2)/Z;

[H_iir,fH] = freqz(b, a, 16384, fs);
iir_equivalent_noise_bandwidth = trapz(fH, abs(H_iir).^2);
expected_iir_power = N0*iir_equivalent_noise_bandwidth;
estimated_iir_power = mean(y1_iir.^2)/Z;

fprintf('Ideal-mask bandwidth:             %.3f Hz\n', bandwidth);
fprintf('Expected ideal-mask power:        %.6e W\n', expected_mask_power);
fprintf('Estimated ideal-mask power:       %.6e W\n', estimated_mask_power);
fprintf('IIR equivalent noise bandwidth:   %.3f Hz\n', iir_equivalent_noise_bandwidth);
fprintf('Expected Butterworth output power: %.6e W\n', expected_iir_power);
fprintf('Estimated Butterworth output power: %.6e W\n', estimated_iir_power);
