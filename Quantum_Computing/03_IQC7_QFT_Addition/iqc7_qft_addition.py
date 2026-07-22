#!/usr/bin/env python3
"""IQC-7: teleportation comparison and 4-qubit QFT addition.

The ideal and noisy results are generated locally with Qiskit Aer. The noisy
backend is a reproducible pedagogical model and is not claimed to be an IBM
Quantum hardware execution. A real IBM run requires the student's account.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from qiskit import ClassicalRegister, QuantumCircuit, QuantumRegister, transpile
from qiskit.circuit.library import DraperQFTAdder
from qiskit.quantum_info import Statevector, state_fidelity
from qiskit_aer import AerSimulator
from qiskit_aer.noise import NoiseModel, ReadoutError, depolarizing_error

SHOTS = 2000
SEED = 2026
ROOT = Path(__file__).resolve().parent
FIG_DIR = ROOT / "figures"
FIG_DIR.mkdir(exist_ok=True)


def build_noise_model() -> NoiseModel:
    noise = NoiseModel()
    one_qubit = depolarizing_error(0.004, 1)
    two_qubit = depolarizing_error(0.025, 2)
    for gate in ("x", "sx", "h"):
        noise.add_all_qubit_quantum_error(one_qubit, gate)
    noise.add_all_qubit_quantum_error(two_qubit, "cx")
    readout = ReadoutError([[0.975, 0.025], [0.035, 0.965]])
    noise.add_all_qubit_readout_error(readout)
    return noise


IDEAL_BACKEND = AerSimulator()
NOISE_MODEL = build_noise_model()
NOISY_BACKEND = AerSimulator(noise_model=NOISE_MODEL)


def save_circuit(circuit: QuantumCircuit, filename: str) -> None:
    fig = circuit.draw(output="mpl", fold=-1)
    fig.savefig(FIG_DIR / filename, dpi=180, bbox_inches="tight")
    plt.close(fig)


def run_counts(circuit: QuantumCircuit, noisy: bool, shots: int = SHOTS, seed: int = SEED) -> dict[str, int]:
    backend = NOISY_BACKEND if noisy else IDEAL_BACKEND
    compiled = transpile(
        circuit,
        backend,
        optimization_level=1,
        seed_transpiler=seed,
    )
    result = backend.run(compiled, shots=shots, seed_simulator=seed).result()
    return {str(key): int(value) for key, value in result.get_counts().items()}


def prepare_state(qc: QuantumCircuit, qubit: int, name: str) -> None:
    if name == "0":
        return
    if name == "1":
        qc.x(qubit)
    elif name == "+":
        qc.h(qubit)
    elif name == "-":
        qc.x(qubit)
        qc.h(qubit)
    elif name == "i":
        qc.h(qubit)
        qc.s(qubit)
    elif name == "-i":
        qc.h(qubit)
        qc.sdg(qubit)
    else:
        raise ValueError(name)


def undo_state(qc: QuantumCircuit, qubit: int, name: str) -> None:
    """Apply the inverse of the state-preparation sequence."""
    if name == "0":
        return
    if name == "1":
        qc.x(qubit)
    elif name == "+":
        qc.h(qubit)
    elif name == "-":
        qc.h(qubit)
        qc.x(qubit)
    elif name == "i":
        qc.sdg(qubit)
        qc.h(qubit)
    elif name == "-i":
        qc.s(qubit)
        qc.h(qubit)
    else:
        raise ValueError(name)


def teleportation_verification_circuit(state_name: str) -> QuantumCircuit:
    q = QuantumRegister(3, "q")
    m0 = ClassicalRegister(1, "m0")
    m1 = ClassicalRegister(1, "m1")
    verify = ClassicalRegister(1, "verify")
    qc = QuantumCircuit(q, m0, m1, verify, name=f"Verify teleport {state_name}")
    prepare_state(qc, 0, state_name)
    qc.h(1)
    qc.cx(1, 2)
    qc.cx(0, 1)
    qc.h(0)
    qc.measure(0, m0[0])
    qc.measure(1, m1[0])
    with qc.if_test((m1[0], True)):
        qc.x(2)
    with qc.if_test((m0[0], True)):
        qc.z(2)
    undo_state(qc, 2, state_name)
    qc.measure(2, verify[0])
    return qc


def verification_marginal(counts: dict[str, int]) -> dict[str, int]:
    marginal = {"0": 0, "1": 0}
    for key, value in counts.items():
        first = key.split()[0]
        marginal[first[-1]] += value
    return marginal


def prepare_entangled_input(qc: QuantumCircuit) -> None:
    """Prepare (|2>|9> + |6>|5>)/sqrt(2) on a[0:4], b[4:8]."""
    # Shared 1-bits: a1 and b0. Branch 0 also has b3=1.
    qc.x(1)
    qc.x(4)
    qc.x(7)
    # q2 distinguishes a=2 from a=6 and controls the correlated b changes.
    qc.h(2)
    qc.cx(2, 6)
    qc.cx(2, 7)


def qft_adder_circuit(measured: bool = True) -> QuantumCircuit:
    qc = QuantumCircuit(8, 8 if measured else 0, name="4-qubit QFT adder")
    prepare_entangled_input(qc)
    qc.barrier()
    qc.append(DraperQFTAdder(4, kind="fixed"), range(8))
    if measured:
        qc.measure(range(8), range(8))
    return qc


def parse_ab(bitstring: str) -> tuple[int, int]:
    bits = bitstring.replace(" ", "")
    if len(bits) != 8:
        raise ValueError(f"Expected 8 bits, got {bitstring!r}")
    b = int(bits[:4], 2)
    a = int(bits[4:], 2)
    return a, b


def marginal_sum_register(counts: dict[str, int]) -> dict[int, int]:
    marginal = {value: 0 for value in range(16)}
    for key, count in counts.items():
        _, b = parse_ab(key)
        marginal[b] += count
    return marginal


def expected_output_state() -> Statevector:
    data = np.zeros(256, dtype=complex)
    data[2 + (11 << 4)] = 1 / np.sqrt(2)
    data[6 + (11 << 4)] = 1 / np.sqrt(2)
    return Statevector(data)


def main() -> dict[str, Any]:
    # 1. Teleportation: perfect simulator versus local noisy model.
    state_names = ["0", "1", "+", "-", "i", "-i"]
    teleportation: dict[str, Any] = {}
    ideal_success = []
    noisy_success = []
    for index, state_name in enumerate(state_names):
        circuit = teleportation_verification_circuit(state_name)
        ideal_counts_full = run_counts(circuit, noisy=False, shots=SHOTS, seed=SEED + index)
        noisy_counts_full = run_counts(circuit, noisy=True, shots=SHOTS, seed=SEED + 100 + index)
        ideal_counts = verification_marginal(ideal_counts_full)
        noisy_counts = verification_marginal(noisy_counts_full)
        ideal_rate = ideal_counts["0"] / SHOTS
        noisy_rate = noisy_counts["0"] / SHOTS
        ideal_success.append(ideal_rate)
        noisy_success.append(noisy_rate)
        teleportation[state_name] = {
            "ideal_verification_counts": ideal_counts,
            "noisy_verification_counts": noisy_counts,
            "ideal_success_rate": ideal_rate,
            "noisy_success_rate": noisy_rate,
        }
    save_circuit(teleportation_verification_circuit("+"), "teleportation_verification_circuit.png")

    x = np.arange(len(state_names))
    width = 0.36
    fig, ax = plt.subplots(figsize=(8.0, 4.5))
    ax.bar(x - width / 2, ideal_success, width, label="Ideal Aer")
    ax.bar(x + width / 2, noisy_success, width, label="Local noisy model")
    ax.set_xticks(x, [f"|{name}>" for name in state_names])
    ax.set_ylim(0, 1.05)
    ax.set_ylabel("Verification success rate")
    ax.set_title("Quantum teleportation: ideal and noisy simulation")
    ax.grid(axis="y", alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(FIG_DIR / "teleportation_ideal_vs_noisy.png", dpi=180)
    plt.close(fig)

    # 2. Entangled 4-bit addition with a Draper QFT adder.
    unmeasured = qft_adder_circuit(measured=False)
    output_state = Statevector.from_instruction(unmeasured)
    expected_state = expected_output_state()
    ideal_fidelity = float(state_fidelity(output_state, expected_state))

    measured = qft_adder_circuit(measured=True)
    ideal_counts = run_counts(measured, noisy=False, seed=SEED + 500)
    noisy_counts = run_counts(measured, noisy=True, seed=SEED + 600)
    ideal_sum = marginal_sum_register(ideal_counts)
    noisy_sum = marginal_sum_register(noisy_counts)
    expected_keys = ["10110010", "10110110"]

    save_circuit(unmeasured, "qft_adder_circuit.png")

    values = np.arange(16)
    fig, ax = plt.subplots(figsize=(9.0, 4.8))
    ax.bar(values - width / 2, [ideal_sum[v] for v in values], width, label="Ideal Aer")
    ax.bar(values + width / 2, [noisy_sum[v] for v in values], width, label="Local noisy model")
    ax.set_xticks(values)
    ax.set_xlabel("Measured value of the sum register b")
    ax.set_ylabel("Counts")
    ax.set_title(f"QFT addition of the entangled input ({SHOTS} shots)")
    ax.grid(axis="y", alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(FIG_DIR / "qft_addition_results.png", dpi=180)
    plt.close(fig)

    top_noisy = sorted(noisy_counts.items(), key=lambda item: item[1], reverse=True)[:12]
    results: dict[str, Any] = {
        "metadata": {
            "practice": "IQC-7",
            "language": "Python",
            "shots": SHOTS,
            "seed": SEED,
            "hardware_disclaimer": (
                "The noisy data were generated with a local Qiskit Aer noise model. "
                "They are not measurements from an IBM Quantum processor."
            ),
            "noise_model": {
                "one_qubit_depolarizing_probability": 0.004,
                "two_qubit_depolarizing_probability": 0.025,
                "readout_matrix": [[0.975, 0.025], [0.035, 0.965]],
            },
        },
        "teleportation": teleportation,
        "qft_addition": {
            "input_state": "(|2>|9> + |6>|5>)/sqrt(2)",
            "expected_output": "(|2>|11> + |6>|11>)/sqrt(2)",
            "ideal_state_fidelity": ideal_fidelity,
            "expected_bitstrings_q7_to_q0": expected_keys,
            "ideal_counts": ideal_counts,
            "noisy_top_counts": dict(top_noisy),
            "ideal_sum_register_counts": {str(k): v for k, v in ideal_sum.items()},
            "noisy_sum_register_counts": {str(k): v for k, v in noisy_sum.items()},
            "ideal_probability_b_equals_11": ideal_sum[11] / SHOTS,
            "noisy_probability_b_equals_11": noisy_sum[11] / SHOTS,
        },
    }
    for filename in ("IQC7_results.json", "result_qft_addition.json"):
        with (ROOT / filename).open("w", encoding="utf-8") as fh:
            json.dump(results, fh, indent=2)

    print("IQC-7 completed.")
    print(f"Ideal QFT-adder fidelity: {ideal_fidelity:.12f}")
    print(f"Ideal P(b=11): {ideal_sum[11] / SHOTS:.4f}")
    print(f"Noisy P(b=11): {noisy_sum[11] / SHOTS:.4f}")
    return results


if __name__ == "__main__":
    main()
