clear;
close all;
clc;

% STEP-BY-STEP OVERLAP-SAVE DEMONSTRATION
% This script shows the exact input blocks, circular-convolution outputs,
% discarded samples, and valid samples for a small numerical example.

x = (1:12)/2;
h = [3 2 1];

L = length(h);
M = 6;
overlap = L - 1;
R = M - overlap;

if M < L
    error('M must be greater than or equal to L.');
end

y_reference = conv(x, h);
output_length = length(y_reference);
number_of_blocks = ceil(output_length/R);

% Construct the zero-padded sequence used by overlap-save.
required_length = (number_of_blocks - 1)*R + M;
number_of_trailing_zeros = required_length - overlap - length(x);

x_extended = [zeros(1, overlap), ...
              x, ...
              zeros(1, number_of_trailing_zeros)];

H = fft(h, M);
assembled_output = [];

fprintf('OVERLAP-SAVE PARAMETERS\n');
fprintf('L = %d filter samples\n', L);
fprintf('M = %d samples per FFT block\n', M);
fprintf('Overlap = %d samples\n', overlap);
fprintf('R = %d valid samples per block\n\n', R);

for k = 1:number_of_blocks
    block_start = (k-1)*R + 1;
    block_end = block_start + M - 1;

    x_block = x_extended(block_start:block_end);
    y_circular = real(ifft(fft(x_block, M).*H));

    discarded = y_circular(1:overlap);
    valid = y_circular(L:M);

    assembled_output = [assembled_output valid]; %#ok<AGROW>

    fprintf('Block %d\n', k);
    fprintf('  Input block:       ');
    fprintf('%8.3f ', x_block);
    fprintf('\n');

    fprintf('  Circular output:   ');
    fprintf('%8.3f ', y_circular);
    fprintf('\n');

    fprintf('  Discarded samples: ');
    fprintf('%8.3f ', discarded);
    fprintf('\n');

    fprintf('  Valid samples:     ');
    fprintf('%8.3f ', valid);
    fprintf('\n\n');

    figure;
    subplot(3,1,1);
    stem(0:M-1, x_block, 'filled');
    grid on;
    xlabel('Position inside the block');
    ylabel('Amplitude');
    title(sprintf('Block %d input', k));

    subplot(3,1,2);
    stem(0:M-1, y_circular, 'filled');
    grid on;
    xlabel('Position inside the block');
    ylabel('Amplitude');
    title('Circular-convolution output');

    subplot(3,1,3);
    stem(0:overlap-1, discarded, 'filled');
    hold on;
    stem(overlap:M-1, valid, 'filled');
    hold off;
    grid on;
    xlabel('Position inside the block');
    ylabel('Amplitude');
    title('Discarded samples and valid samples');
    legend('Discarded', 'Valid', 'Location', 'best');
end

assembled_output = assembled_output(1:output_length);

figure;
stem(0:output_length-1, y_reference, 'filled');
hold on;
stem(0:output_length-1, assembled_output, '.');
hold off;
grid on;
xlabel('Sample index');
ylabel('Amplitude');
title('Final overlap-save reconstruction');
legend('Direct linear convolution', 'Overlap-save output', ...
       'Location', 'best');

figure;
stem(0:output_length-1, y_reference - assembled_output, 'filled');
grid on;
xlabel('Sample index');
ylabel('Error');
title('Reconstruction error');

fprintf('Maximum absolute reconstruction error: %.3e\n', ...
        max(abs(y_reference - assembled_output)));
