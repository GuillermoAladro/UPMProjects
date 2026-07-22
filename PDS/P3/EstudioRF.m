clear;
close all;
clc;

% FILTERING OF A NOISY SIGNAL WITH FIR AND IIR LOW-PASS FILTERS
% The script loads x_frec_noise from caso_ruido.mat, designs two filters
% with the same specifications, and compares their filtered outputs.

data = load('caso_ruido.mat');

if ~isfield(data, 'x_frec_noise')
    error('caso_ruido.mat must contain a variable named x_frec_noise.');
end

x_frec_noise = data.x_frec_noise(:).';

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

y_fir = filter(h_fir, 1, x_frec_noise);

%% Butterworth IIR filter designed through the bilinear transform
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

% Apply the actual IIR numerator and denominator coefficients.
y_iir = filter(b_iir, a_iir, x_frec_noise);

%% Frequency-response comparison
N_response = 2000;
[H_fir, omega] = freqz(h_fir, 1, N_response, 2*pi);
[H_iir, ~] = freqz(b_iir, a_iir, N_response, 2*pi);

figure;
dibuja_plantilla(omega_p, omega_a, delta_p, delta_p, delta_a, 'log');
hold on;
plot(omega, 20*log10(abs(H_fir) + eps), 'LineWidth', 1.2);
plot(omega, 20*log10(abs(H_iir) + eps), 'LineWidth', 1.2);
hold off;
ylim([-90 5]);
grid on;
xlabel('\omega (rad/sample)');
ylabel('Magnitude (dB)');
title('FIR and IIR filter magnitude responses');
legend('Specification mask', 'FIR', 'Butterworth IIR', ...
       'Location', 'best');

%% Time-domain comparison
sample_index = 0:length(x_frec_noise)-1;

figure;
subplot(2,1,1);
plot(sample_index, x_frec_noise);
grid on;
xlabel('Sample index');
ylabel('Amplitude');
title('Noisy input signal');

subplot(2,1,2);
plot(sample_index, y_fir);
grid on;
xlabel('Sample index');
ylabel('Amplitude');
title('Signal filtered with the FIR filter');

figure;
subplot(2,1,1);
plot(sample_index, x_frec_noise);
grid on;
xlabel('Sample index');
ylabel('Amplitude');
title('Noisy input signal');

subplot(2,1,2);
plot(sample_index, y_iir);
grid on;
xlabel('Sample index');
ylabel('Amplitude');
title('Signal filtered with the Butterworth IIR filter');

fprintf('FIR order: %d\n', order_fir);
fprintf('Butterworth IIR order: %d\n', order_iir);
