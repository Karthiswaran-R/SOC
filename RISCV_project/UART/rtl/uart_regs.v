// =============================================================================
// uart_regs.v — Memory-mapped register interface
//
// Offset  Register    Access
// 0x00    DATA        R/W  — write: TX byte,  read: RX byte
// 0x04    STATUS      R    — {28'b0, RX_BUSY, TX_BUSY, RX_VALID, TX_READY}
// 0x08    CONTROL     R/W  — {29'b0, RX_CLR, RX_EN, TX_EN}
// 0x0C    BAUD_DIV    R/W  — 16-bit baud divisor
// =============================================================================
module uart_regs (
    input  wire        clk,
    input  wire        rst_n,

    // Bus interface
    input  wire [7:0]  addr,       // register offset (byte address)
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        write_en,
    input  wire        read_en,
    output reg         ready,      // single-cycle ack

    // Connections to TX block
    output reg  [7:0]  tx_data,
    output reg         tx_start,   // one-cycle pulse
    input  wire        tx_ready,
    input  wire        tx_busy,

    // Connections to RX block
    input  wire [7:0]  rx_data,
    input  wire        rx_valid,
    input  wire        rx_busy,

    // Control outputs
    output reg         tx_en,
    output reg         rx_en,
    output reg         rx_clr,     // one-cycle pulse to clear rx_valid

    // BAUD_DIV output
    output reg  [15:0] baud_div
);

    // Register address offsets
    parameter ADDR_DATA    = 8'h00;
    parameter ADDR_STATUS  = 8'h04;
    parameter ADDR_CONTROL = 8'h08;
    parameter ADDR_BAUD    = 8'h0C;

    // Default baud divisor: 50_000_000 / 9600 ≈ 5208
    parameter DEFAULT_BAUD_DIV = 16'd5208;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata    <= 32'd0;
            ready    <= 1'b0;
            tx_data  <= 8'd0;
            tx_start <= 1'b0;
            tx_en    <= 1'b0;
            rx_en    <= 1'b0;
            rx_clr   <= 1'b0;
            baud_div <= DEFAULT_BAUD_DIV;
        end else begin
            // Default pulse signals LOW every cycle
            tx_start <= 1'b0;
            rx_clr   <= 1'b0;
            ready    <= 1'b0;

            // ----------------------------------------------------------------
            // WRITE
            // ----------------------------------------------------------------
            if (write_en) begin
                case (addr)
                    ADDR_DATA: begin
                        tx_data  <= wdata[7:0];
                        tx_start <= 1'b1;   // pulse TX
                    end
                    ADDR_STATUS: begin
                        // Read-only register — writes ignored
                    end
                    ADDR_CONTROL: begin
                        tx_en  <= wdata[0];
                        rx_en  <= wdata[1];
                        rx_clr <= wdata[2];  // pulse to clear RX_VALID
                    end
                    ADDR_BAUD: begin
                        baud_div <= wdata[15:0];
                    end
                    default: ;
                endcase
                ready <= 1'b1;
            end

            // ----------------------------------------------------------------
            // READ
            // ----------------------------------------------------------------
            if (read_en) begin
                case (addr)
                    ADDR_DATA: begin
                        rdata <= {24'd0, rx_data};
                    end
                    ADDR_STATUS: begin
                        rdata <= {28'd0,
                                  rx_busy,    // bit 3
                                  tx_busy,    // bit 2
                                  rx_valid,   // bit 1
                                  tx_ready};  // bit 0
                    end
                    ADDR_CONTROL: begin
                        rdata <= {29'd0,
                                  1'b0,       // RX_CLR is write-only pulse
                                  rx_en,      // bit 1
                                  tx_en};     // bit 0
                    end
                    ADDR_BAUD: begin
                        rdata <= {16'd0, baud_div};
                    end
                    default: rdata <= 32'd0;
                endcase
                ready <= 1'b1;
            end
        end
    end

endmodule

