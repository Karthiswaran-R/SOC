module soc_bus_interconnect (

    input  logic clk,
    input  logic reset,

    // CPU side
    input  logic [31:0] bus_addr,
    input  logic [31:0] bus_wdata,
    input  logic        bus_we,
    input  logic        bus_re,
    input  logic        bus_valid,
    output logic [31:0] bus_rdata,
    output logic        bus_ready,

    // ROM
    output logic [31:0] rom_addr,
    output logic [31:0] rom_wdata,
    output logic        rom_we,
    output logic        rom_re,
    output logic        rom_valid,
    input  logic [31:0] rom_rdata,
    input  logic        rom_ready,

    // RAM
    output logic [31:0] ram_addr,
    output logic [31:0] ram_wdata,
    output logic        ram_we,
    output logic        ram_re,
    output logic        ram_valid,
    input  logic [31:0] ram_rdata,
    input  logic        ram_ready,

    // GPIO (same pattern for all peripherals)
    output logic [31:0] gpio_addr,
    output logic [31:0] gpio_wdata,
    output logic        gpio_we,
    output logic        gpio_re,
    output logic        gpio_valid,
    input  logic [31:0] gpio_rdata,
    input  logic        gpio_ready

    // 👉 repeat for UART, TIMER, SPI, etc.
);

    // =========================
    // Address Decode
    // =========================
    logic rom_sel, ram_sel, gpio_sel;

    address_decoder u_dec (
        .addr(bus_addr),
        .rom_sel(rom_sel),
        .ram_sel(ram_sel),
        .gpio_sel(gpio_sel)
        // add others
    );

    // =========================
    // Broadcast address/data
    // =========================
    assign rom_addr   = bus_addr;
    assign ram_addr   = bus_addr;
    assign gpio_addr  = bus_addr;

    assign rom_wdata  = bus_wdata;
    assign ram_wdata  = bus_wdata;
    assign gpio_wdata = bus_wdata;

    // =========================
    // Control signals
    // =========================
    assign rom_we   = bus_we & rom_sel;
    assign ram_we   = bus_we & ram_sel;
    assign gpio_we  = bus_we & gpio_sel;

    assign rom_re   = bus_re & rom_sel;
    assign ram_re   = bus_re & ram_sel;
    assign gpio_re  = bus_re & gpio_sel;

    assign rom_valid   = bus_valid & rom_sel;
    assign ram_valid   = bus_valid & ram_sel;
    assign gpio_valid  = bus_valid & gpio_sel;

    // =========================
    // Read Data MUX (CRITICAL)
    // =========================
    always_comb begin
        bus_rdata = 32'h0;
        bus_ready = 1'b0;

        if (rom_sel) begin
            bus_rdata = rom_rdata;
            bus_ready = rom_ready;
        end
        else if (ram_sel) begin
            bus_rdata = ram_rdata;
            bus_ready = ram_ready;
        end
        else if (gpio_sel) begin
            bus_rdata = gpio_rdata;
            bus_ready = gpio_ready;
        end
        else begin
            // Unmapped access
            bus_rdata = 32'hDEAD_BEEF;
            bus_ready = 1'b1;
        end
    end

endmodule
