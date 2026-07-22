function Periodogram = mperiodogram(x, N, w)
%MPERIODOGRAM Window-normalized two-sided periodogram.
%   Periodogram = MPERIODOGRAM(x, N, w) estimates the spectrum of the
%   first N samples of x after applying window w.
%
%   Inputs
%       x : input signal vector (real or complex)
%       N : segment and FFT length
%       w : analysis window with N samples
%
%   Output
%       Periodogram : N-by-1 window-normalized power spectrum

    if nargin ~= 3
        error('mperiodogram requires exactly three inputs: x, N and w.');
    end
    if ~isvector(x) || isempty(x)
        error('x must be a non-empty vector.');
    end
    if ~isscalar(N) || N <= 0 || N ~= floor(N)
        error('N must be a positive integer.');
    end

    x = x(:);
    w = w(:);

    if length(x) < N
        error('N must be less than or equal to the length of x.');
    end
    if length(w) ~= N
        error('The analysis window must contain exactly N samples.');
    end

    % Keep one segment and apply the window sample by sample.
    x_segment = x(1:N);
    x_windowed = x_segment .* w;

    % N-point DFT and squared magnitude.
    X_windowed = fft(x_windowed, N);
    magnitude_squared = abs(X_windowed).^2;

    % Window-energy normalization. This corrects the power change caused
    % by the analysis window. No sampling-frequency division is applied,
    % so the result is a normalized power spectrum rather than W/Hz.
    U = sum(abs(w).^2);
    if U <= 0
        error('The analysis window must have non-zero energy.');
    end

    Periodogram = magnitude_squared / U;
end
