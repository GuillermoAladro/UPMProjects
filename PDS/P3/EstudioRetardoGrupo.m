clear;
close all;
clc;

% FIR AND IIR PHASE / GROUP-DELAY STUDY
% This script loads x_fase from caso_fase.mat, applies FIR and Butterworth
% IIR low-pass filters, and compares magnitude response, time-domain
% behavior, and group delay.

data = load('caso_fase.mat');

if ~isfield(data, 'x_fase')
    error('caso_fase.mat must contain a variable named x_fase.');
end

x_fase = data.x_fase(:).';

fs = 20000;
fp = 750;
fa = 1500;

omega_p = 2*pi*fp/fs;
omega_a = 2*pi*fa/fs;

delta_p = 1 - 10^(-0.9151/20);
delta_a = 10^(-60/20);

%% FIR filter designed with a Kaiser window
[order_fir, Wn_fir, beta, filter_type] = ...
    kaiserord([omega_p omega_a], [1 0], [delta_p delta_a], 2*pi);

order_fir = order_fir + rem(order_fir, 2);

window_fir = kaiser(order_fir + 1, beta).';
omega_c = (omega_p + omega_a)/2;
n_fir = -order_fir/2:order_fir/2;

h_ideal = (omega_c/pi)*sinc((omega_c/pi).*n_fir);
h_fir = h_ideal .* window_fir;

%% Butterworth IIR filter through the bilinear transform
Td = 1;
Omega_p = (2/Td)*tan(omega_p/2);
Omega_a = (2/Td)*tan(omega_a/2);

Rp = -20*log10(1 - delta_p);
Rs = -20*log10(delta_a);

[order_iir, Omega_c_iir] = ...
    buttord(Omega_p, Omega_a, Rp, Rs, 's');

[b_iir_analog, a_iir_analog] = ...
    butter(order_iir, Omega_c_iir, 'low', 's');

[b_iir, a_iir] = ...
    bilinear(b_iir_analog, a_iir_analog, 1/Td);

%% Magnitude responses and input spectrum
N = 2000;

[H_fir, omega] = freqz(h_fir, 1, N, 2*pi);
[H_iir, ~] = freqz(b_iir, a_iir, N, 2*pi);

H_fir_dB = 20*log10(abs(H_fir) + eps);
H_iir_dB = 20*log10(abs(H_iir) + eps);

% Use a 2N-point FFT so that the first N bins cover approximately 0 to pi.
X = fft(x_fase, 2*N);
X_positive = X(1:N);
X_dB = 20*log10(abs(X_positive)/max(abs(X_positive)) + eps);

figure;
plot(omega, H_fir_dB, 'LineWidth', 1.2);
hold on;
plot(omega, H_iir_dB, 'LineWidth', 1.2);
plot(omega, X_dB, 'LineWidth', 1.0);
hold off;
xlim([0 pi]);
ylim([-100 5]);
grid on;
xlabel('\omega (rad/sample)');
ylabel('Normalized magnitude (dB)');
title('Filter responses and normalized input spectrum');
legend('FIR filter', 'Butterworth IIR filter', 'Input signal', ...
       'Location', 'best');

%% Filter the signal
y_fir = filter(h_fir, 1, x_fase);
y_iir = filter(b_iir, a_iir, x_fase);

sample_index = 0:length(x_fase)-1;

figure;
plot(sample_index, x_fase, 'LineWidth', 1.0);
hold on;
plot(sample_index, y_fir, 'LineWidth', 1.0);
hold off;
grid on;
xlabel('Sample index');
ylabel('Amplitude');
title('Input signal and FIR-filtered signal');
legend('Input', 'FIR output', 'Location', 'best');

figure;
plot(sample_index, x_fase, 'LineWidth', 1.0);
hold on;
plot(sample_index, y_iir, 'LineWidth', 1.0);
hold off;
grid on;
xlabel('Sample index');
ylabel('Amplitude');
title('Input signal and IIR-filtered signal');
legend('Input', 'IIR output', 'Location', 'best');

%% Group-delay comparison
[group_delay_fir, omega_gd] = grpdelay(h_fir, 1, N, 2*pi);
[group_delay_iir, ~] = grpdelay(b_iir, a_iir, N, 2*pi);

figure;
plot(omega_gd, group_delay_fir, 'LineWidth', 1.2);
hold on;
plot(omega_gd, group_delay_iir, 'LineWidth', 1.2);
hold off;
xlim([0 pi]);
grid on;
xlabel('\omega (rad/sample)');
ylabel('Group delay (samples)');
title('FIR and IIR group-delay comparison');
legend('Linear-phase FIR', 'Butterworth IIR', 'Location', 'best');

fprintf('FIR order: %d\n', order_fir);
fprintf('Expected FIR group delay: %.1f samples\n', order_fir/2);
fprintf('Butterworth IIR order: %d\n', order_iir);
