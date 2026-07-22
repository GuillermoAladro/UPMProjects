clear;
close all;
clc;

% SMALL OVERLAP-SAVE BLOCK-FILTERING EXAMPLE
% A short sequence is filtered manually in blocks so that the valid and
% discarded samples can be identified clearly.

x = (1:12)/2;
h = [3 2 1];

L = length(h);             % Filter length
M = 6;                     % FFT and block length
R = M - L + 1;             % New samples per block
overlap = L - 1;

if M < L
    error('The FFT length M must be at least the filter length L.');
end

% Reference linear-convolution result.
y_reference = conv(x, h);
output_length = length(y_reference);

% Number of blocks needed to generate the complete output.
number_of_blocks = ceil(output_length/R);

% The sequence begins with L-1 zeros. Additional trailing zeros guarantee
% that the final block has exactly M samples.
required_padded_length = (number_of_blocks - 1)*R + M;
trailing_zeros = required_padded_length - overlap - length(x);
x_padded = [zeros(1, overlap) x zeros(1, trailing_zeros)];

% Filter spectrum reused by every block.
H = fft(h, M);

% Storage for complete circular-convolution blocks and valid samples.
block_outputs = zeros(number_of_blocks, M);
valid_outputs = zeros(number_of_blocks, R);

for block_index = 1:number_of_blocks
    first_sample = (block_index - 1)*R + 1;
    last_sample = first_sample + M - 1;

    current_block = x_padded(first_sample:last_sample);

    % M-point circular convolution performed with the FFT.
    current_output = real(ifft(fft(current_block, M).*H));

    block_outputs(block_index, :) = current_output;
    valid_outputs(block_index, :) = current_output(L:M);
end

% Concatenate the valid samples and remove extra zero-padding results.
y_overlap_save = reshape(valid_outputs.', 1, []);
y_overlap_save = y_overlap_save(1:output_length);

%% Display the complete reference output
figure;
stem(0:output_length-1, y_reference, 'filled');
grid on;
xlabel('Sample index');
ylabel('Amplitude');
title('Reference linear convolution');

%% Display every circular-convolution block
for block_index = 1:number_of_blocks
    figure;
    stem(0:M-1, block_outputs(block_index, :), 'filled');
    hold on;
    stem(L-1:M-1, block_outputs(block_index, L:M), ...
         'LineWidth', 1.5);
    hold off;
    grid on;
    xlabel('Position inside the block');
    ylabel('Amplitude');
    title(sprintf('Block %d: discarded and valid output samples', ...
                  block_index));
    legend('Complete circular-convolution block', ...
           'Valid overlap-save samples', 'Location', 'best');
end

%% Compare the assembled result with linear convolution
figure;
stem(0:output_length-1, y_reference, 'filled');
hold on;
stem(0:output_length-1, y_overlap_save, '.');
hold off;
grid on;
xlabel('Sample index');
ylabel('Amplitude');
title('Direct convolution and assembled overlap-save output');
legend('Direct convolution', 'Overlap-save', 'Location', 'best');

fprintf('Filter length L: %d\n', L);
fprintf('FFT length M: %d\n', M);
fprintf('Overlap: %d samples\n', overlap);
fprintf('New samples per block R: %d\n', R);
fprintf('Number of blocks: %d\n', number_of_blocks);
fprintf('Maximum absolute error: %.3e\n', ...
        max(abs(y_reference - y_overlap_save)));
