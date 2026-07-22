clear;
close all;
clc;

% FAST FILTERING WITH THE OVERLAP-SAVE METHOD
% This script compares direct linear convolution with FFT-based block
% filtering. A random input signal is filtered by a random FIR impulse
% response.

rng(0);                    % Reproducible random signals

x = randn(1, 1000);        % Input signal
h = randn(1, 100);         % FIR impulse response

P = length(x);             % Input length
L = length(h);             % Filter length

% FFT/block length. It must satisfy M >= L.
% A power of two is selected for efficient FFT computation.
M = 2^ceil(log2(L));

% Number of new input samples processed by each block.
R = M - L + 1;

fprintf('P = %d: length of x[n]\n', P);
fprintf('L = %d: length of h[n]\n', L);
fprintf('M = %d: FFT and block length\n', M);
fprintf('R = %d: new samples per block\n', R);

%% Reference result: direct linear convolution
y_reference = conv(x, h);

figure;
stem(0:length(y_reference)-1, y_reference, '.');
grid on;
xlabel('Sample index');
ylabel('Amplitude');
title('Reference output using direct linear convolution');

%% Overlap-save implementation

% Append zeros so that the complete convolution tail is generated.
x_padded = [x zeros(1, L-1)];

% buffer creates M-sample columns with an overlap of L-1 samples.
% Its default behavior inserts L-1 zeros before the first input sample,
% which provides the initial conditions required by overlap-save.
x_blocks = buffer(x_padded, M, L-1);

% Calculate the filter spectrum only once.
H = fft(h, M).';

% Transform every block, multiply in the frequency domain, and return to
% the time domain.
X_blocks = fft(x_blocks, M, 1);
Y_blocks = X_blocks .* repmat(H, 1, size(X_blocks, 2));
y_blocks = real(ifft(Y_blocks, M, 1));

% The first L-1 samples of every block are corrupted by circular aliasing.
% Keep only the final R = M-L+1 valid samples.
y_valid_blocks = y_blocks(L:M, :);

% Concatenate the valid block outputs and trim to the exact convolution
% length.
y_overlap_save = reshape(y_valid_blocks, 1, []);
y_overlap_save = y_overlap_save(1:P+L-1);

figure;
stem(0:length(y_overlap_save)-1, y_overlap_save, '.');
grid on;
xlabel('Sample index');
ylabel('Amplitude');
title('Output using FFT overlap-save filtering');

%% Numerical comparison
error_signal = y_reference - y_overlap_save;
max_error = max(abs(error_signal));

figure;
plot(0:length(error_signal)-1, error_signal);
grid on;
xlabel('Sample index');
ylabel('Error');
title('Difference: direct convolution minus overlap-save');

fprintf('Maximum absolute error: %.3e\n', max_error);

%% Output spectrum
Nfft_spectrum = 2048;
Y = fftshift(fft(y_reference, Nfft_spectrum));
omega = 2*pi*(-Nfft_spectrum/2:Nfft_spectrum/2-1)/Nfft_spectrum;

figure;
plot(omega, abs(Y), 'LineWidth', 1);
grid on;
xlim([-pi pi]);
xlabel('\omega (rad/sample)');
ylabel('|Y(e^{j\omega})|');
title('Magnitude spectrum of the filtered output');
