function dibuja_plantilla(omega_p, omega_a, delta_p_lower, ...
                           delta_p_upper, delta_a, scale)
% DIBUJA_PLANTILLA Draws a low-pass or high-pass filter specification mask.
%
% Inputs:
%   omega_p       Passband edge frequency in rad/sample.
%   omega_a       Stopband edge frequency in rad/sample.
%   delta_p_lower Maximum allowed deviation below unity in the passband.
%   delta_p_upper Maximum allowed deviation above unity in the passband.
%   delta_a       Maximum allowed stopband magnitude.
%   scale         'lin' for linear magnitude or 'log' for decibels.
%
% The function shades the forbidden regions of the specification. A
% low-pass mask is drawn when omega_p < omega_a. A high-pass mask is drawn
% when omega_p > omega_a.

if nargin ~= 6
    error('dibuja_plantilla requires six input arguments.');
end

if delta_p_lower <= 0 || delta_p_lower >= 1
    error('delta_p_lower must be between 0 and 1.');
end

if delta_p_upper <= 0
    error('delta_p_upper must be positive.');
end

if delta_a <= 0 || delta_a >= 1
    error('delta_a must be between 0 and 1.');
end

is_lowpass = omega_p < omega_a;
was_held = ishold;
hold on;

face_color = [0.80 0.80 0.80];
face_alpha = 0.70;

switch lower(scale)
    case 'lin'
        y_min = 0;
        y_max = 1 + 4*delta_p_upper;
        pass_lower = 1 - delta_p_lower;
        pass_upper = 1 + delta_p_upper;

        if is_lowpass
            add_region(0, omega_p, y_min, pass_lower);
            add_region(0, omega_p, pass_upper, y_max);
            add_region(omega_a, pi, delta_a, y_max);
        else
            add_region(0, omega_a, delta_a, y_max);
            add_region(omega_p, pi, y_min, pass_lower);
            add_region(omega_p, pi, pass_upper, y_max);
        end

        axis([0 pi y_min y_max]);
        ylabel('Magnitude');

    case 'log'
        y_min = -120;
        y_max = 20*log10(1 + 4*delta_p_upper);
        pass_lower = 20*log10(1 - delta_p_lower);
        pass_upper = 20*log10(1 + delta_p_upper);
        stop_upper = 20*log10(delta_a);

        if is_lowpass
            add_region(0, omega_p, y_min, pass_lower);
            add_region(0, omega_p, pass_upper, y_max);
            add_region(omega_a, pi, stop_upper, y_max);
        else
            add_region(0, omega_a, stop_upper, y_max);
            add_region(omega_p, pi, y_min, pass_lower);
            add_region(omega_p, pi, pass_upper, y_max);
        end

        axis([0 pi y_min y_max]);
        ylabel('Magnitude (dB)');

    otherwise
        if ~was_held
            hold off;
        end
        error('The scale must be ''lin'' or ''log''.');
end

xlabel('\omega (rad/sample)');
grid on;
box on;

if ~was_held
    hold off;
end

    function add_region(x1, x2, y1, y2)
        patch([x1 x1 x2 x2], [y1 y2 y2 y1], face_color, ...
              'EdgeColor', 'none', 'FaceAlpha', face_alpha, ...
              'HandleVisibility', 'off');
    end
end
