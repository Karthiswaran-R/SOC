module watchdog_timer (
    input         clk,
    input         rst_n,

    input  [7:0]  addr,
    input  [31:0] wdata,
    output reg [31:0] rdata,

    input         write_en,
    input         read_en,
    output        ready,

    output reg    wdt_reset_req
);

    reg [31:0] wdt_load;
    reg [31:0] wdt_count;
    reg        wdt_enable;
    reg        timeout_flag;

    // Address decoding
    parameter ADDR_LOAD   = 8'h00;
    parameter ADDR_COUNT  = 8'h04;
    parameter ADDR_CTRL   = 8'h08;
    parameter ADDR_STATUS = 8'h0C;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wdt_load     <= 32'd0;
            wdt_enable   <= 1'b0;
            timeout_flag <= 1'b0;
            wdt_count    <= 32'd0;
        end
        else if (write_en) begin
            case (addr)

                ADDR_LOAD: begin
                    wdt_load <= wdata;
                end

                ADDR_CTRL: begin
                    // Enable bit
                   wdt_enable <= wdata[0];
                                       // kick
                    if (wdata == 32'hA) begin
                        wdt_count    <= wdt_load;
                        timeout_flag <= 1'b0;
                       wdt_reset_req <= 1'b0;
                    end
                end

                default: ;
            endcase
        end
    end

   //counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wdt_count      <= 32'd0;
            wdt_reset_req  <= 1'b0;
        end
        else if (wdt_enable) begin
            if (wdt_count > 0) begin
                wdt_count <= wdt_count - 1;
            end
            else begin
                timeout_flag  <= 1'b1;
                wdt_reset_req <= 1'b1;
            end
        end
        else begin
            wdt_reset_req <= 1'b0;
        end
    end

//read logic
    always @(*) begin
        case (addr)
            ADDR_LOAD:   rdata = wdt_load;
            ADDR_COUNT:  rdata = wdt_count;
            ADDR_CTRL:   rdata = {31'd0, wdt_enable};
            ADDR_STATUS: rdata = {31'd0, timeout_flag};
            default:     rdata = 32'd0;
        endcase
    end

    assign ready = 1'b1;

endmodule

