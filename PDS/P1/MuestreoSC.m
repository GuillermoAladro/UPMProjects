%% MuestreoSC.m
% Muestreo de una señal cosenoidal y demostración de aliasing.

clear;
close all;
clc;

w = 2000*pi;          % Frecuencia angular (rad/s), f0 = 1000 Hz
f0 = w/(2*pi);        % Frecuencia de la señal (Hz)
Tc = 1e-5;            % Paso temporal para simular señal continua
T = 1/f0;             % Periodo de la señal (1 ms)
t = 0:Tc:1;           % Representación de 0 a 1 segundo
xc = cos(w*t);

%% Secuencia discreta 1: fs1 = 10 kHz (cumple Nyquist)
fs1 = 10e3;
Ts1 = 1/fs1;
n1 = 0:fs1;
xn1 = cos(w*n1*Ts1);

t_lim = 5*T;          % Mostrar los primeros 5 periodos = 5 ms
n1_lim = floor(t_lim/Ts1);

figure;
subplot(2,1,1);
plot(t,xc,'LineWidth',1.1);
xlim([0 t_lim]);
grid on;
title('Señal x_c(t): primeros 5 ms');
xlabel('Tiempo (s)');
ylabel('Amplitud');

subplot(2,1,2);
stem(n1,xn1,'filled');
xlim([0 n1_lim]);
grid on;
title(sprintf('Señal x_1[n], f_s = %.0f Hz: primeros 5 ms',fs1));
xlabel('Índice n');
ylabel('Amplitud');

% Espectro entre -pi y pi
N = 10000;
X1 = fftshift(fft(xn1,N));
W = linspace(-pi,pi,N);

figure;
plot(W,abs(X1),'LineWidth',1.1);
xlim([-pi pi]);
grid on;
title('Espectro de X_1(e^{j\omega})');
xlabel('\omega (rad/muestra)');
ylabel('|X_1|');

%% Secuencia discreta 2: fs2 = 800 Hz (no cumple Nyquist)
fs2 = 800;
Ts2 = 1/fs2;
n2 = 0:fs2;
xn2 = cos(w*n2*Ts2);
n2_lim = floor(t_lim/Ts2);

figure;
subplot(2,1,1);
plot(t,xc,'LineWidth',1.1);
xlim([0 t_lim]);
grid on;
title('Señal x_c(t): primeros 5 ms');
xlabel('Tiempo (s)');
ylabel('Amplitud');

subplot(2,1,2);
stem(n2,xn2,'filled');
xlim([0 max(n2_lim,1)]);
grid on;
title(sprintf('Señal x_2[n], f_s = %.0f Hz (aliasing): primeros 5 ms',fs2));
xlabel('Índice n');
ylabel('Amplitud');

% Espectro entre -pi y pi
X2 = fftshift(fft(xn2,N));

figure;
plot(W,abs(X2),'LineWidth',1.1);
xlim([-pi pi]);
grid on;
title('Espectro de X_2(e^{j\omega})');
xlabel('\omega (rad/muestra)');
ylabel('|X_2|');

%% Reproducción opcional
% La primera señal se oye como un tono de 1 kHz. En la segunda aparece
% aliasing, pues fs2 < 2*f0.
% sound(xn1,fs1);
% pause(1.2);
% sound(xn2,fs2);
