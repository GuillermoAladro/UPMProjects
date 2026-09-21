# Operating Systems — Concurrent Programming (POSIX & Java)

<p align="center"><img src="../assets/covers/os.svg" width="830" alt="Operating Systems"/></p>

Systems-programming work on concurrency: first with heavyweight processes on POSIX/Linux, then with threads and shared-memory synchronisation in Java.

## P2 — Multiprocess applications on POSIX (C)

- **`controlador.c`** — concurrent image-processing controller: one child process per image (`fork` + `execlp` → ImageMagick blur), a maximum of 4 simultaneous workers managed with `waitpid`, and clean group shutdown on `SIGTERM`.
- **`servidor.c`** — concurrent TCP server (POSIX sockets): one child per client, "next prime number" service, zombie reaping with `SIGCHLD` + `WNOHANG`, configurable port (`-p`, default 1234).

Usage examples and design notes in [`P2-Multiproceso-POSIX/document_explanations_en.txt`](P2-Multiproceso-POSIX/document_explanations_en.txt).

## P3 — Multithreaded telemetry server (Java)

A producer–consumer server that receives telemetry requests from ground stations, splits each one into independent analysis jobs and returns a consolidated report.

- Fixed pool of analyser threads, sized from `Runtime.availableProcessors()`.
- Shared `LinkedBlockingQueue` decoupling producers from consumers, with blocking `put`/`take` instead of busy waiting.
- Per-request synchronisation with `wait()` / `notify()` over the requesting thread.

Architecture and build instructions in [`P3-Multihilo-Java/README.md`](P3-Multihilo-Java/README.md).
