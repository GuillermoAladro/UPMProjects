function [x, f_command, f_real] = dds_generate_lfm( ...
    f_start, f_end, sweep_duration, total_duration, fs, ...
    accumulator_bits, lut_bits, lut)
%DDS_GENERATE_LFM Generate a repetitive linear-frequency-modulated signal.
%
%   The frequency rises linearly from f_start to f_end during each sweep.
%   It then returns to f_start, producing a sawtooth frequency law.

    if f_start < 0 || f_end <= f_start || f_end >= fs/2
        error('Use 0 <= f_start < f_end < fs/2.');
    end
    if sweep_duration <= 0 || total_duration <= 0
        error('Durations must be positive.');
    end

    num_samples = round(total_duration * fs);
    samples_per_sweep = round(sweep_duration * fs);
    if samples_per_sweep < 2
        error('The sweep must contain at least two samples.');
    end

    sweep_position = mod(0:num_samples-1, samples_per_sweep);
    f_command = f_start + (f_end - f_start) .* ...
        sweep_position / (samples_per_sweep - 1);

    tuning_words = uint64(round(f_command * 2^accumulator_bits / fs));
    f_real = double(tuning_words) * fs / 2^accumulator_bits;

    phase_modulus = uint64(2^accumulator_bits);
    phase_accumulator = uint64(0);
    shift = accumulator_bits - lut_bits;
    x = zeros(1, num_samples);

    for n = 1:num_samples
        phase_accumulator = mod(phase_accumulator + tuning_words(n), ...
            phase_modulus);
        lut_index_zero_based = bitshift(phase_accumulator, -shift);
        lut_index_matlab = double(lut_index_zero_based) + 1;
        x(n) = lut(lut_index_matlab);
    end
end
