function STFT = mstft(x, dt, df, rvar, w)
%MSTFT Short-time spectral analysis using the custom periodogram.
%   STFT = MSTFT(x, dt, df, rvar, w) creates overlapping time frames and
%   stores one power spectrum per column.
%
%   Inputs
%       x    : input signal vector
%       dt   : time hop between frames, in samples
%       df   : angular-frequency-bin spacing, rad/sample
%       rvar : temporal averaging factor (1 = no averaging)
%       w    : analysis window
%
%   Output
%       STFT : N-by-number_of_frames time-frequency power matrix
%
%   The FFT length follows df = 2*pi/N. When rvar is greater than one,
%   each output column is the mean of the current and previous rvar-1
%   periodograms. This optional smoothing reduces variance at the cost of
%   temporal detail while preserving the frequency-grid size.

    if nargin ~= 5
        error('mstft requires exactly five inputs: x, dt, df, rvar and w.');
    end
    if ~isvector(x) || isempty(x)
        error('x must be a non-empty vector.');
    end
    if ~isscalar(dt) || dt <= 0 || dt ~= floor(dt)
        error('dt must be a positive integer number of samples.');
    end
    if ~isscalar(df) || df <= 0
        error('df must be positive.');
    end
    if ~isscalar(rvar) || rvar < 1 || rvar ~= floor(rvar)
        error('rvar must be a positive integer.');
    end

    x = x(:);
    w = w(:);

    % Frequency spacing of an N-point DFT: df = 2*pi/N.
    N = round(2*pi / df);
    if N <= 0
        error('The selected df produces an invalid FFT length.');
    end
    if length(w) ~= N
        error('The analysis window length must equal round(2*pi/df).');
    end
    if dt > N
        error('dt must not exceed the window length N.');
    end

    signal_length = length(x);
    if signal_length < N
        x = [x; zeros(N - signal_length, 1, class(x))];
        start_indices = 1;
    else
        start_indices = 1:dt:(signal_length - N + 1);
    end

    number_of_frames = length(start_indices);
    raw_periodograms = zeros(N, number_of_frames);

    for k = 1:number_of_frames
        first_sample = start_indices(k);
        frame = x(first_sample:first_sample + N - 1);
        raw_periodograms(:, k) = mperiodogram(frame, N, w);
    end

    if rvar == 1
        STFT = raw_periodograms;
    else
        STFT = zeros(size(raw_periodograms));
        for k = 1:number_of_frames
            first_average = max(1, k - rvar + 1);
            STFT(:, k) = mean(raw_periodograms(:, first_average:k), 2);
        end
    end
end
