`timescale 1ns/1ps
module tb_axi;
reg clk,rst_n;
reg [31:0] cache_addr,cache_wdata;
reg cache_wen,cache_req;
wire [31:0] cache_rdata;
wire cache_ack;
soc_top u_soc(.clk(clk),.rst_n(rst_n),
    .cache_addr(cache_addr),.cache_wdata(cache_wdata),
    .cache_wen(cache_wen),.cache_req(cache_req),
    .cache_rdata(cache_rdata),.cache_ack(cache_ack));
initial clk=0;
always #5 clk=~clk;
initial begin #5000; $display("TIMEOUT"); $finish; end
initial begin
    $dumpfile("sim/tb_axi.vcd");
    $dumpvars(0,tb_axi);
    rst_n=0; cache_req=0; cache_wen=0; cache_addr=0; cache_wdata=0;
    repeat(5) @(posedge clk); rst_n=1; repeat(2) @(posedge clk);
    $display("TEST 1: Write 0xDEADBEEF to addr 0x10");
    cache_addr=32'h10; cache_wdata=32'hDEADBEEF; cache_wen=1; cache_req=1;
    @(posedge cache_ack); @(posedge clk); cache_req=0;
    $display("WRITE DONE"); repeat(3) @(posedge clk);
    $display("TEST 2: Read from addr 0x10");
    cache_addr=32'h10; cache_wen=0; cache_req=1;
    @(posedge cache_ack); @(posedge clk); cache_req=0;
    if(cache_rdata==32'hDEADBEEF) $display("PASS: Got 0x%h",cache_rdata);
    else $display("FAIL: Got 0x%h",cache_rdata);
    repeat(5) @(posedge clk);
    $display("ALL TESTS DONE"); $finish;
end
endmodule
