`timescale 1ns/1ps
module tb_axi;
reg clk,rst_n;
reg [31:0] cache_addr,cache_wdata;
reg cache_wen,cache_req;
reg [7:0] cache_burst_len;
reg [3:0] cache_wstrb;
wire [31:0] cache_rdata;
wire cache_ack,cache_last;

soc_top u_soc(.clk(clk),.rst_n(rst_n),
    .cache_addr(cache_addr),.cache_wdata(cache_wdata),
    .cache_wen(cache_wen),.cache_req(cache_req),
    .cache_burst_len(cache_burst_len),.cache_wstrb(cache_wstrb),
    .cache_rdata(cache_rdata),.cache_ack(cache_ack),.cache_last(cache_last));

initial clk=0;
always #5 clk=~clk;
initial begin #20000; $display("TIMEOUT"); $finish; end
integer pass_count,fail_count;

initial begin
    $dumpfile("sim/tb_axi.vcd");
    $dumpvars(0,tb_axi);
    pass_count=0; fail_count=0;
    rst_n=0; cache_req=0; cache_wen=0;
    cache_addr=0; cache_wdata=0; cache_burst_len=0; cache_wstrb=4'b1111;
    repeat(5) @(posedge clk); rst_n=1; repeat(2) @(posedge clk);

    $display("===== AXI4 TEST SUITE =====");

    // Test 1: Full word write/read
    $display("--- Test 1: Full word write/read ---");
    cache_addr=32'h10; cache_wdata=32'hDEADBEEF;
    cache_wen=1; cache_req=1; cache_burst_len=0; cache_wstrb=4'b1111;
    @(posedge cache_ack); @(posedge clk); cache_req=0;
    repeat(2) @(posedge clk);
    cache_addr=32'h10; cache_wen=0; cache_req=1; cache_burst_len=0;
    @(posedge cache_ack); @(posedge clk); cache_req=0;
    if(cache_rdata==32'hDEADBEEF) begin $display("PASS: 0x%h",cache_rdata); pass_count=pass_count+1; end
    else begin $display("FAIL: got 0x%h",cache_rdata); fail_count=fail_count+1; end
    repeat(3) @(posedge clk);

    // Test 2: Partial byte write
    $display("--- Test 2: Partial byte write (wstrb=4'b0001) ---");
    cache_addr=32'h20; cache_wdata=32'hFFFFFFFF;
    cache_wen=1; cache_req=1; cache_burst_len=0; cache_wstrb=4'b1111;
    @(posedge cache_ack); @(posedge clk); cache_req=0;
    repeat(2) @(posedge clk);
    cache_addr=32'h20; cache_wdata=32'h000000AB;
    cache_wen=1; cache_req=1; cache_wstrb=4'b0001;
    @(posedge cache_ack); @(posedge clk); cache_req=0;
    repeat(2) @(posedge clk);
    cache_addr=32'h20; cache_wen=0; cache_req=1; cache_burst_len=0;
    @(posedge cache_ack); @(posedge clk); cache_req=0;
    if(cache_rdata==32'hFFFFFFAB) begin $display("PASS: 0x%h",cache_rdata); pass_count=pass_count+1; end
    else begin $display("FAIL: expected 0xFFFFFFAB got 0x%h",cache_rdata); fail_count=fail_count+1; end
    repeat(3) @(posedge clk);

    // Test 3: Burst write 4 words
    $display("--- Test 3: Burst write 4 words ---");
    cache_addr=32'h100; cache_wdata=32'hAAAA0000; cache_wen=1; cache_req=1; cache_burst_len=0; cache_wstrb=4'b1111;
    @(posedge cache_ack); cache_req=0; repeat(2) @(posedge clk);
    cache_addr=32'h104; cache_wdata=32'hBBBB1111; cache_req=1;
    @(posedge cache_ack); cache_req=0; repeat(2) @(posedge clk);
    cache_addr=32'h108; cache_wdata=32'hCCCC2222; cache_req=1;
    @(posedge cache_ack); cache_req=0; repeat(2) @(posedge clk);
    cache_addr=32'h10C; cache_wdata=32'hDDDD3333; cache_req=1;
    @(posedge cache_ack); cache_req=0; repeat(3) @(posedge clk);

    // Test 4: Burst read 4 words
    $display("--- Test 4: Burst read 4 words ---");
    cache_addr=32'h100; cache_wen=0; cache_req=1; cache_burst_len=8'd3;
    @(posedge cache_ack);
    if(cache_rdata==32'hAAAA0000) begin $display("PASS beat0: 0x%h",cache_rdata); pass_count=pass_count+1; end
    else begin $display("FAIL beat0: 0x%h",cache_rdata); fail_count=fail_count+1; end
    @(posedge cache_ack);
    if(cache_rdata==32'hBBBB1111) begin $display("PASS beat1: 0x%h",cache_rdata); pass_count=pass_count+1; end
    else begin $display("FAIL beat1: 0x%h",cache_rdata); fail_count=fail_count+1; end
    @(posedge cache_ack);
    if(cache_rdata==32'hCCCC2222) begin $display("PASS beat2: 0x%h",cache_rdata); pass_count=pass_count+1; end
    else begin $display("FAIL beat2: 0x%h",cache_rdata); fail_count=fail_count+1; end
    @(posedge cache_last);
    if(cache_rdata==32'hDDDD3333) begin $display("PASS beat3(last): 0x%h",cache_rdata); pass_count=pass_count+1; end
    else begin $display("FAIL beat3: 0x%h",cache_rdata); fail_count=fail_count+1; end
    @(posedge clk); cache_req=0;
    repeat(5) @(posedge clk);

    $display("===== RESULTS =====");
    $display("PASSED: %0d  FAILED: %0d",pass_count,fail_count);
    if(fail_count==0) $display("ALL TESTS PASSED!");
    $finish;
end
endmodule
