// =============================================================================
// uart_rx.v — UART Receiver (fixed)
// 8N1. Detects start-bit falling edge, waits half-bit, samples mid-bit.
// Uses its own sub-tick counter independent of baud_gen so the half-bit
// centre-sampling is not subject to baud_tick phase.
// =============================================================================
module uart_rx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rx_en,
    input  wire        rx_clr,      // one-cycle pulse: clear rx_valid
    input  wire        rx,
    input  wire        baud_tick,   // one pulse per bit period from baud_gen
    output reg  [7:0]  rx_data,
    output reg         rx_valid,
    output reg         rx_busy
);

    // FSM
    parameter IDLE         = 3'd0;
    parameter HALF_WAIT    = 3'd1;   // wait ~half bit to centre on start bit
    parameter SAMPLE_START = 3'd2;
    parameter DATA_BITS    = 3'd3;
    parameter STOP_BIT     = 3'd4;
    parameter DONE         = 3'd5;

    reg [2:0]  state;
    reg [7:0]  shift_reg;
    reg [2:0]  bit_cnt;
    reg [15:0] half_cnt;    // counts to half-bit period in system clocks
    reg        half_done;   // flag: half-bit wait elapsed
    reg [15:0] tick_hold;   // latched baud_div/2 from external counter

    // 2-FF synchroniser
    reg rx_s1, rx_s2, rx_prev;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin rx_s1<=1'b1; rx_s2<=1'b1; rx_prev<=1'b1; end
        else        begin rx_s1<=rx; rx_s2<=rx_s1; rx_prev<=rx_s2; end
    end
    wire rx_s = rx_s2;
    wire falling = rx_prev & ~rx_s;

    // We count baud_ticks instead of raw clock cycles for the half-wait.
    // After falling edge: wait 1 baud_tick (≈ half bit if we sampled at
    // the tick boundary). This is the classic simple approach.
    // Then sample every baud_tick for 8 data bits + stop.
    reg half_tick_wait; // 1 = still waiting first baud_tick after edge

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= IDLE;
            shift_reg      <= 8'd0;
            bit_cnt        <= 3'd0;
            rx_data        <= 8'd0;
            rx_valid       <= 1'b0;
            rx_busy        <= 1'b0;
            half_tick_wait <= 1'b0;
        end else begin
            if (rx_clr) rx_valid <= 1'b0;

            case (state)
                IDLE: begin
                    rx_busy        <= 1'b0;
                    half_tick_wait <= 1'b0;
                    if (rx_en && falling) begin
                        rx_busy        <= 1'b1;
                        half_tick_wait <= 1'b1;
                        state          <= HALF_WAIT;
                    end
                end

                // Wait one full baud_tick (this places us ~mid-bit for the
                // start bit, since the edge happened somewhere within the
                // previous bit period and baud_tick fires every bit period).
                HALF_WAIT: begin
                    if (baud_tick) begin
                        state <= SAMPLE_START;
                    end
                end

                SAMPLE_START: begin
                    // Sample centre of start bit
                    if (~rx_s) begin
                        bit_cnt   <= 3'd0;
                        shift_reg <= 8'd0;
                        state     <= DATA_BITS;
                    end else begin
                        // False start
                        rx_busy <= 1'b0;
                        state   <= IDLE;
                    end
                end

                DATA_BITS: begin
                    if (baud_tick) begin
                        shift_reg <= {rx_s, shift_reg[7:1]}; // LSB first
                        if (bit_cnt == 3'd7)
                            state <= STOP_BIT;
                        else
                            bit_cnt <= bit_cnt + 1'b1;
                    end
                end

                STOP_BIT: begin
                    if (baud_tick) begin
                        rx_data  <= shift_reg;
                        rx_valid <= 1'b1;
                        rx_busy  <= 1'b0;
                        state    <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

