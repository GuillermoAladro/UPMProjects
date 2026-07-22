function [x, tuning_word, actual_frequency] = dds_generate_tone( ...
    frequency, fs, num_samples, accumulator_bits, lut_bits, lut)
%DDS_GENERATE_TONE Generate one sinusoid with a phase-accumulator DDS.
%
%   The tuning word is constrained to an integer, as it would be in a
%   digital hardware implementation.

    validateattributes(frequency, {'numeric'}, {'scalar', 'nonnegative'});
    validateattributes(fs, {'numeric'}, {'scalar', 'positive'});
    validateattributes(num_samples, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    if frequency >= fs/2
        error('The requested tone must be below the Nyquist frequency.');
    end

    phase_modulus = uint64(2^accumulator_bits);
    tuning_word = uint64(round(frequency * 2^accumulator_bits / fs));
    actual_frequency = double(tuning_word) * fs / 2^accumulator_bits;

    phase_accumulator = uint64(0);
    x = zeros(1, num_samples);
    shift = accumulator_bits - lut_bits;

    for n = 1:num_samples
        phase_accumulator = mod(phase_accumulator + tuning_word, ...
            phase_modulus);
        lut_index_zero_based = bitshift(phase_accumulator, -shift);
        lut_index_matlab = double(lut_index_zero_based) + 1;
        x(n) = lut(lut_index_matlab);
    end
end
