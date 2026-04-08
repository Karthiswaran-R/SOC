// =============================================================================
// uart_top.v — Top-level UART peripheral wrapper
//
// Instantiates: uart_regs, baud_gen, uart_tx, uart_rx
// Base address decoding is handled externally by the SoC address decoder.
// This module accepts the register offset (addr[7:0]) directly.
// =============================================================================
module uart_top (
    input  wire        clk,
    input  wire        rst_n,

    // Memory-mapped bus interface
    input  wire [7:0]  addr,       // register byte offset
    input  wire [31:0] wdata,
    output wire [31:0] rdata,
    input  wire        write_en,
    input  wire        read_en,
    output wire        ready,

    // Serial lines
    output wire        tx,
    input  wire        rx
);

    // Internal wires
    wire        baud_tick;
    wire [15:0] baud_div;

    wire [7:0]  tx_data;
    wire        tx_start;
    wire        tx_ready;
    wire        tx_busy;
    wire        tx_en;

    wire [7:0]  rx_data;
    wire        rx_valid;
    wire        rx_busy;
    wire        rx_en;
    wire        rx_clr;

    // ------------------------------------------------------------------
    // Register / Bus Interface
    // ------------------------------------------------------------------
    uart_regs u_regs (
        .clk       (clk),
        .rst_n     (rst_n),
        .addr      (addr),
        .wdata     (wdata),
        .rdata     (rdata),
        .write_en  (write_en),
        .read_en   (read_en),
        .ready     (ready),
        .tx_data   (tx_data),
        .tx_start  (tx_start),
        .tx_ready  (tx_ready),
        .tx_busy   (tx_busy),
        .rx_data   (rx_data),
        .rx_valid  (rx_valid),
        .rx_busy   (rx_busy),
        .tx_en     (tx_en),
        .rx_en     (rx_en),
        .rx_clr    (rx_clr),
        .baud_div  (baud_div)
    );

    // ------------------------------------------------------------------
    // Baud Rate Generator
    // ------------------------------------------------------------------
    baud_gen u_baud (
        .clk       (clk),
        .rst_n     (rst_n),
        .baud_div  (baud_div),
        .baud_tick (baud_tick)
    );

    // ------------------------------------------------------------------
    // UART Transmitter
    // ------------------------------------------------------------------
    uart_tx u_tx (
        .clk       (clk),
        .rst_n     (rst_n),
        .tx_en     (tx_en),
        .tx_start  (tx_start),
        .tx_data   (tx_data),
        .baud_tick (baud_tick),
        .tx        (tx),
        .tx_ready  (tx_ready),
        .tx_busy   (tx_busy)
    );

    // ------------------------------------------------------------------
    // UART Receiver
    // ------------------------------------------------------------------
    uart_rx u_rx (
        .clk       (clk),
        .rst_n     (rst_n),
        .rx_en     (rx_en),
        .rx_clr    (rx_clr),
        .rx        (rx),
        .baud_tick (baud_tick),
        .rx_data   (rx_data),
        .rx_valid  (rx_valid),
        .rx_busy   (rx_busy)
    );

    // ------------------------------------------------------------------
    // RX_VALID clear: rx_clr pulse drives rx_valid low via uart_rx.
    // Since uart_rx sets rx_valid internally, we handle the clear by
    // overriding rx_valid when rx_clr is pulsed.
    // This is wired through uart_rx's internal logic — see note below.
    // ------------------------------------------------------------------
    // NOTE: uart_rx.rx_valid is an output reg.  To allow external clear,
    // connect rx_clr as an input to uart_rx (see updated uart_rx below),
    // OR handle clear purely in uart_regs by latching rx_data and
    // masking the STATUS bit.  The recommended student approach is to pass
    // rx_clr into uart_rx — see the extended version in the README.

endmodule

