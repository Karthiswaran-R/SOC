// =============================================================================
// uart_tx.v — UART Transmitter
// 8N1 format: Start(0) | D0..D7 (LSB first) | Stop(1)
// Transmission begins when tx_start is pulsed with tx_en asserted.
// =============================================================================
module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_en,       // TX_EN from CONTROL register
    input  wire       tx_start,    // pulse when software writes DATA register
    input  wire [7:0] tx_data,     // byte to transmit
    input  wire       baud_tick,   // one tick per bit period
    output reg        tx,          // serial output line
    output reg        tx_ready,    // 1 = ready to accept new byte
    output reg        tx_busy      // 1 = transmission in progress
);

    // FSM states
    parameter IDLE      = 2'd0;
    parameter START_BIT = 2'd1;
    parameter DATA_BITS = 2'd2;
    parameter STOP_BIT  = 2'd3;

    reg [1:0] state;
    reg [7:0] shift_reg;   // holds the byte being shifted out
    reg [2:0] bit_cnt;     // counts 0..7 for the 8 data bits

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            tx        <= 1'b1;   // idle high
            tx_ready  <= 1'b1;
            tx_busy   <= 1'b0;
            shift_reg <= 8'd0;
            bit_cnt   <= 3'd0;
        end else begin
            case (state)

                // ----------------------------------------------------------
                IDLE: begin
                    tx       <= 1'b1;   // keep line idle-high
                    tx_busy  <= 1'b0;
                    tx_ready <= tx_en;  // only ready when enabled

                    if (tx_en && tx_start) begin
                        shift_reg <= tx_data;
                        tx_ready  <= 1'b0;
                        tx_busy   <= 1'b1;
                        state     <= START_BIT;
                    end
                end

                // ----------------------------------------------------------
                START_BIT: begin
                    tx <= 1'b0;         // drive start bit LOW
                    if (baud_tick) begin
                        bit_cnt <= 3'd0;
                        state   <= DATA_BITS;
                    end
                end

                // ----------------------------------------------------------
                DATA_BITS: begin
                    tx <= shift_reg[0]; // LSB first
                    if (baud_tick) begin
                        shift_reg <= shift_reg >> 1;
                        if (bit_cnt == 3'd7) begin
                            state <= STOP_BIT;
                        end else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                end

                // ----------------------------------------------------------
                STOP_BIT: begin
                    tx <= 1'b1;         // stop bit HIGH
                    if (baud_tick) begin
                        tx_busy  <= 1'b0;
                        tx_ready <= 1'b1;
                        state    <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

