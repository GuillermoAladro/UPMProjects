#!/usr/bin/env python3
"""IQC-2: Bell states, superdense coding and quantum teleportation.

The program uses Qiskit Aer for 1000-shot simulations and SciPy for the
chi-square and binomial tests requested by the laboratory statement.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Callable

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from qiskit import ClassicalRegister, QuantumCircuit, QuantumRegister, transpile
from qiskit.quantum_info import DensityMatrix, Statevector, partial_trace, state_fidelity
from qiskit_aer import AerSimulator
from scipy.stats import binomtest, chisquare

SHOTS = 1000
SEED = 2026
ROOT = Path(__file__).resolve().parent
FIG_DIR = ROOT / "figures"
FIG_DIR.mkdir(exist_ok=True)
BACKEND = AerSimulator()


def save_circuit(circuit: QuantumCircuit, filename: str) -> None:
    fig = circuit.draw(output="mpl", fold=-1)
    fig.savefig(FIG_DIR / filename, dpi=180, bbox_inches="tight")
    plt.close(fig)


def run_counts(circuit: QuantumCircuit, shots: int = SHOTS, seed: int = SEED) -> dict[str, int]:
    compiled = transpile(circuit, BACKEND, optimization_level=1, seed_transpiler=seed)
    result = BACKEND.run(compiled, shots=shots, seed_simulator=seed).result()
    return {str(k): int(v) for k, v in result.get_counts().items()}


def bell_circuit(name: str, measured: bool = True) -> QuantumCircuit:
    qc = QuantumCircuit(2, 2 if measured else 0, name=name)
    qc.h(0)
    qc.cx(0, 1)
    if name in ("Phi-", "Psi-"):
        qc.z(0)
    if name in ("Psi+", "Psi-"):
        qc.x(1)
    if measured:
        qc.measure([0, 1], [0, 1])
    return qc


def superdense_circuit(message: str) -> QuantumCircuit:
    """Encode message b1b0 with Z^b1 X^b0 on Alice's qubit."""
    qc = QuantumCircuit(2, 2, name=f"SDC {message}")
    qc.h(0)
    qc.cx(0, 1)
    if message[1] == "1":
        qc.x(0)
    if message[0] == "1":
        qc.z(0)
    qc.cx(0, 1)
    qc.h(0)
    qc.measure([0, 1], [0, 1])
    return qc


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
        raise ValueError(f"Unknown state {name!r}")


def statevector_for_name(name: str) -> Statevector:
    qc = QuantumCircuit(1)
    prepare_state(qc, 0, name)
    return Statevector.from_instruction(qc)


def teleportation_circuit(state_name: str, final_h: bool = False) -> QuantumCircuit:
    q = QuantumRegister(3, "q")
    m0 = ClassicalRegister(1, "m0")
    m1 = ClassicalRegister(1, "m1")
    out = ClassicalRegister(1, "out")
    qc = QuantumCircuit(q, m0, m1, out, name=f"Teleport {state_name}")

    prepare_state(qc, 0, state_name)
    qc.barrier()
    qc.h(1)
    qc.cx(1, 2)
    qc.barrier()
    qc.cx(0, 1)
    qc.h(0)
    qc.measure(0, m0[0])
    qc.measure(1, m1[0])
    with qc.if_test((m1[0], True)):
        qc.x(2)
    with qc.if_test((m0[0], True)):
        qc.z(2)
    if final_h:
        qc.h(2)
    qc.measure(2, out[0])
    return qc


def coherent_teleportation_fidelity(state_name: str) -> float:
    """Use deferred measurement to verify the exact teleported state."""
    qc = QuantumCircuit(3)
    prepare_state(qc, 0, state_name)
    qc.h(1)
    qc.cx(1, 2)
    qc.cx(0, 1)
    qc.h(0)
    qc.cx(1, 2)
    qc.cz(0, 2)
    full = DensityMatrix(Statevector.from_instruction(qc))
    bob = partial_trace(full, [0, 1])
    return float(state_fidelity(bob, statevector_for_name(state_name)))


def output_marginal(counts: dict[str, int]) -> dict[str, int]:
    """Extract the final 'out' register from keys formatted as 'out m1 m0'."""
    marginal = {"0": 0, "1": 0}
    for key, value in counts.items():
        first_register = key.split()[0]
        marginal[first_register[-1]] += value
    return marginal


def expected_probability_one(state_name: str, final_h: bool = False) -> float:
    state = statevector_for_name(state_name)
    if final_h:
        h = QuantumCircuit(1)
        h.h(0)
        state = state.evolve(h)
    return float(state.probabilities()[1])


def main() -> dict[str, Any]:
    # 1. Bell-state simulation and chi-square tests.
    bell_names = ["Phi+", "Phi-", "Psi+", "Psi-"]
    basis = ["00", "01", "10", "11"]
    bell_results: dict[str, Any] = {}
    bell_matrix = []
    for offset, name in enumerate(bell_names):
        qc = bell_circuit(name, measured=True)
        counts = run_counts(qc, seed=SEED + offset)
        unmeasured = bell_circuit(name, measured=False)
        theory = Statevector.from_instruction(unmeasured).probabilities_dict()
        support = [key for key in basis if theory.get(key, 0.0) > 1e-12]
        observed = [counts.get(key, 0) for key in support]
        expected = [SHOTS * theory[key] for key in support]
        test = chisquare(observed, f_exp=expected)
        bell_results[name] = {
            "counts": {key: counts.get(key, 0) for key in basis},
            "theoretical_probabilities": {key: float(theory.get(key, 0.0)) for key in basis},
            "chi_square": float(test.statistic),
            "p_value": float(test.pvalue),
        }
        bell_matrix.append([counts.get(key, 0) for key in basis])
    save_circuit(bell_circuit("Phi+", measured=True), "bell_phi_plus_qiskit.png")

    fig, ax = plt.subplots(figsize=(8.0, 4.5))
    matrix = np.asarray(bell_matrix)
    x = np.arange(4)
    width = 0.19
    for j, bitstring in enumerate(basis):
        ax.bar(x + (j - 1.5) * width, matrix[:, j], width, label=bitstring)
    ax.set_xticks(x, bell_names)
    ax.set_ylabel("Counts")
    ax.set_title(f"Bell-state measurements ({SHOTS} shots)")
    ax.grid(axis="y", alpha=0.3)
    ax.legend(ncol=4)
    fig.tight_layout()
    fig.savefig(FIG_DIR / "bell_measurements.png", dpi=180)
    plt.close(fig)

    # 2. Superdense coding.
    superdense: dict[str, Any] = {}
    for offset, message in enumerate(("00", "01", "10", "11")):
        qc = superdense_circuit(message)
        raw_counts = run_counts(qc, seed=SEED + 10 + offset)
        # Qiskit displays classical bits as c1c0. Reverse the key so that the
        # reported logical message follows the laboratory convention b1b0.
        counts = {key[::-1]: value for key, value in raw_counts.items()}
        decoded = max(counts, key=counts.get)
        superdense[message] = {"counts": counts, "decoded_message": decoded}
    save_circuit(superdense_circuit("11"), "superdense_coding_11.png")

    # 3. Dynamic-circuit quantum teleportation.
    state_names = ["0", "1", "+", "-", "i", "-i"]
    teleportation: dict[str, Any] = {}
    normal_matrix = []
    h_matrix = []
    for index, state_name in enumerate(state_names):
        state_result: dict[str, Any] = {}
        for final_h, label in ((False, "computational_basis"), (True, "after_hadamard")):
            qc = teleportation_circuit(state_name, final_h=final_h)
            counts_full = run_counts(qc, seed=SEED + 100 + 2 * index + int(final_h))
            counts = output_marginal(counts_full)
            p1_expected = expected_probability_one(state_name, final_h=final_h)
            test_result = None
            if np.isclose(p1_expected, 0.5):
                test = binomtest(counts["1"], SHOTS, p=0.5, alternative="two-sided")
                test_result = {"statistic": float(test.statistic), "p_value": float(test.pvalue)}
            state_result[label] = {
                "counts": counts,
                "expected_P1": p1_expected,
                "binomial_test": test_result,
            }
        state_result["coherent_verification_fidelity"] = coherent_teleportation_fidelity(state_name)
        teleportation[state_name] = state_result
        normal_matrix.append([
            state_result["computational_basis"]["counts"]["0"],
            state_result["computational_basis"]["counts"]["1"],
        ])
        h_matrix.append([
            state_result["after_hadamard"]["counts"]["0"],
            state_result["after_hadamard"]["counts"]["1"],
        ])
    save_circuit(teleportation_circuit("+", final_h=False), "teleportation_dynamic_circuit.png")

    fig, ax = plt.subplots(figsize=(8.0, 4.5))
    normal = np.asarray(normal_matrix)
    x = np.arange(len(state_names))
    ax.bar(x, normal[:, 0], label="0")
    ax.bar(x, normal[:, 1], bottom=normal[:, 0], label="1")
    ax.set_xticks(x, [f"|{name}>" for name in state_names])
    ax.set_ylabel("Counts")
    ax.set_title("Measurement of the teleported qubit")
    ax.grid(axis="y", alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(FIG_DIR / "teleportation_measurements.png", dpi=180)
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(8.0, 4.5))
    after_h = np.asarray(h_matrix)
    ax.bar(x, after_h[:, 0], label="0")
    ax.bar(x, after_h[:, 1], bottom=after_h[:, 0], label="1")
    ax.set_xticks(x, [f"H|{name}>" for name in state_names])
    ax.set_ylabel("Counts")
    ax.set_title("Teleported qubit after an additional Hadamard gate")
    ax.grid(axis="y", alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(FIG_DIR / "teleportation_after_h.png", dpi=180)
    plt.close(fig)

    results: dict[str, Any] = {
        "metadata": {
            "practice": "IQC-2",
            "language": "Python",
            "libraries": ["Qiskit", "Qiskit Aer", "SciPy", "NumPy", "Matplotlib"],
            "shots": SHOTS,
            "seed": SEED,
            "significance_level": 0.05,
        },
        "bell_states": bell_results,
        "superdense_coding": superdense,
        "teleportation": teleportation,
    }
    with (ROOT / "IQC2_results.json").open("w", encoding="utf-8") as fh:
        json.dump(results, fh, indent=2)

    print("IQC-2 completed.")
    for name in bell_names:
        row = bell_results[name]
        print(f"{name}: counts={row['counts']}, p={row['p_value']:.4f}")
    for state_name in state_names:
        row = teleportation[state_name]["computational_basis"]
        print(f"Teleport |{state_name}>: {row['counts']}")
    return results


if __name__ == "__main__":
    main()
