# Quantum Computing — Qiskit Practices (Python)

Three self-contained Qiskit practices. Each folder includes runnable Python scripts and notebooks, generated figures, JSON results and an English report (PDF).

- **IQC1 — Quantum Fundamentals**: single-qubit rotations, controlled gates, Bell state Φ⁺ and a no-cloning demonstration.
- **IQC2 — Entanglement & Teleportation**: Bell measurements, quantum teleportation with dynamic circuits, and superdense coding.
- **IQC7 — QFT Addition**: quantum adder based on the Quantum Fourier Transform, plus ideal-vs-noisy teleportation verification.

## Setup & run

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate   |   Linux/macOS: source .venv/bin/activate
pip install -r requirements.txt
python run_all.py
```

Each practice can also be run from its own folder; the scripts regenerate the JSON results and the figures used in the reports. The noise comparison uses a local Qiskit Aer noise model (results are not presented as real IBM hardware runs).
