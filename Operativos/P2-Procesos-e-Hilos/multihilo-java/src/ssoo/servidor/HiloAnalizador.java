package ssoo.servidor;

import ssoo.telemetría.Analizador;
import ssoo.telemetría.Telemetría;

// Consumidor: extrae trabajos de la cola común, los procesa y avisa al hilo propietario.
public class HiloAnalizador extends Thread {

    private int id;
    private ColaTrabajos cola;

    public HiloAnalizador(int id, ColaTrabajos cola) {
        this.id = id;
        this.cola = cola;
    }

    @Override
    public void run() {
        System.out.println("[Analizador " + id + "] Listo para trabajar");

        // Bucle infinito: el analizador siempre busca trabajo.
        while (true) {
            // 1. EXTRAER. Se bloquea si la cola está vacía.
            Trabajo trabajo = cola.cogerTrabajo();

            if (trabajo != null) {

                // 2. PROCESAR. El analizador del JAR simula la carga de CPU.
                Analizador herramienta = new Analizador();
                Telemetría datoOriginal = trabajo.getTelemetriaOriginal();
                Telemetría resultado = herramienta.analizar(datoOriginal);

                // 3. GUARDAR RESULTADO en el propio objeto Trabajo.
                trabajo.setTelemetriaAnalizada(resultado);

                // 4. NOTIFICAR al hilo que encargó el trabajo.
                HiloPeticion jefe = trabajo.getHiloPropietario();

                // Sección crítica sobre el objeto jefe para poder despertarlo.
                synchronized (jefe) {
                    jefe.notify(); // Despierta al HiloPeticion que espera en wait().
                }
            }
        }
    }
}
