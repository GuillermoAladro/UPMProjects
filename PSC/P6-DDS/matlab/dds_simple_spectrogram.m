function [S, f, t] = dds_simple_spectrogram(x, fs, window_length, overlap, nfft)
%DDS_SIMPLE_SPECTROGRAM Compute an STFT without requiring extra toolboxes.

    if overlap >= window_length
        error('overlap must be smaller than window_length.');
    end
    if nfft < window_length
        error('nfft must be at least window_length.');
    end

    x = x(:);
    hop = window_length - overlap;
    number_of_frames = 1 + floor((length(x) - window_length) / hop);
    if number_of_frames < 1
        error('The input signal is shorter than the analysis window.');
    end

    n = (0:window_length-1)';
    window = 0.5 - 0.5*cos(2*pi*n/(window_length-1));
    positive_bins = floor(nfft/2) + 1;
    S = zeros(positive_bins, number_of_frames);
    t = zeros(1, number_of_frames);

    for frame = 1:number_of_frames
        first_sample = (frame-1)*hop + 1;
        segment = x(first_sample:first_sample+window_length-1) .* window;
        spectrum = fft(segment, nfft);
        S(:, frame) = spectrum(1:positive_bins);
        t(frame) = (first_sample - 1 + (window_length-1)/2) / fs;
    end

    f = (0:positive_bins-1)' * fs / nfft;
end
