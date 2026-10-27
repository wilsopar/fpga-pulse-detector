`timescale 1ns/1ps

module tb_pulse_detector;

    logic clk = 0;
    logic reset_n = 0;
    logic sample_valid = 0;

    logic signed [11:0] sample_i = 0;
    logic signed [11:0] sample_q = 0;

    logic pulse_detected;
    logic [24:0] peak_power;

    integer vector_file;
    integer scan_count;
    integer vector_number = 0;

    integer reset_value;
    integer valid_value;
    integer expected_detect;

    logic [11:0] i_bits;
    logic [11:0] q_bits;
    logic [24:0] expected_peak;

    // 10 ns clock period.
    always #5 clk = ~clk;

    pulse_detector dut (
        .clk(clk),
        .reset_n(reset_n),
        .sample_valid(sample_valid),
        .sample_i(sample_i),
        .sample_q(sample_q),
        .pulse_detected(pulse_detected),
        .peak_power(peak_power)
    );

    initial begin
        // Save signals for later viewing in a waveform viewer.
        $dumpfile("build/pulse_detector.vcd");
        $dumpvars(0, tb_pulse_detector);

        vector_file = $fopen("vectors/pulse_vectors.txt", "r");

        if (vector_file == 0)
            $fatal(1, "Cannot open vectors. Run the Python generator.");

        while (!$feof(vector_file)) begin
            scan_count = $fscanf(
                vector_file,
                "%d %d %h %h %d %h\n",
                reset_value,
                valid_value,
                i_bits,
                q_bits,
                expected_detect,
                expected_peak
            );

            if (scan_count != 6)
                $fatal(1, "Invalid vector file row.");

            // Apply inputs before the next rising clock edge.
            @(negedge clk);
            reset_n = reset_value[0];
            sample_valid = valid_value[0];
            sample_i = $signed(i_bits);
            sample_q = $signed(q_bits);

            // Wait for registered outputs to update.
            @(posedge clk);
            #1;

            vector_number = vector_number + 1;

            if (pulse_detected !== expected_detect[0]) begin
                $display(
                    "FAIL vector %0d: expected detection %0d, got %0d",
                    vector_number, expected_detect, pulse_detected
                );
                $fatal(1, "Detection mismatch.");
            end

            if (peak_power !== expected_peak) begin
                $display(
                    "FAIL vector %0d: expected peak %0d, got %0d",
                    vector_number, expected_peak, peak_power
                );
                $fatal(1, "Peak power mismatch.");
            end

            if (pulse_detected)
                $display(
                    "Detected pulse at vector %0d, peak power = %0d",
                    vector_number, peak_power
                );
        end

        $fclose(vector_file);
        $display("PASS: all %0d vectors matched.", vector_number);
        $finish;
    end

endmodule