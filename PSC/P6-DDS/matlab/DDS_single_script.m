%% DDS PRACTICE - SELF-CONTAINED VERSION
% This file reproduces the complete practice without auxiliary functions.
clear; clc; close all;

fs = 48e3;
accumulator_bits = 32;
lut_bits = 11;
lut_size = 2^lut_bits;
phase_modulus = uint64(2^accumulator_bits);
shift = accumulator_bits - lut_bits;

% Full-cycle sine LUT, quantized in Q1.31.
phase_table = (0:lut_size-1) * 2*pi/lut_size;
lut_q31 = int32(round(sin(phase_table) * (2^31 - 1)));
lut = double(lut_q31) / 2^31;

%% Part 1: fixed tones
frequencies = [400, 600, 1000];
N = round(fs);

for tone = 1:length(frequencies)
    f = frequencies(tone);
    M = uint64(round(f * 2^accumulator_bits / fs));
    phase_accumulator = uint64(0);
    x = zeros(1, N);

    for n = 1:N
        phase_accumulator = mod(phase_accumulator + M, phase_modulus);
        index_zero_based = bitshift(phase_accumulator, -shift);
        x(n) = lut(double(index_zero_based) + 1);
    end

    t = (0:N-1)/fs;
    X = fft(x)/N;
    bins = 1:(N/2+1);
    f_axis = (bins-1)*fs/N;
    X_db = 20*log10(abs(X(bins)) + eps);
    X_db = X_db - max(X_db);

    figure;
    subplot(2,1,1);
    visible = 1:round(8*fs/f);
    plot(1e3*t(visible), x(visible)); grid on;
    title(sprintf('DDS output at %.0f Hz', f));
    xlabel('Time [ms]'); ylabel('Amplitude');

    subplot(2,1,2);
    plot(f_axis, X_db); grid on;
    xlim([0 5000]); ylim([-140 5]);
    title('Single-sided magnitude spectrum');
    xlabel('Frequency [Hz]'); ylabel('Magnitude [dB]');
end

%% Part 2: repetitive LFM signal
f_start = 500;
f_end = 3000;
sweep_duration = 1;
total_duration = 2;
N = round(total_duration*fs);
samples_per_sweep = round(sweep_duration*fs);
position = mod(0:N-1, samples_per_sweep);
f_inst = f_start + (f_end-f_start)*position/(samples_per_sweep-1);
M_sequence = uint64(round(f_inst*2^accumulator_bits/fs));

phase_accumulator = uint64(0);
x_lfm = zeros(1,N);
for n = 1:N
    phase_accumulator = mod(phase_accumulator + M_sequence(n), phase_modulus);
    index_zero_based = bitshift(phase_accumulator, -shift);
    x_lfm(n) = lut(double(index_zero_based)+1);
end

% Spectrum
X = fft(x_lfm)/N;
bins = 1:(N/2+1);
f_axis = (bins-1)*fs/N;
X_db = 20*log10(abs(X(bins))+eps);
X_db = X_db-max(X_db);
figure;
plot(f_axis,X_db); grid on; xlim([0 5000]); ylim([-100 5]);
title('Spectrum of the repetitive LFM signal');
xlabel('Frequency [Hz]'); ylabel('Magnitude [dB]');

% Spectrogram (requires Signal Processing Toolbox)
figure;
spectrogram(x_lfm,1024,512,1024,fs,'yaxis');
ylim([0 5]);
title('Spectrogram of the DDS LFM signal');
