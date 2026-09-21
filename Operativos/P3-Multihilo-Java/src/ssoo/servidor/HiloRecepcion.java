package ssoo.servidor;

import ssoo.telemetría.estación.Receptor;
import ssoo.telemetría.estación.Petición;

// Hilo receptor: escucha peticiones de red y delega cada una en un HiloPeticion.
public class HiloRecepcion extends Thread {

    private ColaTrabajos cola;

    public HiloRecepcion(ColaTrabajos cola) {
        this.cola = cola;
    }

    @Override
    public void run() {
        System.out.println("[Receptor] Esperando peticiones");

        try {
            // Abre el puerto de red para escuchar.
            Receptor receptor = new Receptor();

            // Bucle infinito: el servidor atiende peticiones indefinidamente.
            while (true) {

                // Bloqueo hasta que llega una conexión.
                Petición peticionRecibida = receptor.recibirPetición();

                // Delegación: un hilo específico por petición, de modo que el
                // receptor vuelve a escuchar de inmediato (alta disponibilidad).
                HiloPeticion trabajador = new HiloPeticion(peticionRecibida, cola);
                trabajador.start();

                System.out.println("[Receptor] Nueva petición recibida y encolada.");
            }
        } catch (Exception e) {
            System.err.println("[Receptor] Error crítico: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
