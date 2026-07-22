%% DIRECT DIGITAL SYNTHESIS (DDS) LABORATORY PRACTICE
clear; clc; close all;

%% 1. Configuration
fs = 48e3;                    % Sampling frequency [Hz]
accumulator_bits = 32;        % Phase-accumulator width
lut_bits = 11;                % Number of phase bits used to address the LUT
lut_size = 2^lut_bits;

[lut, lut_q31] = dds_build_lut(lut_bits);
frequency_resolution = fs / 2^accumulator_bits;

fprintf('DDS frequency resolution: %.12f Hz\n', frequency_resolution);
fprintf('LUT size: %d samples\n', lut_size);
fprintf('Discarded phase bits: %d\n\n', accumulator_bits-lut_bits);

output_folder = fullfile(pwd, 'generated_figures');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

%% 2. Fixed tones: 400 Hz, 600 Hz and 1 kHz
requested_frequencies = [400, 600, 1000];
num_tone_samples = round(fs);            % One second per tone

for tone_number = 1:length(requested_frequencies)
    requested_frequency = requested_frequencies(tone_number);
    [x, tuning_word, actual_frequency] = dds_generate_tone( ...
        requested_frequency, fs, num_tone_samples, ...
        accumulator_bits, lut_bits, lut);

    frequency_error = actual_frequency - requested_frequency;
    fprintf(['Tone %7.2f Hz | M = %10u | actual = %.12f Hz | ' ...
        'error = %+0.3e Hz\n'], requested_frequency, tuning_word, ...
        actual_frequency, frequency_error);

    time = (0:num_tone_samples-1) / fs;
    spectrum = fft(x) / num_tone_samples;
    positive_bins = 1:(num_tone_samples/2 + 1);
    frequency_axis = (positive_bins-1) * fs / num_tone_samples;
    magnitude_db = 20*log10(abs(spectrum(positive_bins)) + eps);
    magnitude_db = magnitude_db - max(magnitude_db);

    figure('Name', sprintf('DDS tone %.0f Hz', requested_frequency));
    subplot(2,1,1);
    visible_samples = 1:round(8*fs/requested_frequency);
    plot(1e3*time(visible_samples), x(visible_samples), 'LineWidth', 1.1);
    grid on;
    title(sprintf('DDS output at %.0f Hz', requested_frequency));
    xlabel('Time [ms]'); ylabel('Amplitude');

    subplot(2,1,2);
    plot(frequency_axis, magnitude_db, 'LineWidth', 1.1);
    grid on; xlim([0, 5000]); ylim([-140, 5]);
    title('Single-sided magnitude spectrum');
    xlabel('Frequency [Hz]'); ylabel('Magnitude [dB, normalized]');

    print(gcf, fullfile(output_folder, ...
        sprintf('tone_%04d_Hz.png', requested_frequency)), '-dpng', '-r200');
end

%% 3. Repetitive LFM signal: 500 Hz to 3 kHz
f_start = 500;
f_end = 3000;
sweep_duration = 1.0;         % One ramp per second
total_duration = 2.0;         % Two consecutive ramps

[x_lfm, f_command, f_real] = dds_generate_lfm( ...
    f_start, f_end, sweep_duration, total_duration, fs, ...
    accumulator_bits, lut_bits, lut);

num_lfm_samples = length(x_lfm);
time_lfm = (0:num_lfm_samples-1) / fs;

figure('Name', 'LFM frequency law');
plot(time_lfm, f_real, 'LineWidth', 1.1);
grid on; xlim([0, total_duration]);
title('DDS LFM instantaneous frequency');
xlabel('Time [s]'); ylabel('Frequency [Hz]');
print(gcf, fullfile(output_folder, 'lfm_frequency_law.png'), ...
    '-dpng', '-r200');

% Whole-record spectrum
spectrum_lfm = fft(x_lfm) / num_lfm_samples;
positive_bins = 1:(num_lfm_samples/2 + 1);
frequency_axis_lfm = (positive_bins-1) * fs / num_lfm_samples;
magnitude_lfm_db = 20*log10(abs(spectrum_lfm(positive_bins)) + eps);
magnitude_lfm_db = magnitude_lfm_db - max(magnitude_lfm_db);

figure('Name', 'LFM spectrum');
plot(frequency_axis_lfm, magnitude_lfm_db, 'LineWidth', 1.1);
grid on; xlim([0, 5000]); ylim([-100, 5]);
title('Spectrum of the repetitive LFM signal');
xlabel('Frequency [Hz]'); ylabel('Magnitude [dB, normalized]');
print(gcf, fullfile(output_folder, 'lfm_spectrum.png'), ...
    '-dpng', '-r200');

% Toolbox-independent spectrogram
[S, f_stft, t_stft] = dds_simple_spectrogram( ...
    x_lfm, fs, 1024, 512, 1024);
S_db = 20*log10(abs(S) + eps);
S_db = S_db - max(S_db(:));

figure('Name', 'LFM spectrogram');
imagesc(t_stft, f_stft, S_db);
axis xy; ylim([0, 5000]); caxis([-70, 0]);
colorbar; title('Spectrogram of the DDS LFM signal');
xlabel('Time [s]'); ylabel('Frequency [Hz]');
print(gcf, fullfile(output_folder, 'lfm_spectrogram.png'), ...
    '-dpng', '-r200');

%% 4. Save reproducible numerical results
save('DDS_reference_results.mat', 'fs', 'accumulator_bits', 'lut_bits', ...
    'lut_q31', 'requested_frequencies', 'f_start', 'f_end', ...
    'sweep_duration', 'total_duration', 'f_command', 'f_real');
