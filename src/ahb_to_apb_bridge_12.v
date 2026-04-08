// AHB to APB Bridge with 12 APB Slave Selects
// Supports APB3, 32-bit, simple decode (4KB per slave)

module ahb_to_apb_bridge_12 #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input                   HCLK,
    input                   HRESETn,

    // AHB Slave Interface
    input                   HSEL,
    input  [ADDR_WIDTH-1:0] HADDR,
    input                   HWRITE,
    input  [1:0]            HTRANS,
    input  [2:0]            HSIZE,
    input  [DATA_WIDTH-1:0] HWDATA,
    input                   HREADY,

    output reg [DATA_WIDTH-1:0] HRDATA,
    output reg              HREADYOUT,
    output reg              HRESP,

    // APB Interface
    output                  PCLK,
    output                  PRESETn,

    output reg [11:0]       PSEL,     // 12 slaves
    output reg              PENABLE,
    output reg              PWRITE,
    output reg [ADDR_WIDTH-1:0] PADDR,
    output reg [DATA_WIDTH-1:0] PWDATA,

    input  [DATA_WIDTH-1:0] PRDATA [11:0],
    input  [11:0]           PREADY,
    input  [11:0]           PSLVERR
);

// Clock mapping
assign PCLK    = HCLK;
assign PRESETn = HRESETn;

// FSM
localparam IDLE=2'b00, SETUP=2'b01, ENABLE=2'b10;
reg [1:0] state, next_state;

// Latched signals
reg [ADDR_WIDTH-1:0] addr_reg;
reg                  write_reg;
reg [DATA_WIDTH-1:0] wdata_reg;
reg                  valid;

// Slave select index
reg [3:0] slave_idx;

// Transfer valid
always @(*) begin
    valid = HSEL && HTRANS[1] && HREADY;
end

// Latch AHB phase
always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
        addr_reg  <= 0;
        write_reg <= 0;
        wdata_reg <= 0;
    end else if (valid) begin
        addr_reg  <= HADDR;
        write_reg <= HWRITE;
        wdata_reg <= HWDATA;
    end
end

// Decode slave (4KB each)
always @(*) begin
    slave_idx = addr_reg[15:12]; // 4KB blocks
end

// FSM
always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    next_state = state;
    case(state)
        IDLE: if(valid) next_state = SETUP;
        SETUP: next_state = ENABLE;
        ENABLE: if(PREADY[slave_idx]) next_state = IDLE;
    endcase
end

// APB control
integer i;
always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
        PSEL    <= 12'b0;
        PENABLE <= 0;
        PWRITE  <= 0;
        PADDR   <= 0;
        PWDATA  <= 0;
    end else begin
        case(next_state)
            IDLE: begin
                PSEL    <= 12'b0;
                PENABLE <= 0;
            end
            SETUP: begin
                PSEL    <= 12'b0;
                PSEL[slave_idx] <= 1'b1;
                PENABLE <= 0;
                PWRITE  <= write_reg;
                PADDR   <= addr_reg;
                PWDATA  <= wdata_reg;
            end
            ENABLE: begin
                PSEL[slave_idx] <= 1'b1;
                PENABLE <= 1;
            end
        endcase
    end
end

// Response handling
always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
        HREADYOUT <= 1;
        HRESP     <= 0;
        HRDATA    <= 0;
    end else begin
        case(state)
            IDLE: HREADYOUT <= 1;
            SETUP: HREADYOUT <= 0;
            ENABLE: begin
                HREADYOUT <= PREADY[slave_idx];
                if(PREADY[slave_idx]) begin
                    HRDATA <= PRDATA[slave_idx];
                    HRESP  <= PSLVERR[slave_idx];
                end
            end
        endcase
    end
end

endmodule
