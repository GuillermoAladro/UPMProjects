function [xout, yout] = mcordic_r2(xin, yin, angle_table, angle)
%MCORDIC_R2 CORDIC rotation mode with full-circle angle support.
%
%   [XOUT, YOUT] = MCORDIC_R2(XIN, YIN, ANGLE_TABLE, ANGLE)
%   rotates the input vector [XIN, YIN] by ANGLE radians using only
%   additions, subtractions, and powers-of-two scale factors.
%
%   ANGLE_TABLE must contain atan(2^(-i)) for i = 0, 1, ..., M-1.
%   The caller is responsible for compensating the CORDIC gain in the
%   input vector when a unit-amplitude rotation is required.
%
%   The initial +/-pi/2 rotation extends the convergence interval so that
%   input angles in [-pi, pi] can be processed directly.

    z = angle;

    % Direction for the initial +/-pi/2 rotation.
    if z >= 0
        d = 1;
    else
        d = -1;
    end

    % Initial exact rotation by d*pi/2:
    % [x; y] <- R(d*pi/2) * [xin; yin]
    y = xin * d;
    x = -yin * d;
    z = z - d * pi / 2;

    % Iterative CORDIC micro-rotations.
    for k = 1:length(angle_table)
        if z >= 0
            d = 1;
        else
            d = -1;
        end

        shift = 2^(-(k - 1));
        x_next = x - d * y * shift;
        y_next = y + d * x * shift;
        z_next = z - d * angle_table(k);

        x = x_next;
        y = y_next;
        z = z_next;
    end

    xout = x;
    yout = y;
end
