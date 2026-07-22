%% CambioTasaMuestreo.m
% Conversión de una señal de voz de 8 kHz a 44.1 kHz.
% Coloque voz1_8khz.mat en la misma carpeta que este script.
% Requiere Signal Processing Toolbox.

clear;
close all;
clc;

S = load('voz1_8khz.mat');
x = S.x(:);                 % Trabajar como vector columna

if isfield(S,'fs_x')
    fs1 = double(S.fs_x);
else
    fs1 = 8e3;
end

fs2 = 44.1e3;
[P,Q] = rat(fs2/fs1);       % 44.1/8 = 441/80

%% Señal original
nv = 0:length(x)-1;
tv = nv/fs1;

figure;
plot(tv,x,'LineWidth',1.0);
grid on;
title('Señal de voz original');
xlabel('Tiempo (s)');
ylabel('Amplitud');

%% Cambio de tasa en una etapa
% resample realiza interpolación, filtrado antialias y diezmado de manera
% más eficiente que crear explícitamente una señal interpolada por 441.
xc2 = resample(x,P,Q);

%% Cambio de tasa en tres etapas
% 441/80 = (9/4)*(7/4)*(7/5)
xcb1 = resample(x,9,4);
xcb3 = resample(xcb1,7,4);
xcb5 = resample(xcb3,7,5);

%% Comparación temporal
n_mostrar = min(round(0.03*fs2),min(length(xc2),length(xcb5)));
t_out = (0:n_mostrar-1)/fs2;

figure;
plot(t_out,xc2(1:n_mostrar),'LineWidth',1.0);
hold on;
plot(t_out,xcb5(1:n_mostrar),'--','LineWidth',1.0);
grid on;
title('Conversión a 44.1 kHz: comparación de los primeros 30 ms');
xlabel('Tiempo (s)');
ylabel('Amplitud');
legend('Una etapa','Tres etapas');

%% Espectros
N = 5000;

TF_x = fftshift(fft(x,N));
f_in = linspace(-fs1/2,fs1/2,N);

XC = fftshift(fft(xc2,N));
XCb = fftshift(fft(xcb5,N));
f_out = linspace(-fs2/2,fs2/2,N);

mag_x_db = 20*log10(abs(TF_x)+eps);
mag_xc_db = 20*log10(abs(XC)+eps);
mag_xcb_db = 20*log10(abs(XCb)+eps);

figure;
plot(f_in,mag_x_db,'LineWidth',1.0);
grid on;
title('Espectro de la señal original (8 kHz)');
xlabel('Frecuencia (Hz)');
ylabel('Magnitud (dB)');
xlim([-fs1/2 fs1/2]);

figure;
plot(f_out,mag_xc_db,'LineWidth',1.0);
grid on;
title('Espectro tras cambio de tasa en una etapa');
xlabel('Frecuencia (Hz)');
ylabel('Magnitud (dB)');
xlim([-fs2/2 fs2/2]);

figure;
plot(f_out,mag_xcb_db,'LineWidth',1.0);
grid on;
title('Espectro tras cambio de tasa en tres etapas');
xlabel('Frecuencia (Hz)');
ylabel('Magnitud (dB)');
xlim([-fs2/2 fs2/2]);

%% Diferencia entre los dos métodos
L = min(length(xc2),length(xcb5));
error_rms = sqrt(mean((xc2(1:L)-xcb5(1:L)).^2));
fprintf('Error RMS entre una etapa y tres etapas: %.6g\n',error_rms);

%% Reproducción opcional
% soundsc(x,fs1);
% pause(length(x)/fs1 + 0.5);
% soundsc(xc2,fs2);
