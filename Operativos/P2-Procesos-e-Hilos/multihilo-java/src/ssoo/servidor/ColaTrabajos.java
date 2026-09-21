package ssoo.servidor;

import java.util.concurrent.LinkedBlockingQueue;
import ssoo.telemetría.Numerable;

// Cola compartida entre productores (HiloPeticion) y consumidores (HiloAnalizador).
// Implementa 'Numerable' para que el panel gráfico pueda consultar su tamaño.
public class ColaTrabajos implements Numerable {

    // LinkedBlockingQueue es thread-safe: gestiona internamente los cerrojos
    // para que dos hilos no manipulen el mismo dato a la vez.
    private LinkedBlockingQueue<Trabajo> colaInterna;

    public ColaTrabajos() {
        this.colaInterna = new LinkedBlockingQueue<>();
    }

    // Método productor: HiloPeticion deposita trabajos.
    public void ponerTrabajo(Trabajo trabajo) {
        try {
            // put() espera si la cola tuviera capacidad limitada y estuviera llena.
            colaInterna.put(trabajo);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    // Método consumidor: HiloAnalizador extrae trabajos.
    public Trabajo cogerTrabajo() {
        try {
            // take() es bloqueante: si la cola está vacía el hilo se duerme aquí
            // hasta que alguien inserte un trabajo. Evita la espera activa (busy waiting).
            return colaInterna.take();
        } catch (InterruptedException e) {
            return null;
        }
    }

    @Override
    public int numTrabajos() {
        return colaInterna.size();
    }
}
