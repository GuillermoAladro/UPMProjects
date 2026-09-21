# P3 — Multithreaded telemetry server (Java)

Concurrent server that receives telemetry requests from ground stations, decomposes each request into independent analysis jobs, processes them in parallel and returns a single consolidated report to the station that asked for it.

## Architecture

| Class | Role |
|---|---|
| `ServidorTelemetria` | Entry point: creates the shared queue, starts the analyser pool and the receiver thread. |
| `HiloRecepcion` | Receiver. Blocks on `recibirPetición()` and spawns one `HiloPeticion` per incoming request, so the listening loop is never held up. |
| `HiloPeticion` | Producer. Splits an `Encargo` into `Trabajo` units, pushes them onto the shared queue, waits passively for all of them, then builds and sends the `Informe`. |
| `ColaTrabajos` | Shared queue. Wraps a `LinkedBlockingQueue<Trabajo>`; implements `Numerable` so the visual panel can read its depth. |
| `HiloAnalizador` | Consumer. Takes jobs from the queue, runs the CPU-bound `Analizador`, stores the result and notifies the owning thread. |
| `Trabajo` | Job record: input telemetry, analysed result and a reference to the owning `HiloPeticion`. |

```
Estación ──▶ HiloRecepcion ──▶ HiloPeticion ──┐
                                              │  ponerTrabajo()
                                        ColaTrabajos  (LinkedBlockingQueue)
                                              │  cogerTrabajo()
                          HiloAnalizador × N ─┘ ──notify()──▶ HiloPeticion ──▶ Informe
```

## Concurrency design

- **Thread pool sizing** — the number of analyser threads comes from `Runtime.getRuntime().availableProcessors()`, capped at 8 (the visual panel does not render more).
- **No busy waiting** — `LinkedBlockingQueue.take()` parks an idle analyser until a job arrives; `put()` blocks if the queue is bounded and full.
- **Passive request-level waiting** — `HiloPeticion` blocks in `wait()` inside a `while (!estanTodosCompletos())` loop, releasing its monitor; each analyser wakes it with `notify()` after storing a result. The `while` guard protects against spurious wake-ups and partial completion.
- **Shared state** — job lists are held in a synchronised `Vector`; the request-ID counter is incremented inside a `synchronized` block on the class object.

## Build and run

The `ssoo.telemetría` package (stations, `Analizador`, `Informe`, visual panel) is the JAR supplied with the practice; it is not redistributed here.

```bash
javac -encoding UTF-8 -cp telemetria.jar -d out src/ssoo/servidor/*.java
java  -cp telemetria.jar:out ssoo.servidor.ServidorTelemetria
```

Then launch a station simulator against the running server:

```bash
java -cp telemetria.jar ssoo.telemetría.estación.simulador.SimuladorEstación
```

Source comments are in Spanish, as submitted for the course.
