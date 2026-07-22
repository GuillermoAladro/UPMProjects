clear; clc; close all;

%% 1. SYNTHETIC NON-STATIONARY SIGNAL
L = 32768;
n = (0:L-1)';

% S1: constant complex tone. For N = 1024 its FFT bin is 400.
omega1 = 2*pi*(50/128);
s1 = exp(1j*omega1*n);

% S2: intermittent tone. Frequency 105/128 cycles/sample is equivalent
% to -23/128 cycles/sample in the centered digital-frequency interval.
omega2 = 2*pi*(105/128);
cycle_position = mod(n, 256);
mask = cycle_position < 150;       % 150 samples ON, 106 samples OFF
s2 = exp(1j*omega2*n) .* mask;

% S3: asymmetric triangular frequency sweep from bins 240 to 480.
T3 = 4096;
triangle_width = 3276/T3;
omega3_initial = 2*pi*(30/128);
omega3_final = 2*pi*(60/128);
u3 = mod(n, T3)/T3;
shape3 = zeros(L, 1);
rising = u3 < triangle_width;
shape3(rising) = -1 + 2*u3(rising)/triangle_width;
shape3(~rising) = 1 - 2*(u3(~rising) - triangle_width) ...
    /(1 - triangle_width);
instantaneous_omega3 = omega3_initial + ...
    (omega3_final - omega3_initial)*(shape3 + 1)/2;
s3 = exp(1j*cumsum(instantaneous_omega3));

% S4: repeated rising sawtooth sweep from bins 192 to 288.
T4 = 8192;
omega4_initial = 2*pi*(24/128);
omega4_final = 2*pi*(36/128);
shape4 = -1 + 2*mod(n, T4)/T4;
instantaneous_omega4 = omega4_initial + ...
    (omega4_final - omega4_initial)*(shape4 + 1)/2;
s4 = exp(1j*cumsum(instantaneous_omega4));

% Composite signal.
x = s1 + s2 + s3 + s4;

%% 2. ANALYSIS PARAMETERS
N = 1024;
w = 0.5 - 0.5*cos(2*pi*(0:N-1)'/(N-1));  % Symmetric Hann window

%% 3. CUSTOM ESTIMATORS
P_periodogram = mperiodogram(x, N, w);
P_welch = mwelch(x, N, 512, w);            % 50 percent overlap

dt = 128;
df = 2*pi/N;
rvar = 1;
P_stft = mstft(x, dt, df, rvar, w);

%% 4. AXES AND DECIBEL CONVERSION
normalized_frequency = (0:N-1)'/N*2;       % Units of pi rad/sample
P_periodogram_dB = 10*log10(max(P_periodogram, eps));
P_welch_dB = 10*log10(max(P_welch, eps));
P_stft_dB = 10*log10(max(P_stft, eps));
frame_centers = (0:size(P_stft, 2)-1)*dt + (N-1)/2;
fft_bins = 0:N-1;

%% 5. FIGURES
figure(1);
plot(normalized_frequency, P_periodogram_dB, 'LineWidth', 1.0);
grid on;
title('Periodogram of the first 1024-sample segment');
xlabel('Normalized angular frequency (x pi rad/sample)');
ylabel('Power (dB)');
xlim([0 2]);

figure(2);
plot(normalized_frequency, P_welch_dB, 'LineWidth', 1.0);
grid on;
title('Welch estimate of the complete record');
xlabel('Normalized angular frequency (x pi rad/sample)');
ylabel('Power (dB)');
xlim([0 2]);

figure(3);
imagesc(frame_centers, fft_bins, P_stft_dB);
axis xy;
xlabel('Sample index');
ylabel('FFT bin');
title('Short-time Fourier power representation');
colorbar;

figure(4);
time_selection = 1:10:length(frame_centers);
frequency_selection = 1:4:N;
surf(frame_centers(time_selection), fft_bins(frequency_selection), ...
    P_stft_dB(frequency_selection, time_selection), 'EdgeColor', 'none');
xlabel('Sample index');
ylabel('FFT bin');
zlabel('Power (dB)');
title('Three-dimensional time-frequency representation');
view(95, 30);

%% 6. SAVE NUMERICAL RESULTS
save('practice_results.mat', 'x', 's1', 's2', 's3', 's4', ...
    'P_periodogram', 'P_welch', 'P_stft', 'N', 'dt', 'df', ...
    'normalized_frequency', 'frame_centers', 'fft_bins');
