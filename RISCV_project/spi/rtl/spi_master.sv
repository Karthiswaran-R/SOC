module spi_master (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [7:0]  addr,
    input  logic [31:0] wdata,
    input  logic        write_en,
    input  logic        read_en,

    output logic [31:0] rdata,
    output logic        ready,

    output logic        sclk,
    output logic        mosi,
    input  logic        miso,
    output logic        cs_n
);

    logic [7:0] tx_reg, rx_reg;
    logic start, busy;

    typedef enum logic [1:0] {IDLE, TRANSFER, DONE} state_t;
    state_t state;

    logic [2:0] bit_cnt;
    logic sclk_en;

    assign ready = 1'b1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_reg <= 0;
            start  <= 0;
        end else begin
            start <= 0;

            if (write_en) begin
                case (addr)
                    8'h00: tx_reg <= wdata[7:0];
                    8'h0C: start  <= wdata[0];
                endcase
            end
        end
    end

    always_comb begin
        case (addr)
            8'h04: rdata = {24'd0, rx_reg};
            8'h08: rdata = {31'd0, busy};
            default: rdata = 0;
        endcase
    end

    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sclk <= 0;
        else if (sclk_en)
            sclk <= ~sclk;
        else
            sclk <= 0;
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            cs_n    <= 1;
            busy    <= 0;
            bit_cnt <= 7;
            rx_reg  <= 0;
            sclk_en <= 0;
            mosi    <= 0;
        end else begin
            case (state)

                IDLE: begin
                    cs_n <= 1;
                    busy <= 0;
                    sclk_en <= 0;

                    if (start) begin
                        state <= TRANSFER;
                        cs_n <= 0;
                        busy <= 1;
                        bit_cnt <= 7;
                        sclk_en <= 1;
                    end
                end

                TRANSFER: begin
                    if (sclk == 0)
                        mosi <= tx_reg[bit_cnt];

                    if (sclk == 1) begin
                        rx_reg[bit_cnt] <= miso;

                        if (bit_cnt == 0)
                            state <= DONE;
                        else
                            bit_cnt <= bit_cnt - 1;
                    end
                end

                DONE: begin
                    cs_n <= 1;
                    busy <= 0;
                    sclk_en <= 0;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
