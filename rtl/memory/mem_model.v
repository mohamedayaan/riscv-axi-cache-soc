module mem_model (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [3:0]  mem_wstrb,
    input  wire        mem_wen,
    input  wire        mem_ren,
    output reg  [31:0] mem_rdata,
    output reg         mem_rvalid
);

reg [31:0] mem [0:4095];
integer i;
integer log_file;

initial begin
    for(i=0;i<4096;i=i+1) mem[i]=32'd0;
    log_file = $fopen("sim/mem_access.log","w");
    $fwrite(log_file,"TIME(ps)         TYPE   ADDR        DATA        WSTRB\n");
    $fwrite(log_file,"------------------------------------------------------\n");
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mem_rdata  <= 0;
        mem_rvalid <= 0;
    end else begin
        mem_rvalid <= 0;
        if (mem_ren) begin
            mem_rdata  <= mem[mem_addr[13:2]];
            mem_rvalid <= 1;
            $fwrite(log_file,"%0t\t READ   0x%08h  0x%08h  ----\n",
                $time, mem_addr, mem[mem_addr[13:2]]);
        end
        if (mem_wen) begin
            if(mem_wstrb[0]) mem[mem_addr[13:2]][7:0]  <=mem_wdata[7:0];
            if(mem_wstrb[1]) mem[mem_addr[13:2]][15:8] <=mem_wdata[15:8];
            if(mem_wstrb[2]) mem[mem_addr[13:2]][23:16]<=mem_wdata[23:16];
            if(mem_wstrb[3]) mem[mem_addr[13:2]][31:24]<=mem_wdata[31:24];
            $fwrite(log_file,"%0t\t WRITE  0x%08h  0x%08h  %04b\n",
                $time, mem_addr, mem_wdata, mem_wstrb);
        end
    end
end

always @(posedge clk) begin
    $fflush(log_file);
end

endmodule
