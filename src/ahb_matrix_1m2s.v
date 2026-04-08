// AHB-Lite Matrix (1 Master -> 2 Slaves)
// Slave 0: SRAM
// Slave 1: AHB-APB Bridge

module ahb_matrix_1m2s #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input                   HCLK,
    input                   HRESETn,

    // Master Interface (RISC-V)
    input  [ADDR_WIDTH-1:0] HADDR_M,
    input                   HWRITE_M,
    input  [1:0]            HTRANS_M,
    input  [2:0]            HSIZE_M,
    input  [DATA_WIDTH-1:0] HWDATA_M,
    input                   HREADY_M,

    output reg [DATA_WIDTH-1:0] HRDATA_M,
    output reg              HREADYOUT_M,
    output reg              HRESP_M,

    // Slave 0 (SRAM)
    output                  HSEL_S0,
    output [ADDR_WIDTH-1:0] HADDR_S0,
    output                  HWRITE_S0,
    output [1:0]            HTRANS_S0,
    output [2:0]            HSIZE_S0,
    output [DATA_WIDTH-1:0] HWDATA_S0,

    input  [DATA_WIDTH-1:0] HRDATA_S0,
    input                   HREADYOUT_S0,
    input                   HRESP_S0,

    // Slave 1 (AHB-APB Bridge)
    output                  HSEL_S1,
    output [ADDR_WIDTH-1:0] HADDR_S1,
    output                  HWRITE_S1,
    output [1:0]            HTRANS_S1,
    output [2:0]            HSIZE_S1,
    output [DATA_WIDTH-1:0] HWDATA_S1,

    input  [DATA_WIDTH-1:0] HRDATA_S1,
    input                   HREADYOUT_S1,
    input                   HRESP_S1
);

// Address decode
// 0x0000_0000 - 0x1FFF_FFFF : SRAM
// 0x4000_0000 - 0x4FFF_FFFF : APB bridge

assign HSEL_S0 = (HADDR_M[31:28] == 4'h0);
assign HSEL_S1 = (HADDR_M[31:28] == 4'h4);

// Forward signals
assign HADDR_S0  = HADDR_M;
assign HWRITE_S0 = HWRITE_M;
assign HTRANS_S0 = HTRANS_M;
assign HSIZE_S0  = HSIZE_M;
assign HWDATA_S0 = HWDATA_M;

assign HADDR_S1  = HADDR_M;
assign HWRITE_S1 = HWRITE_M;
assign HTRANS_S1 = HTRANS_M;
assign HSIZE_S1  = HSIZE_M;
assign HWDATA_S1 = HWDATA_M;

// Response mux
always @(*) begin
    case (1'b1)
        HSEL_S0: begin
            HRDATA_M     = HRDATA_S0;
            HREADYOUT_M  = HREADYOUT_S0;
            HRESP_M      = HRESP_S0;
        end

        HSEL_S1: begin
            HRDATA_M     = HRDATA_S1;
            HREADYOUT_M  = HREADYOUT_S1;
            HRESP_M      = HRESP_S1;
        end

        default: begin
            HRDATA_M     = 32'hDEAD_BEEF;
            HREADYOUT_M  = 1'b1;
            HRESP_M      = 1'b1; // error
        end
    endcase
end

endmodule
