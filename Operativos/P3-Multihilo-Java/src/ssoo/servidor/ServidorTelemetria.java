package ssoo.servidor;

import ssoo.telemetría.panel.PanelVisualizador;

// Punto de entrada: crea los recursos compartidos, el pool de analizadores
// y el hilo receptor que atiende las peticiones de las estaciones.
public class ServidorTelemetria {

    public static void main(String[] args) {
        System.out.println("--- Inicio del Servidor de Telemetría (Fase 2) ---");

        // 1. RECURSOS COMPARTIDOS.
        // Cola que actúa de puente entre productores y consumidores.
        ColaTrabajos cola = new ColaTrabajos();

        // 2. MONITORIZACIÓN.
        // Se registra la cola en el panel para ver su ocupación gráficamente.
        PanelVisualizador.getPanel().registrarColaTrabajos(cola);

        // 3. POOL DE HILOS ANALIZADORES.
        // Se dimensiona según los núcleos disponibles, para no crear más hilos
        // de los que la máquina puede ejecutar en paralelo.
        int numAnalizadores = Runtime.getRuntime().availableProcessors();

        // El panel visualizador no dibuja más de 8 analizadores.
        if (numAnalizadores > 8) numAnalizadores = 8;

        System.out.println("Creando " + numAnalizadores + " hilos analizadores...");

        for (int i = 0; i < numAnalizadores; i++) {
            HiloAnalizador analizador = new HiloAnalizador(i, cola);
            analizador.start();
        }

        // 4. ARRANQUE DEL SERVIDOR.
        HiloRecepcion hiloPrincipal = new HiloRecepcion(cola);
        hiloPrincipal.start();

        // main termina aquí, pero la JVM sigue viva mientras haya hilos activos.
        System.out.println("Servidor Fase 2 operativo. Cola y Analizadores listos.");
    }
}
