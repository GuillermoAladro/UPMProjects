function Welch = mwelch(x, N, O, w)
%MWELCH Welch spectral estimate implemented from first principles.
%   Welch = MWELCH(x, N, O, w) divides x into overlapping segments,
%   windows each segment, computes its periodogram and averages all the
%   individual estimates.
%
%   Inputs
%       x : input signal vector (real or complex)
%       N : segment and FFT length
%       O : overlap between consecutive segments, in samples
%       w : analysis window with N samples
%
%   Output
%       Welch : N-by-1 averaged two-sided power spectrum

    if nargin ~= 4
        error('mwelch requires exactly four inputs: x, N, O and w.');
    end
    if ~isvector(x) || isempty(x)
        error('x must be a non-empty vector.');
    end
    if ~isscalar(N) || N <= 0 || N ~= floor(N)
        error('N must be a positive integer.');
    end
    if ~isscalar(O) || O < 0 || O >= N || O ~= floor(O)
        error('O must be an integer in the interval 0 <= O < N.');
    end

    x = x(:);
    w = w(:);
    if length(w) ~= N
        error('The analysis window must contain exactly N samples.');
    end

    hop = N - O;
    signal_length = length(x);

    % Standard Welch processing uses complete segments. If the record is
    % shorter than N, one zero-padded segment is used.
    if signal_length < N
        x = [x; zeros(N - signal_length, 1, class(x))];
        start_indices = 1;
    else
        start_indices = 1:hop:(signal_length - N + 1);
    end

    number_of_segments = length(start_indices);
    spectrum_accumulator = zeros(N, 1);

    for k = 1:number_of_segments
        first_sample = start_indices(k);
        current_segment = x(first_sample:first_sample + N - 1);
        spectrum_accumulator = spectrum_accumulator + ...
            mperiodogram(current_segment, N, w);
    end

    Welch = spectrum_accumulator / number_of_segments;
end
