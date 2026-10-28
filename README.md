# SystemVerilog I/Q Pulse Detector

## Contributions
Built a simulated signal-processing circuit in SystemVerilog, a Python script to generate signal samples and expected results, and a testbench that checks the circuit's outputs automatically.

## My Decisions and Explanations
- Used a simulation-first approach to develop the detector without requiring an FPGA board.
- Calculated signal power using `I² + Q²`, allowing positive and negative signal components to contribute to the power measurement.
- Required four consecutive valid samples at or above a power threshold of 1,000,000 to reject short spikes.
- Used signed 12-bit inputs and a 25-bit power output to accommodate the full input range without overflow.
- Made detection last one clock cycle so another circuit could count or respond to each pulse.
- Required a below-threshold sample before another detection to prevent repeated events during one continuous pulse.

## Testing and Diagnosing
- Used Python to generate repeatable synthetic inputs and calculate expected detection and peak-power outputs.
- Used a SystemVerilog testbench to compare the circuit against those expected results.
- Passed all 34 sample checks, including noise rejection, single-sample spikes, three-sample pulses, sustained pulses, negative inputs, and maximum-magnitude inputs.
- Confirmed three pulse detections during the simulation.
- Icarus reported constant-select sensitivity warnings during compilation; the simulation completed and passed its checks.

## Features
- Streaming I/Q signal-power calculation.
- Configurable power threshold and required sample count.
- Short-spike rejection.
- One detection event per continuous pulse.
- Peak-power tracking.
- Automatic output checking and VCD waveform generation.

# Installation / Guide

Requires Python 3 and Icarus Verilog. Run these commands from the project folder.

1. Generate input samples and expected results:

   ```powershell
   py .\tools\generate_vectors.py
   ```

2. Create the build folder:

   ```powershell
   New-Item -ItemType Directory -Force -Path .\build | Out-Null
   ```

3. Compile the detector and testbench:

   ```powershell
   & "C:\iverilog\bin\iverilog.exe" -g2012 -s tb_pulse_detector -o .\build\pulse_sim .\rt1\pulse_detector.sv .\tb\tb_pulse_detector.sv
   ```

4. Run the simulation:

   ```powershell
   & "C:\iverilog\bin\vvp.exe" .\build\pulse_sim
   ```

Expected result:

```text
Detected pulse at vector 17, peak power = 3240000
Detected pulse at vector 28, peak power = 2930000
Detected pulse at vector 33, peak power = 8388608
PASS: all 34 vectors matched.
```

- **Waveforms:** Open `build/pulse_detector.vcd` in a compatible viewer, such as GTKWave.
- **Paths:** Commands use my Windows Icarus installation at `C:\iverilog\bin`. Adjust this path for your installation.

# Limitations / Performance (10/27/26)
- Tested with synthetic signal samples in simulation; not yet deployed on an FPGA or connected to a receiver.
- Detects sustained signal power; does not identify a signal's source or classify its contents.
- Four qualifying valid samples are required for detection. Invalid samples pause/will stop the count.
- Passing 34 sample checks confirms the tested cases, rather than every possible input sequence.
- FPGA resource usage, maximum clock frequency, and physical hardware performance have not been measured.
