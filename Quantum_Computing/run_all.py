#!/usr/bin/env python3
"""Run the three quantum-computing practices sequentially."""
from __future__ import annotations
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCRIPTS = [
    ROOT / "01_IQC1_Quantum_Fundamentals" / "iqc1_quantum_fundamentals.py",
    ROOT / "02_IQC2_Entanglement_Teleportation" / "iqc2_entanglement_teleportation.py",
    ROOT / "03_IQC7_QFT_Addition" / "iqc7_qft_addition.py",
]

for script in SCRIPTS:
    print(f"\n=== Running {script.parent.name} ===")
    subprocess.run([sys.executable, script.name], cwd=script.parent, check=True)
print("\nAll practices completed successfully.")
