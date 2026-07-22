BER PERFORMANCE ANALYSIS PRACTICE

Files
-----
- BER_Performance_Analysis_Report.pdf: English technical report.
- MonteCarloYEnfatizado.m: complete, memory-safe MATLAB implementation.
- MCandIIS.m: compact comparison script close to the laboratory template.
- BER_results.mat: numerical variables used for the report figures.
- Figure_1_MonteCarlo.png and Figure_2_ImportanceSampling.png: report plots.

Execution
---------
1. Open MATLAB and set this folder as the current directory.
2. Run MonteCarloYEnfatizado.m for the complete practice.
3. The script creates BER_results.mat after execution.

Note
----
The conventional simulation uses N=10^7 bits at every SNR point and can
therefore take several minutes depending on the computer. The block-based
implementation limits memory usage while preserving the requested sample count.
