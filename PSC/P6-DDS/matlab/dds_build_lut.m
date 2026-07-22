function [lut, lut_q31] = dds_build_lut(lut_bits)
%DDS_BUILD_LUT Create a full-cycle sine lookup table in Q1.31 format.
%
%   [lut, lut_q31] = dds_build_lut(lut_bits)
%
%   lut_bits  Number of phase-address bits used by the LUT.
%   lut       Normalized floating-point values in approximately [-1, 1).
%   lut_q31   Signed 32-bit integer representation of the same samples.

    validateattributes(lut_bits, {'numeric'}, ...
        {'scalar', 'integer', 'positive', '<=', 24});

    lut_size = 2^lut_bits;
    phase = (0:lut_size-1) * (2*pi/lut_size);
    sine_samples = sin(phase);

    % Q1.31 scaling. The positive peak is limited to 2^31 - 1.
    lut_q31 = int32(round(sine_samples * (2^31 - 1)));
    lut = double(lut_q31) / 2^31;
end
