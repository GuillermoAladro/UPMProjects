package ssoo.servidor;

import ssoo.telemetría.Telemetría;

// Unidad de trabajo que viaja por la cola: dato de entrada, resultado y
// referencia al hilo que debe ser notificado cuando el análisis termine.
public class Trabajo {

    // Entrada: dato crudo recibido de la estación.
    private Telemetría telemetriaOriginal;

    // Salida: dato procesado (null hasta que un analizador lo completa).
    private Telemetría telemetriaAnalizada;

    // Hilo que encargó el trabajo, para el aviso (notify) posterior.
    private HiloPeticion hiloPropietario;

    public Trabajo(Telemetría original, HiloPeticion propietario) {
        this.telemetriaOriginal = original;
        this.hiloPropietario = propietario;
        this.telemetriaAnalizada = null;
    }

    public Telemetría getTelemetriaOriginal() {
        return telemetriaOriginal;
    }

    public void setTelemetriaAnalizada(Telemetría resultado) {
        this.telemetriaAnalizada = resultado;
    }

    public Telemetría getTelemetriaAnalizada() {
        return telemetriaAnalizada;
    }

    public HiloPeticion getHiloPropietario() {
        return hiloPropietario;
    }
}
