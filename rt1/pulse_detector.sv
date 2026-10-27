module pulse_detector #(
    parameter integer SAMPLE_WIDTH = 12,
    parameter integer POWER_THRESHOLD = 1_000_000,
    parameter integer CONSECUTIVE_REQUIRED = 4
) (
    input  logic clk,
    input  logic reset_n,
    input  logic sample_valid,

    input  logic signed [SAMPLE_WIDTH-1:0] sample_i,
    input  logic signed [SAMPLE_WIDTH-1:0] sample_q,

    output logic pulse_detected,
    output logic [2*SAMPLE_WIDTH:0] peak_power
);

    localparam integer POWER_WIDTH = 2 * SAMPLE_WIDTH + 1;

    localparam integer COUNT_WIDTH =
        (CONSECUTIVE_REQUIRED <= 1)
        ? 1 : $clog2(CONSECUTIVE_REQUIRED + 1);

    logic signed [2*SAMPLE_WIDTH-1:0] i_extended;
    logic signed [2*SAMPLE_WIDTH-1:0] q_extended;
    logic signed [2*SAMPLE_WIDTH-1:0] square_i;
    logic signed [2*SAMPLE_WIDTH-1:0] square_q;

    logic [POWER_WIDTH-1:0] power_value;
    logic [POWER_WIDTH-1:0] candidate_peak;

    logic [COUNT_WIDTH-1:0] high_count;
    logic in_pulse;

    // Calculate signal power: I squared plus Q squared.
    always_comb begin
        i_extended = {
            {SAMPLE_WIDTH{sample_i[SAMPLE_WIDTH-1]}},
            sample_i
        };

        q_extended = {
            {SAMPLE_WIDTH{sample_q[SAMPLE_WIDTH-1]}},
            sample_q
        };

        square_i = i_extended * i_extended;
        square_q = q_extended * q_extended;

        power_value = {1'b0, square_i} + {1'b0, square_q};
    end

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            high_count     <= '0;
            in_pulse       <= 1'b0;
            candidate_peak <= '0;
            peak_power     <= '0;
            pulse_detected <= 1'b0;
        end else begin
            // Detection is asserted for only one clock.
            pulse_detected <= 1'b0;

            if (sample_valid) begin
                if (power_value >= POWER_THRESHOLD) begin
                    if (in_pulse) begin
                        // Continue measuring the detected pulse.
                        if (power_value > peak_power)
                            peak_power <= power_value;
                    end else begin
                        // Track the peak while qualifying a pulse.
                        if ((high_count == 0) ||
                            (power_value > candidate_peak))
                            candidate_peak <= power_value;

                        if (high_count ==
                            CONSECUTIVE_REQUIRED - 1) begin

                            pulse_detected <= 1'b1;
                            in_pulse       <= 1'b1;
                            high_count     <= '0;

                            if ((high_count == 0) ||
                                (power_value > candidate_peak))
                                peak_power <= power_value;
                            else
                                peak_power <= candidate_peak;
                        end else begin
                            high_count <= high_count + 1'b1;
                        end
                    end
                end else begin
                    // A low sample rearms detection.
                    high_count     <= '0;
                    in_pulse       <= 1'b0;
                    candidate_peak <= '0;
                end
            end
        end
    end

endmodule