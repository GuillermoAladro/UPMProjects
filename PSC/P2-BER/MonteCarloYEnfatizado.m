%% MonteCarloYEnfatizado.m
% BER estimation for bipolar NRZ transmission over an AWGN channel.
% The script compares conventional Monte Carlo simulation with
% variance-inflated importance sampling (emphasized sampling).
%
% Generated for the BER performance-analysis practice.

clear; clc; close all;
rng(42, 'twister');              % Reproducible random sequence

%% 1. Conventional Monte Carlo simulation
A = 1;                           % Bipolar signal amplitude: {-A,+A}
N_MC = 1e7;                      % Number of transmitted bits per SNR point
SNRdB_MC = -10:0.5:15;           % Sample SNR = 20*log10(A/sigma)
sigma_MC = A .* 10.^(-SNRdB_MC/20);
BER_MC = zeros(size(SNRdB_MC));

% Processing the sequence in blocks avoids allocating several vectors of
% 10 million doubles at the same time.
blockSize = 2e5;

tStart = tic;
for i = 1:numel(SNRdB_MC)
    errorCount = 0;
    processed = 0;

    while processed < N_MC
        currentBlock = min(blockSize, N_MC - processed);

        % Equiprobable binary source: false = 0, true = 1.
        data = rand(1, currentBlock) >= 0.5;

        % Bipolar NRZ mapping: 0 -> -A and 1 -> +A.
        tx = 2*A*double(data) - A;

        % Additive white Gaussian noise with standard deviation sigma.
        noise = sigma_MC(i) * randn(1, currentBlock);
        rx = tx + noise;

        % Zero-threshold detector and error counter.
        detected = rx >= 0;
        errorCount = errorCount + nnz(xor(detected, data));
        processed = processed + currentBlock;
    end

    BER_MC(i) = errorCount / N_MC;
end
elapsed_MC = toc(tStart);
fprintf('Conventional Monte Carlo time: %.3f s\n', elapsed_MC);

% Theoretical BER for antipodal signaling with a zero threshold.
BER_theory_MC = 0.5 * erfc(A ./ (sqrt(2)*sigma_MC));

figure('Color','w');
semilogy(SNRdB_MC, BER_theory_MC, '--r', 'LineWidth', 1.6); hold on;
semilogy(SNRdB_MC, BER_MC, 'o-b', 'LineWidth', 1.0, 'MarkerSize', 3);
grid on;
xlabel('SNR (dB)');
ylabel('BER');
title('Bipolar NRZ - Conventional Monte Carlo');
legend('Theoretical BER', 'Monte Carlo estimate', 'Location', 'southwest');

%% 2. Variance-inflated importance sampling
N_IS = 1e5;                      % Far fewer samples are required
SNRdB_IS = 8:18;                 % High-SNR region
sigma_IS = A .* 10.^(-SNRdB_IS/20);
B_IS = 4;                        % Proposal standard-deviation scale
BER_IS = zeros(size(SNRdB_IS));
SE_IS = zeros(size(SNRdB_IS));

tStart = tic;
for i = 1:numel(SNRdB_IS)
    data = rand(1, N_IS) >= 0.5;
    tx = 2*A*double(data) - A;

    % Samples are drawn from q(n)=N(0,(B_IS*sigma)^2), which produces
    % substantially more threshold crossings than the true distribution.
    noise = B_IS * sigma_IS(i) * randn(1, N_IS);

    % Likelihood ratio p(n)/q(n). This weight removes the bias introduced
    % by sampling from the broader proposal distribution.
    exponent = -(noise.^2 ./ (2*sigma_IS(i)^2)) * (1 - 1/B_IS^2);
    weight = B_IS * exp(exponent);

    rx = tx + noise;
    detected = rx >= 0;

    % IMPORTANT: keep one error indicator per sample. Summing the logical
    % vector before multiplying by the weights would be incorrect.
    errorIndicator = xor(detected, data);
    weightedSamples = weight .* double(errorIndicator);
    BER_IS(i) = mean(weightedSamples);
    SE_IS(i) = std(weightedSamples, 0, 2) / sqrt(N_IS);
end
elapsed_IS = toc(tStart);
fprintf('Importance-sampling time: %.3f s\n', elapsed_IS);

BER_theory_IS = 0.5 * erfc(A ./ (sqrt(2)*sigma_IS));

figure('Color','w');
semilogy(SNRdB_IS, BER_theory_IS, '--r', 'LineWidth', 1.6); hold on;
semilogy(SNRdB_IS, BER_IS, 'o-g', 'LineWidth', 1.2, 'MarkerSize', 4);
grid on;
xlabel('SNR (dB)');
ylabel('BER');
title('Bipolar NRZ - Importance Sampling');
legend('Theoretical BER', 'Importance-sampling estimate', ...
       'Location', 'southwest');

%% 3. Save numerical results
save('BER_results.mat', 'A', 'N_MC', 'SNRdB_MC', 'sigma_MC', ...
     'BER_MC', 'BER_theory_MC', 'elapsed_MC', 'N_IS', 'SNRdB_IS', ...
     'sigma_IS', 'B_IS', 'BER_IS', 'BER_theory_IS', 'SE_IS', ...
     'elapsed_IS');
