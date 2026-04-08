// =============================================================================
// baud_gen.v — Baud Rate Generator
// Generates a single-cycle baud_tick pulse once per bit period.
// baud_div = clk_freq / baud_rate  (e.g. 50_000_000 / 9600 = 5208)
// =============================================================================
module baud_gen (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] baud_div,   // loaded from BAUD_DIV register
    output reg         baud_tick   // one-cycle pulse per bit period
);

    reg [15:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter   <= 16'd0;
            baud_tick <= 1'b0;
        end else begin
            if (counter >= baud_div - 1) begin
                counter   <= 16'd0;
                baud_tick <= 1'b1;
            end else begin
                counter   <= counter + 1'b1;
                baud_tick <= 1'b0;
            end
        end
    end

endmodule

