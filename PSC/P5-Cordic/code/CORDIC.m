%% CORDIC ALGORITHM - FIXED TONES AND REPEATED LFM SWEEP
% This script uses mcordic_r2.m to generate cosine/sine pairs without
% calling sin() or cos() inside the sample-generation loops.

clear;
clc;
close all;

%% General parameters
fs = 44e3;                  % Sampling frequency [Hz]
steps = 32;                 % CORDIC iterations (approximately 32-bit precision)
angle_table = atan(2.^(-(0:steps-1)));

% CORDIC gain for the selected number of iterations.
cordic_gain = prod(sqrt(1 + 2.^(-2*(0:steps-1))));

% Fixed input vector. The desired output amplitude is 0.5.
xin = 0.5;
yin = 0;

% Simulated 1T31-style input preparation. The value is first truncated to
% 21 fractional bits and then pre-scaled by the inverse CORDIC gain.
x_quantized = (floor(xin * 2^21) * 2^10) / 2^31;
y_quantized = (floor(yin * 2^21) * 2^10) / 2^31;
x_actual = x_quantized / cordic_gain;
y_actual = y_quantized / cordic_gain;

fprintf('CORDIC steps: %d\n', steps);
fprintf('CORDIC gain: %.12f\n', cordic_gain);
fprintf('Pre-scaled initial x: %.12f\n\n', x_actual);

% Folder used by saveas().
output_folder = 'results_figures';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

%% PART 1 - Fixed tones: 440 Hz, 1 kHz, and 2.3 kHz
tone_frequencies = [440, 1000, 2300];
tone_duration = 1;                         % Seconds
N_tone = round(tone_duration * fs);
time_tone = (0:N_tone-1) / fs;
number_of_tones = length(tone_frequencies);

x_tones = zeros(number_of_tones, N_tone);  % Cosine component
y_tones = zeros(number_of_tones, N_tone);  % Sine component
tone_spectra = zeros(number_of_tones, floor(N_tone/2));
frequency_axis_tone = (0:floor(N_tone/2)-1) * (fs / N_tone);

for tone_index = 1:number_of_tones
    frequency = tone_frequencies(tone_index);
    phase = 0;
    phase_increment = 2 * pi * frequency / fs;

    for n = 1:N_tone
        [x_rotated, y_rotated] = mcordic_r2( ...
            x_actual, y_actual, angle_table, phase);

        x_tones(tone_index, n) = x_rotated;
        y_tones(tone_index, n) = y_rotated;

        % Phase accumulator update and wrapping to [-pi, pi].
        phase = phase + phase_increment;
        if phase > pi
            phase = phase - 2*pi;
        elseif phase < -pi
            phase = phase + 2*pi;
        end
    end

    complex_tone = x_tones(tone_index, :) + 1i*y_tones(tone_index, :);
    tone_fft = fft(complex_tone) / N_tone;
    tone_power = abs(tone_fft).^2;
    tone_spectra(tone_index, :) = tone_power(1:floor(N_tone/2));

    [~, peak_bin] = max(tone_spectra(tone_index, :));
    measured_frequency = frequency_axis_tone(peak_bin);
    fprintf('Tone %4d Hz -> FFT peak at %.1f Hz\n', frequency, measured_frequency);
end

% Time-domain plots (first 5 ms).
visible_samples = round(0.005 * fs);
figure(1);
for tone_index = 1:number_of_tones
    subplot(number_of_tones, 2, 2*tone_index-1);
    plot(time_tone(1:visible_samples), ...
         x_tones(tone_index, 1:visible_samples), 'LineWidth', 1.1);
    grid on;
    title(sprintf('%g Hz - cosine output', tone_frequencies(tone_index)));
    xlabel('Time (s)');
    ylabel('Amplitude');
    ylim([-0.55, 0.55]);

    subplot(number_of_tones, 2, 2*tone_index);
    plot(time_tone(1:visible_samples), ...
         y_tones(tone_index, 1:visible_samples), 'LineWidth', 1.1);
    grid on;
    title(sprintf('%g Hz - sine output', tone_frequencies(tone_index)));
    xlabel('Time (s)');
    ylabel('Amplitude');
    ylim([-0.55, 0.55]);
end
sgtitle('CORDIC-generated fixed tones');
saveas(gcf, fullfile(output_folder, '01_fixed_tones_time.png'));

% Frequency-domain plots.
figure(2);
for tone_index = 1:number_of_tones
    subplot(number_of_tones, 1, tone_index);
    plot(frequency_axis_tone, 10*log10(tone_spectra(tone_index, :) + eps), ...
         'LineWidth', 1.1);
    grid on;
    xlim([0, 4000]);
    title(sprintf('CORDIC spectrum - %g Hz tone', tone_frequencies(tone_index)));
    xlabel('Frequency (Hz)');
    ylabel('Power (dB)');
end
saveas(gcf, fullfile(output_folder, '02_fixed_tones_spectrum.png'));

%% PART 2 - Repeated LFM sweep from 500 Hz to 3 kHz
f_start = 500;
f_end = 3000;
lfm_duration = 2;                       % Total duration [s]
ramp_duration = 1;                      % Duration of each repeated ramp [s]
N_lfm = round(lfm_duration * fs);
samples_per_ramp = round(ramp_duration * fs);
frequency_increment = (f_end - f_start) / (samples_per_ramp - 1);

phase = 0;
x_lfm = zeros(1, N_lfm);
y_lfm = zeros(1, N_lfm);
instantaneous_frequency = zeros(1, N_lfm);

for k = 1:N_lfm
    ramp_sample = mod(k - 1, samples_per_ramp);
    current_frequency = f_start + ramp_sample * frequency_increment;
    instantaneous_frequency(k) = current_frequency;

    phase_increment = 2 * pi * current_frequency / fs;
    phase = phase + phase_increment;

    if phase > pi
        phase = phase - 2*pi;
    elseif phase < -pi
        phase = phase + 2*pi;
    end

    [x_rotated, y_rotated] = mcordic_r2( ...
        x_actual, y_actual, angle_table, phase);
    x_lfm(k) = x_rotated;
    y_lfm(k) = y_rotated;
end

time_lfm = (0:N_lfm-1) / fs;
complex_lfm = x_lfm + 1i*y_lfm;

% Time-domain detail around the ramp reset at t = 1 s.
figure(3);
plot(time_lfm, y_lfm, 'LineWidth', 1.0);
grid on;
xlim([0.995, 1.005]);
ylim([-0.55, 0.55]);
title('CORDIC LFM signal around the 1 s ramp reset');
xlabel('Time (s)');
ylabel('Sine component');
saveas(gcf, fullfile(output_folder, '03_lfm_time_detail.png'));

% Overall LFM spectrum.
lfm_fft = fft(complex_lfm) / N_lfm;
lfm_power = abs(lfm_fft).^2;
frequency_axis_lfm = (0:N_lfm-1) * (fs / N_lfm);

figure(4);
plot(frequency_axis_lfm(1:floor(N_lfm/2)), ...
     10*log10(lfm_power(1:floor(N_lfm/2)) + eps), 'LineWidth', 1.0);
grid on;
xlim([0, 5000]);
title('Spectrum of the repeated CORDIC LFM waveform');
xlabel('Frequency (Hz)');
ylabel('Power (dB)');
saveas(gcf, fullfile(output_folder, '04_lfm_spectrum.png'));

% Toolbox-independent short-time Fourier transform.
window_length = 1024;
overlap = 512;
hop = window_length - overlap;
nfft = 1024;
number_of_frames = floor((N_lfm - window_length) / hop) + 1;

hann_window = 0.5 - 0.5*cos(2*pi*(0:window_length-1)'/(window_length-1));
stft_matrix = zeros(nfft/2 + 1, number_of_frames);

for frame_index = 1:number_of_frames
    first_sample = (frame_index - 1) * hop + 1;
    frame_samples = first_sample:first_sample + window_length - 1;
    windowed_frame = complex_lfm(frame_samples).' .* hann_window;
    frame_fft = fft(windowed_frame, nfft);
    stft_matrix(:, frame_index) = frame_fft(1:nfft/2 + 1);
end

stft_frequency = (0:nfft/2) * fs / nfft;
stft_time = ((0:number_of_frames-1) * hop + window_length/2) / fs;

figure(5);
imagesc(stft_time, stft_frequency, 20*log10(abs(stft_matrix) + eps));
axis xy;
ylim([0, 5000]);
colorbar;
title('Spectrogram of the repeated CORDIC LFM waveform');
xlabel('Time (s)');
ylabel('Frequency (Hz)');
saveas(gcf, fullfile(output_folder, '05_lfm_spectrogram.png'));

%% PART 3 - Numerical validation against MATLAB sin/cos
validation_angles = linspace(-pi, pi, 2001);
x_validation = zeros(size(validation_angles));
y_validation = zeros(size(validation_angles));

for index = 1:length(validation_angles)
    [x_validation(index), y_validation(index)] = mcordic_r2( ...
        x_actual, y_actual, angle_table, validation_angles(index));
end

x_reference = xin * cos(validation_angles);
y_reference = xin * sin(validation_angles);
vector_error = sqrt((x_validation - x_reference).^2 + ...
                    (y_validation - y_reference).^2);

fprintf('\nMaximum vector error over [-pi, pi]: %.3e\n', max(vector_error));
fprintf('RMS vector error over [-pi, pi]: %.3e\n', ...
        sqrt(mean(vector_error.^2)));

figure(6);
semilogy(validation_angles, vector_error + eps, 'LineWidth', 1.1);
grid on;
title('CORDIC vector error with 32 iterations');
xlabel('Angle (rad)');
ylabel('Euclidean error');
saveas(gcf, fullfile(output_folder, '06_cordic_error.png'));

%% Save generated data for later analysis
save('cordic_results.mat', ...
     'fs', 'steps', 'cordic_gain', 'tone_frequencies', ...
     'time_tone', 'x_tones', 'y_tones', 'tone_spectra', ...
     'frequency_axis_tone', 'time_lfm', 'x_lfm', 'y_lfm', ...
     'instantaneous_frequency', 'frequency_axis_lfm', 'lfm_power', ...
     'validation_angles', 'vector_error');

fprintf('\nFigures were saved in the folder: %s\n', output_folder);
fprintf('Numerical results were saved in cordic_results.mat\n');
