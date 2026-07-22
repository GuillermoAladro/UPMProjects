#!/usr/bin/env python3
"""IQC-1: one-qubit gates, controlled gates, Bell states and no-cloning.

The exercise is implemented in Python with Qiskit, NumPy and Matplotlib.
It runs entirely offline and saves reproducible numerical results and figures.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from qiskit import QuantumCircuit
from qiskit.circuit.library import HGate, XGate
from qiskit.quantum_info import DensityMatrix, Operator, Statevector, partial_trace

SEED = 2026
ROOT = Path(__file__).resolve().parent
FIG_DIR = ROOT / "figures"
FIG_DIR.mkdir(exist_ok=True)


def carray(values: np.ndarray) -> list[dict[str, float]]:
    """Convert a complex NumPy vector into JSON-safe real/imag pairs."""
    return [{"real": float(z.real), "imag": float(z.imag)} for z in np.asarray(values).ravel()]


def bloch_vector(rho: DensityMatrix | np.ndarray) -> list[float]:
    matrix = rho.data if isinstance(rho, DensityMatrix) else np.asarray(rho)
    x = np.array([[0, 1], [1, 0]], dtype=complex)
    y = np.array([[0, -1j], [1j, 0]], dtype=complex)
    z = np.array([[1, 0], [0, -1]], dtype=complex)
    return [float(np.real(np.trace(matrix @ p))) for p in (x, y, z)]


def save_circuit(circuit: QuantumCircuit, filename: str) -> None:
    fig = circuit.draw(output="mpl", fold=-1)
    fig.savefig(FIG_DIR / filename, dpi=180, bbox_inches="tight")
    plt.close(fig)


def prepare_one_qubit_circuits() -> dict[str, QuantumCircuit]:
    circuits: dict[str, QuantumCircuit] = {}
    qc = QuantumCircuit(1, name="|1>")
    qc.x(0)
    circuits["|1>"] = qc

    qc = QuantumCircuit(1, name="|+>")
    qc.h(0)
    circuits["|+>"] = qc

    qc = QuantumCircuit(1, name="|->")
    qc.h(0)
    qc.z(0)
    circuits["|->"] = qc

    qc = QuantumCircuit(1, name="|R>")
    qc.h(0)
    qc.s(0)
    circuits["|R>"] = qc
    return circuits


def bell_circuits() -> dict[str, QuantumCircuit]:
    circuits: dict[str, QuantumCircuit] = {}
    for name in ("Phi+", "Phi-", "Psi+", "Psi-"):
        qc = QuantumCircuit(2, name=name)
        qc.h(0)
        qc.cx(0, 1)
        if name in ("Phi-", "Psi-"):
            qc.z(0)
        if name in ("Psi+", "Psi-"):
            qc.x(1)
        circuits[name] = qc
    return circuits


def controlled_truth_table(gate_name: str, anti_control: bool = False) -> dict[str, str]:
    table: dict[str, str] = {}
    gate = XGate() if gate_name == "X" else HGate()
    controlled = gate.control(1, ctrl_state=0 if anti_control else 1)
    for value in range(4):
        qc = QuantumCircuit(2)
        if value & 1:
            qc.x(0)
        if value & 2:
            qc.x(1)
        qc.append(controlled, [0, 1])
        state = Statevector.from_instruction(qc)
        probs = state.probabilities_dict()
        table[f"{value:02b}"] = max(probs, key=probs.get)
    return table


def main() -> dict[str, Any]:
    rng = np.random.default_rng(SEED)
    _ = rng  # seed recorded for reproducibility; calculations are deterministic.

    # 1. Gate products.
    i2 = np.eye(2, dtype=complex)
    x = Operator(XGate()).data
    h = Operator(HGate()).data
    sqrt_x = 0.5 * np.array([[1 + 1j, 1 - 1j], [1 - 1j, 1 + 1j]], dtype=complex)
    gate_errors = {
        "||X.X-I||": float(np.linalg.norm(x @ x - i2)),
        "||H.H-I||": float(np.linalg.norm(h @ h - i2)),
        "||sqrt(X)^2-X||": float(np.linalg.norm(sqrt_x @ sqrt_x - x)),
    }

    # 2. One-qubit states.
    one_q_circuits = prepare_one_qubit_circuits()
    one_q_results: dict[str, Any] = {}
    for label, qc in one_q_circuits.items():
        state = Statevector.from_instruction(qc)
        rho = DensityMatrix(state)
        one_q_results[label] = {
            "amplitudes": carray(state.data),
            "probabilities": {k: float(v) for k, v in state.probabilities_dict().items()},
            "bloch_vector": bloch_vector(rho),
        }
    save_circuit(one_q_circuits["|R>"], "one_qubit_R_circuit.png")

    labels = list(one_q_results)
    p0 = [one_q_results[label]["probabilities"].get("0", 0.0) for label in labels]
    p1 = [one_q_results[label]["probabilities"].get("1", 0.0) for label in labels]
    xx = np.arange(len(labels))
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    width = 0.36
    ax.bar(xx - width / 2, p0, width, label="|0>")
    ax.bar(xx + width / 2, p1, width, label="|1>")
    ax.set_xticks(xx, labels)
    ax.set_ylim(0, 1.08)
    ax.set_ylabel("Probability")
    ax.set_title("Prepared one-qubit states")
    ax.grid(axis="y", alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(FIG_DIR / "one_qubit_probabilities.png", dpi=180)
    plt.close(fig)

    # 3. Controlled and anti-controlled gates.
    truth_tables = {
        "CNOT": controlled_truth_table("X", anti_control=False),
        "anti-CNOT": controlled_truth_table("X", anti_control=True),
        "controlled-H": controlled_truth_table("H", anti_control=False),
        "anti-controlled-H": controlled_truth_table("H", anti_control=True),
    }

    control_demo = QuantumCircuit(2)
    control_demo.h(0)
    control_demo.cx(0, 1)
    save_circuit(control_demo, "controlled_gate_demo.png")

    # 4. Bell states.
    bells = bell_circuits()
    bell_results: dict[str, Any] = {}
    bell_prob_matrix = []
    basis = ["00", "01", "10", "11"]
    for label, qc in bells.items():
        state = Statevector.from_instruction(qc)
        probs = state.probabilities_dict()
        bell_results[label] = {
            "amplitudes": carray(state.data),
            "probabilities": {key: float(probs.get(key, 0.0)) for key in basis},
        }
        bell_prob_matrix.append([probs.get(key, 0.0) for key in basis])
    save_circuit(bells["Phi+"], "bell_phi_plus_circuit.png")

    fig, ax = plt.subplots(figsize=(8.0, 4.5))
    matrix = np.asarray(bell_prob_matrix)
    width = 0.19
    xx = np.arange(4)
    for k, basis_state in enumerate(basis):
        ax.bar(xx + (k - 1.5) * width, matrix[:, k], width, label=f"|{basis_state}>")
    ax.set_xticks(xx, list(bells))
    ax.set_ylim(0, 0.62)
    ax.set_ylabel("Probability")
    ax.set_title("Bell-state computational-basis probabilities")
    ax.grid(axis="y", alpha=0.3)
    ax.legend(ncol=4, fontsize=8)
    fig.tight_layout()
    fig.savefig(FIG_DIR / "bell_state_probabilities.png", dpi=180)
    plt.close(fig)

    # 5. No-cloning demonstration.
    plus_plus = QuantumCircuit(2)
    plus_plus.h([0, 1])
    sv_plus_plus = Statevector.from_instruction(plus_plus)

    cloning_attempt = QuantumCircuit(2)
    cloning_attempt.h(0)
    cloning_attempt.cx(0, 1)
    sv_clone = Statevector.from_instruction(cloning_attempt)
    rho_clone = DensityMatrix(sv_clone)
    rho_q0 = partial_trace(rho_clone, [1])
    rho_q1 = partial_trace(rho_clone, [0])
    purities = {
        "control": float(np.real(np.trace(rho_q0.data @ rho_q0.data))),
        "target": float(np.real(np.trace(rho_q1.data @ rho_q1.data))),
    }
    save_circuit(cloning_attempt, "no_cloning_circuit.png")

    # 6. Register A = |+>|+>; Register B = Bell state Phi+.
    reg_a = Statevector.from_instruction(plus_plus)
    reg_b = sv_clone
    reduced: dict[str, Any] = {}
    for register_name, state in (("A", reg_a), ("B", reg_b)):
        rho = DensityMatrix(state)
        for q in (0, 1):
            red = partial_trace(rho, [1 - q])
            reduced[f"{register_name}{q + 1}"] = {
                "P(1)": float(red.probabilities()[1]),
                "bloch_vector": bloch_vector(red),
                "purity": float(np.real(np.trace(red.data @ red.data))),
            }

    hh_a = QuantumCircuit(2)
    hh_a.h([0, 1])
    reg_a_after_h = reg_a.evolve(hh_a)
    reg_b_after_h = reg_b.evolve(hh_a)

    results: dict[str, Any] = {
        "metadata": {
            "practice": "IQC-1",
            "language": "Python",
            "libraries": ["Qiskit", "NumPy", "Matplotlib"],
            "seed": SEED,
            "basis_order_note": "Qiskit displays two-qubit bit strings as q1q0.",
        },
        "gate_product_errors": gate_errors,
        "one_qubit_states": one_q_results,
        "controlled_gate_truth_tables": truth_tables,
        "bell_states": bell_results,
        "no_cloning": {
            "plus_plus_amplitudes": carray(sv_plus_plus.data),
            "cnot_plus_zero_amplitudes": carray(sv_clone.data),
            "reduced_state_purities": purities,
            "conclusion": "CNOT creates an entangled Bell state instead of the product state |+>|+>.",
        },
        "individual_qubits": reduced,
        "after_hadamard": {
            "register_A": {k: float(v) for k, v in reg_a_after_h.probabilities_dict().items()},
            "register_B": {k: float(v) for k, v in reg_b_after_h.probabilities_dict().items()},
        },
    }

    with (ROOT / "IQC1_results.json").open("w", encoding="utf-8") as fh:
        json.dump(results, fh, indent=2)

    print("IQC-1 completed.")
    for name, error in gate_errors.items():
        print(f"{name}: {error:.3e}")
    print("No-cloning reduced-state purities:", purities)
    return results


if __name__ == "__main__":
    main()
