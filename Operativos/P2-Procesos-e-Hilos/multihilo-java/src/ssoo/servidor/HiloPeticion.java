package ssoo.servidor;

import java.util.List;
import java.util.Vector;
import java.util.ArrayList;
import ssoo.telemetría.estación.Petición;
import ssoo.telemetría.estación.Estación;
import ssoo.telemetría.Encargo;
import ssoo.telemetría.Telemetría;
import ssoo.telemetría.Informe;
import ssoo.telemetría.Índice;

// Productor: descompone un encargo en trabajos, espera a que los analizadores
// los completen y devuelve un informe consolidado a la estación.
public class HiloPeticion extends Thread {

    private static int contadorGlobal = 0;
    private int id;
    private Petición peticion;
    private ColaTrabajos cola;

    // Vector es una colección sincronizada; guarda los trabajos de esta petición.
    private Vector<Trabajo> misTrabajos;

    public HiloPeticion(Petición peticion, ColaTrabajos cola) {
        this.peticion = peticion;
        this.cola = cola;
        this.misTrabajos = new Vector<>();
        synchronized (HiloPeticion.class) {
            this.id = contadorGlobal++;
        }
    }

    @Override
    public void run() {

        Estación estacion = peticion.getEstación();
        Encargo encargo = peticion.getEncargo();

        System.out.println("[HiloPeticion " + id + "] Procesando encargo: " + encargo);

        try {
            // PASO 1: DESCOMPOSICIÓN DEL ENCARGO.
            List<Telemetría> listaDatos = encargo.getTelemetrías();

            // PASO 2: GENERACIÓN DE TRABAJOS (producción).
            for (Telemetría dato : listaDatos) {
                // Se pasa 'this' para que el analizador sepa a quién notificar.
                Trabajo nuevoTrabajo = new Trabajo(dato, this);

                // Control local del trabajo y envío a la cola común.
                misTrabajos.add(nuevoTrabajo);
                cola.ponerTrabajo(nuevoTrabajo);
            }

            // PASO 3: SINCRONIZACIÓN. Espera pasiva, sin consumir CPU.
            esperarResultados();

            // PASO 4: CONSOLIDACIÓN DE RESULTADOS.
            Informe informe = generarInforme(encargo);

            // PASO 5: RESPUESTA AL CLIENTE.
            estacion.enviar(informe);

            System.out.println("[HiloPeticion " + id + "] Informe enviado. Termino.");

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // Método crítico de sincronización.
    private synchronized void esperarResultados() {
        try {
            // El bucle while es obligatorio con wait(): protege frente a
            // despertares espurios y comprueba de nuevo la condición al despertar.
            while (!estanTodosCompletos()) {
                wait(); // Libera el cerrojo y duerme hasta recibir notify().
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    private boolean estanTodosCompletos() {
        for (Trabajo t : misTrabajos) {
            // Si algún trabajo aún no tiene resultado, la petición no ha terminado.
            if (t.getTelemetriaAnalizada() == null) {
                return false;
            }
        }
        return true;
    }

    private Informe generarInforme(Encargo encargo) {
        String tituloInforme = "informe-" + encargo.getTítulo();

        // Lista únicamente con los resultados ya procesados.
        List<Telemetría> listaFinal = new ArrayList<>();
        for (Trabajo t : misTrabajos) {
            listaFinal.add(t.getTelemetriaAnalizada());
        }

        // Índice e Informe se construyen según la interfaz del JAR de la práctica.
        Índice indice = new Índice(listaFinal);
        Informe informe = new Informe(tituloInforme, indice, listaFinal);

        return informe;
    }
}
