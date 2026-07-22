%% Coloured noise using an IIR band-pass filter and an ideal spectral mask
% The same white-noise spectrum is coloured by two methods:
%   1) a fourth-order Butterworth IIR band-pass filter;
%   2) direct multiplication by a rectangular frequency-domain mask.

clear; clc; close all;
rng(23, 'twister');                 % Reproducible random experiment

%% General parameters
N = 2^11;                           % Number of samples / DFT size
fs = N/4;                           % Sampling frequency [Hz]
Ts = 1/fs;                          % Sampling period [s]
t = (0:N-1)*Ts;                     % Time axis [s]
Z = 1;                              % Reference impedance [ohm]
N0 = 5e-6;                          % One-sided noise PSD [W/Hz]
Pn = N0*(fs/2);                     % Total white-noise power [W]

%% White-noise synthesis in the frequency domain
K = sqrt(Pn*Z*N);
S = K*exp(1j*2*pi*rand(1,N));
x = ifft(S);

%% Method 1: Butterworth IIR band-pass filter
Wn = [1/3 2/3];                     % Normalised band edges
filterOrder = 4;
[b, a] = butter(filterOrder, Wn, 'bandpass');

yIIR = filter(b, a, x);
y1IIR = sqrt(2)*real(yIIR);
y2IIR = sqrt(2)*imag(yIIR);

YIIR = fft(y1IIR)/N;
PyyIIR = abs(YIIR).^2/Z;
PyyIIRone = PyyIIR(1:N/2);
PyyIIRone(2:end) = 2*PyyIIRone(2:end);
f = (0:N/2-1)*(fs/N);

figure(1);
subplot(2,1,1);
plot(t, y1IIR, 'k'); grid on;
title('IIR-Coloured Noise - Time Domain');
xlabel('Time (s)'); ylabel('Amplitude (V)');
subplot(2,1,2);
plot(f, PyyIIRone, 'k'); grid on;
title('IIR-Coloured Noise - One-Sided PSD');
xlabel('Frequency (Hz)'); ylabel('Power spectral density (W/Hz)');

%% Method 2: ideal frequency-domain mask
fmin = (1/3)*(fs/2);                % Lower edge = fs/6
fmax = (2/3)*(fs/2);                % Upper edge = fs/3
df = fs/N;
fTwoSided = (0:N-1)*df;

% Keep the positive-frequency band and its negative-frequency mirror.
mask = ((fTwoSided >= fmin) & (fTwoSided <= fmax)) | ...
       ((fTwoSided >= fs-fmax) & (fTwoSided <= fs-fmin));

Scol = S.*mask;
yMask = ifft(Scol);
y1Mask = sqrt(2)*real(yMask);
y2Mask = sqrt(2)*imag(yMask);

YMask = fft(y1Mask)/N;
PyyMask = abs(YMask).^2/Z;
PyyMaskOne = PyyMask(1:N/2);
PyyMaskOne(2:end) = 2*PyyMaskOne(2:end);

figure(2);
subplot(2,1,1);
plot(t, y1Mask, 'k'); grid on;
title('Mask-Coloured Noise - Time Domain');
xlabel('Time (s)'); ylabel('Amplitude (V)');
subplot(2,1,2);
plot(f, PyyMaskOne, 'k'); grid on;
title('Mask-Coloured Noise - One-Sided PSD');
xlabel('Frequency (Hz)'); ylabel('Power spectral density (W/Hz)');

%% Comparison of both colouring techniques
figure(3);
plot(f, PyyIIRone, 'k', 'LineWidth', 1); hold on;
plot(f, PyyMaskOne, '--k', 'LineWidth', 1.3); grid on;
title('IIR Band-Pass Filtering versus Ideal Spectral Mask');
xlabel('Frequency (Hz)'); ylabel('Power spectral density (W/Hz)');
legend('Butterworth IIR', 'Ideal mask', 'Location', 'northeast');

%% Correlation analysis of the mask-coloured process
[ry1, lags1] = xcorr(y1Mask);
[ry2, lags2] = xcorr(y2Mask);
[ry12, lags12] = xcorr(y1Mask, y2Mask);

figure(4);
subplot(3,1,1);
plot(lags1, ry1, 'k'); grid on;
title('Autocorrelation of Mask-Coloured Real Component');
xlabel('Lag'); ylabel('Correlation'); xlim([-N N]);

subplot(3,1,2);
plot(lags2, ry2, 'k'); grid on;
title('Autocorrelation of Mask-Coloured Imaginary Component');
xlabel('Lag'); ylabel('Correlation'); xlim([-N N]);

subplot(3,1,3);
plot(lags12, ry12, 'k'); grid on;
title('Cross-Correlation between Real and Imaginary Components');
xlabel('Lag'); ylabel('Correlation'); xlim([-N N]);

%% Power verification
bandwidth = fmax-fmin;
expectedPower = N0*bandwidth;
estimatedIIRPower = mean(y1IIR.^2)/Z;
estimatedMaskPower = mean(y1Mask.^2)/Z;

fprintf('Band limits:                    %.3f Hz to %.3f Hz\n', fmin, fmax);
fprintf('Expected ideal-mask power:      %.6e W\n', expectedPower);
fprintf('Estimated IIR output power:     %.6e W\n', estimatedIIRPower);
fprintf('Estimated mask output power:    %.6e W\n', estimatedMaskPower);
