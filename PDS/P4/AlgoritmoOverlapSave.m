clear;
close all;
clc;

% COMPLETE FAST-CONVOLUTION AND OVERLAP-SAVE COMPARISON
% A long random sequence is filtered by a 101-tap FIR low-pass filter.
% Three implementations are compared:
%   1. Direct time-domain convolution.
%   2. One complete FFT-based linear convolution.
%   3. FFT overlap-save block processing.

rng(0);

fs = 2048;
input_length = 2048;

x = randn(1, input_length);

L = 101;
h = fir1(L-1, 0.25);

output_length = input_length + L - 1;
time = (0:output_length-1)/fs;

%% 1. Direct linear convolution
y_direct = conv(x, h);

figure;
plot(time, y_direct);
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title('Direct time-domain convolution');

%% 2. Complete FFT-based linear convolution
% The FFT length must be at least input_length + L - 1.
Nfft_full = 2^nextpow2(output_length);

X = fft(x, Nfft_full);
H_full = fft(h, Nfft_full);

y_fft = real(ifft(X .* H_full));
y_fft = y_fft(1:output_length);

figure;
plot(time, y_fft);
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title('Complete FFT-based linear convolution');

figure;
plot(time, y_direct - y_fft);
grid on;
xlabel('Time (s)');
ylabel('Error');
title('Difference: direct convolution minus complete FFT convolution');

%% 3. Overlap-save block processing
M = 256;                    % FFT and block length
R = M - L + 1;              % New samples per block

if M < L
    error('The overlap-save FFT length M must be at least L.');
end

% Add zeros to produce the complete convolution tail.
x_padded = [x zeros(1, L-1)];

% Form overlapping blocks. buffer inserts the initial L-1 zeros.
x_blocks = buffer(x_padded, M, L-1);

% Calculate the filter FFT once.
H_block = fft(h, M).';

% Process all blocks.
X_blocks = fft(x_blocks, M, 1);
Y_blocks = X_blocks .* repmat(H_block, 1, size(X_blocks, 2));
y_blocks = real(ifft(Y_blocks, M, 1));

% Discard the first L-1 circularly aliased samples from each block.
valid_blocks = y_blocks(L:M, :);

% Assemble and trim the output.
y_overlap_save = reshape(valid_blocks, 1, []);
y_overlap_save = y_overlap_save(1:output_length);

figure;
plot(time, y_overlap_save);
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title('FFT overlap-save output');

figure;
plot(time, y_direct - y_overlap_save);
grid on;
xlabel('Time (s)');
ylabel('Error');
title('Difference: direct convolution minus overlap-save');

%% Output spectrum
Nfft_spectrum = 4096;
Y_spectrum = fftshift(fft(y_direct, Nfft_spectrum));
omega = 2*pi*(-Nfft_spectrum/2:Nfft_spectrum/2-1)/Nfft_spectrum;
Y_dB = 20*log10(abs(Y_spectrum) + eps);

figure;
plot(omega, Y_dB);
grid on;
xlim([-pi pi]);
xlabel('\omega (rad/sample)');
ylabel('Magnitude (dB)');
title('Spectrum of the filtered output');

fprintf('Input length: %d samples\n', input_length);
fprintf('Filter length: %d coefficients\n', L);
fprintf('Complete FFT length: %d\n', Nfft_full);
fprintf('Overlap-save FFT length: %d\n', M);
fprintf('Overlap-save advance: %d samples per block\n', R);
fprintf('Maximum direct/FFT error: %.3e\n', ...
        max(abs(y_direct - y_fft)));
fprintf('Maximum direct/overlap-save error: %.3e\n', ...
        max(abs(y_direct - y_overlap_save)));
