module instruction_memory (
    input  wire [31:0] addr,
    output reg  [31:0] rdata     
);
    reg [31:0] mem [0:255];

    initial begin
        $readmemh("program.hex", mem);
    end
    always @(*) begin
        rdata = mem[addr[31:2]];   
    end

endmodule
