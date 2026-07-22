%% interpYdiez.m
% Interpolación, diezmado y comparación con interp/decimate.
% Requiere Signal Processing Toolbox.

clear;
close all;
clc;

w = 2000*pi;          % f0 = 1000 Hz
f0 = w/(2*pi);
T = 1/f0;

%% Señal original muestreada a 12 kHz
fs = 12e3;
Ts = 1/fs;
duracion = 1;         % segundos
n = 0:round(fs*duracion);
xn = cos(w*n*Ts);

muestras_10ms = floor(10e-3*fs);

figure;
stem(n(1:muestras_10ms+1),xn(1:muestras_10ms+1),'filled');
grid on;
title('Señal x_0[n]: primeros 10 ms');
xlabel('Índice n');
ylabel('Amplitud');

N = 10000;
W = linspace(-pi,pi,N);
X0 = fftshift(fft(xn,N));
f0_axis = linspace(-fs/2,fs/2,N);

figure;
plot(W,abs(X0),'LineWidth',1.1);
xlim([-pi pi]);
grid on;
title('Espectro X_0 entre -\pi y \pi');
xlabel('\omega (rad/muestra)');
ylabel('|X_0|');

figure;
plot(f0_axis,abs(X0),'LineWidth',1.1);
xlim([-fs/2 fs/2]);
grid on;
title('Espectro X_0 en Hz');
xlabel('Frecuencia (Hz)');
ylabel('|X_0|');

%% Interpolación por 2: 12 kHz -> 24 kHz
fs2 = 24e3;
[p,q] = rat(fs2/fs);   % p = 2, q = 1

% upsample inserta p-1 ceros entre muestras
x1p = upsample(xn,p);
n1 = 0:length(x1p)-1;
lim1 = min(floor(10e-3*fs2),length(x1p)-1);

figure;
stem(n1(1:lim1+1),x1p(1:lim1+1),'filled');
grid on;
title('Señal x_{1p}[n] obtenida con upsample: primeros 10 ms');
xlabel('Índice n');
ylabel('Amplitud');

X1P = fftshift(fft(x1p,N));
f2_axis = linspace(-fs2/2,fs2/2,N);

figure;
plot(W,abs(X1P),'LineWidth',1.1);
xlim([-pi pi]);
grid on;
title('Espectro X_{1P} entre -\pi y \pi');
xlabel('\omega (rad/muestra)');
ylabel('|X_{1P}|');

figure;
plot(f2_axis,abs(X1P),'LineWidth',1.1);
xlim([-fs2/2 fs2/2]);
grid on;
title('Espectro X_{1P} en Hz');
xlabel('Frecuencia (Hz)');
ylabel('|X_{1P}|');

% interp inserta ceros y aplica un filtro paso bajo
x1n = interp(xn,p);
n1f = 0:length(x1n)-1;
lim1f = min(floor(10e-3*fs2),length(x1n)-1);

figure;
stem(n1f(1:lim1f+1),x1n(1:lim1f+1),'filled');
grid on;
title('Señal x_{1n}[n] obtenida mediante interp');
xlabel('Índice n');
ylabel('Amplitud');

X1N = fftshift(fft(x1n,N));

figure;
plot(W,abs(X1N),'LineWidth',1.1);
xlim([-pi pi]);
grid on;
title('Espectro X_{1N} entre -\pi y \pi');
xlabel('\omega (rad/muestra)');
ylabel('|X_{1N}|');

figure;
plot(f2_axis,abs(X1N),'LineWidth',1.1);
xlim([-fs2/2 fs2/2]);
grid on;
title('Espectro X_{1N} en Hz');
xlabel('Frecuencia (Hz)');
ylabel('|X_{1N}|');

%% Diezmado por 2: 12 kHz -> 6 kHz
fs3 = 6e3;
[p2,q2] = rat(fs3/fs); % p2 = 1, q2 = 2

% downsample elimina q2-1 muestras de cada q2
x2p = downsample(xn,q2);
n2 = 0:length(x2p)-1;
lim2 = min(floor(10e-3*fs3),length(x2p)-1);

figure;
stem(n2(1:lim2+1),x2p(1:lim2+1),'filled');
grid on;
title('Señal x_{2q}[n] obtenida con downsample: primeros 10 ms');
xlabel('Índice n');
ylabel('Amplitud');

X2P = fftshift(fft(x2p,N));
f3_axis = linspace(-fs3/2,fs3/2,N);

figure;
plot(W,abs(X2P),'LineWidth',1.1);
xlim([-pi pi]);
grid on;
title('Espectro X_{2Q} entre -\pi y \pi');
xlabel('\omega (rad/muestra)');
ylabel('|X_{2Q}|');

figure;
plot(f3_axis,abs(X2P),'LineWidth',1.1);
xlim([-fs3/2 fs3/2]);
grid on;
title('Espectro X_{2Q} en Hz');
xlabel('Frecuencia (Hz)');
ylabel('|X_{2Q}|');

% decimate filtra antes de eliminar muestras
x2n = decimate(xn,q2);
n2f = 0:length(x2n)-1;
lim2f = min(floor(10e-3*fs3),length(x2n)-1);

figure;
stem(n2f(1:lim2f+1),x2n(1:lim2f+1),'filled');
grid on;
title('Señal x_{2n}[n] obtenida mediante decimate');
xlabel('Índice n');
ylabel('Amplitud');

X2N = fftshift(fft(x2n,N));

figure;
plot(W,abs(X2N),'LineWidth',1.1);
xlim([-pi pi]);
grid on;
title('Espectro X_{2N} entre -\pi y \pi');
xlabel('\omega (rad/muestra)');
ylabel('|X_{2N}|');

figure;
plot(f3_axis,abs(X2N),'LineWidth',1.1);
xlim([-fs3/2 fs3/2]);
grid on;
title('Espectro X_{2N} en Hz');
xlabel('Frecuencia (Hz)');
ylabel('|X_{2N}|');

%% Diezmado por 8: 12 kHz -> 1.5 kHz
% Esta frecuencia final no cumple Nyquist para una señal de 1 kHz.
fs4 = 1.5e3;
[p3,q3] = rat(fs4/fs); % p3 = 1, q3 = 8

x3q = downsample(xn,q3);
n3 = 0:length(x3q)-1;
lim3 = min(floor(10e-3*fs4),length(x3q)-1);

figure;
stem(n3(1:lim3+1),x3q(1:lim3+1),'filled');
grid on;
title('Señal x_{3q}[n] obtenida con downsample: primeros 10 ms');
xlabel('Índice n');
ylabel('Amplitud');

% Corrección respecto al código original: aquí se calcula la FFT de x3q.
X3Q = fftshift(fft(x3q,N));
f4_axis = linspace(-fs4/2,fs4/2,N);

figure;
plot(W,abs(X3Q),'LineWidth',1.1);
xlim([-pi pi]);
grid on;
title('Espectro X_{3Q} entre -\pi y \pi');
xlabel('\omega (rad/muestra)');
ylabel('|X_{3Q}|');

figure;
plot(f4_axis,abs(X3Q),'LineWidth',1.1);
xlim([-fs4/2 fs4/2]);
grid on;
title('Espectro X_{3Q} en Hz');
xlabel('Frecuencia (Hz)');
ylabel('|X_{3Q}|');

x3n = decimate(xn,q3);
n3f = 0:length(x3n)-1;
lim3f = min(floor(10e-3*fs4),length(x3n)-1);

figure;
stem(n3f(1:lim3f+1),x3n(1:lim3f+1),'filled');
grid on;
title('Señal x_{3n}[n] obtenida mediante decimate');
xlabel('Índice n');
ylabel('Amplitud');

X3N = fftshift(fft(x3n,N));

figure;
plot(W,abs(X3N),'LineWidth',1.1);
xlim([-pi pi]);
grid on;
title('Espectro X_{3N} entre -\pi y \pi');
xlabel('\omega (rad/muestra)');
ylabel('|X_{3N}|');

figure;
plot(f4_axis,abs(X3N),'LineWidth',1.1);
xlim([-fs4/2 fs4/2]);
grid on;
title('Espectro X_{3N} en Hz');
xlabel('Frecuencia (Hz)');
ylabel('|X_{3N}|');
