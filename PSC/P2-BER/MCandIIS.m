%% MCandIIS.m
% Compact comparison between conventional Monte Carlo (MC) and
% variance-inflated importance sampling (IIS) for bipolar NRZ signaling.

clear; clc; close all;
rng(42, 'twister');

%% Conventional Monte Carlo
V = 1;                           % Signal amplitude in volts
threshold = 0;
N = 1e7;
SNRdB = -10:0.5:15;
sigma = V .* 10.^(-SNRdB/20);
ber_MC = zeros(size(SNRdB));
blockSize = 2e5;

tStart = tic;
for k = 1:numel(SNRdB)
    errors = 0;
    processed = 0;

    while processed < N
        M = min(blockSize, N - processed);
        bits = rand(1, M) > 0.5;
        tx = V * (2*double(bits) - 1);
        rx = tx + sigma(k)*randn(1, M);
        bits_rx = rx > threshold;
        errors = errors + nnz(xor(bits, bits_rx));
        processed = processed + M;
    end

    ber_MC(k) = errors/N;
end
fprintf('Monte Carlo time: %.3f s\n', toc(tStart));

ber_theory = 0.5*erfc(V ./ (sqrt(2)*sigma));
figure('Color','w');
semilogy(SNRdB, ber_MC, 'o-b', SNRdB, ber_theory, '--r', ...
         'LineWidth', 1.4);
grid on;
xlabel('SNR (dB)');
ylabel('BER');
title('Bipolar NRZ: Monte Carlo');
legend('Monte Carlo BER', 'Theoretical BER', 'Location', 'southwest');

%% Improved / emphasized importance sampling
N = 1e5;
SNRdB = 8:18;
sigma = V .* 10.^(-SNRdB/20);
B_IS = 4;
ber_IS = zeros(size(SNRdB));

tStart = tic;
for k = 1:numel(SNRdB)
    bits = rand(1, N) > 0.5;
    tx = V * (2*double(bits) - 1);

    n = B_IS*sigma(k)*randn(1, N);
    weight = B_IS * exp(-(n.^2/(2*sigma(k)^2))*(1 - 1/B_IS^2));

    rx = tx + n;
    bits_rx = rx > threshold;
    errorIndicator = xor(bits, bits_rx);

    % Weighted mean under the proposal density.
    ber_IS(k) = mean(weight .* double(errorIndicator));
end
fprintf('Importance-sampling time: %.3f s\n', toc(tStart));

ber_theory_IS = 0.5*erfc(V ./ (sqrt(2)*sigma));
figure('Color','w');
semilogy(SNRdB, ber_IS, 'o-g', SNRdB, ber_theory_IS, '--r', ...
         'LineWidth', 1.4);
grid on;
xlabel('SNR (dB)');
ylabel('BER');
title('Bipolar NRZ: Importance Sampling');
legend('Importance-sampling BER', 'Theoretical BER', ...
       'Location', 'southwest');
