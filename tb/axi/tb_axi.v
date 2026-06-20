`timescale 1ns/1ps
module tb_axi;
reg clk, rst_n;
reg [31:0] cache_addr, cache_wdata;
reg cache_wen, cache_req;
wire [31:0] cache_rdata;
wire cache_ack;

soc_top u_soc(.clk(clk),.rst_n(rst_n),
    .cache_addr(cache_addr),.cache_wdata(cache_wdata),
    .cache_wen(cache_wen),.cache_req(cache_req),
    .cache_rdata(cache_rdata),.cache_ack(cache_ack));

initial clk=0;
always #5 clk=~clk;
initial begin #10000; $display("TIMEOUT"); $finish; end

integer pass_count, fail_count;

task do_write;
    input [31:0] addr, data;
    begin
        cache_addr=addr; cache_wdata=data; cache_wen=1; cache_req=1;
        @(posedge cache_ack); @(posedge clk); cache_req=0;
        repeat(2) @(posedge clk);
    end
endtask

task do_read;
    input [31:0] addr, expected;
    begin
        cache_addr=addr; cache_wen=0; cache_req=1;
        @(posedge cache_ack); @(posedge clk); cache_req=0;
        if(cache_rdata==expected) begin
            $display("PASS: addr=0x%h expected=0x%h got=0x%h", addr, expected, cache_rdata);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: addr=0x%h expected=0x%h got=0x%h", addr, expected, cache_rdata);
            fail_count = fail_count + 1;
        end
        repeat(2) @(posedge clk);
    end
endtask

initial begin
    $dumpfile("sim/tb_axi.vcd");
    $dumpvars(0,tb_axi);
    pass_count=0; fail_count=0;
    rst_n=0; cache_req=0; cache_wen=0; cache_addr=0; cache_wdata=0;
    repeat(5) @(posedge clk); rst_n=1; repeat(2) @(posedge clk);

    $display("========== AXI MEMORY TEST SUITE ==========");

    // Test 1
    $display("--- Test 1: Basic write/read ---");
    do_write(32'h10, 32'hDEADBEEF);
    do_read (32'h10, 32'hDEADBEEF);

    // Test 2
    $display("--- Test 2: Different address ---");
    do_write(32'h20, 32'h12345678);
    do_read (32'h20, 32'h12345678);

    // Test 3
    $display("--- Test 3: Multiple addresses ---");
    do_write(32'h100, 32'hAAAAAAAA);
    do_write(32'h104, 32'hBBBBBBBB);
    do_write(32'h108, 32'hCCCCCCCC);
    do_read (32'h100, 32'hAAAAAAAA);
    do_read (32'h104, 32'hBBBBBBBB);
    do_read (32'h108, 32'hCCCCCCCC);

    // Test 4
    $display("--- Test 4: Overwrite same address ---");
    do_write(32'h10, 32'h11111111);
    do_read (32'h10, 32'h11111111);

    // Test 5
    $display("--- Test 5: Zero data ---");
    do_write(32'h200, 32'h00000000);
    do_read (32'h200, 32'h00000000);

    // Test 6
    $display("--- Test 6: Max value ---");
    do_write(32'h204, 32'hFFFFFFFF);
    do_read (32'h204, 32'hFFFFFFFF);

    $display("========== RESULTS ==========");
    $display("PASSED: %0d", pass_count);
    $display("FAILED: %0d", fail_count);
    if(fail_count==0) $display("ALL TESTS PASSED!");
    else $display("SOME TESTS FAILED!");
    $finish;
end
endmodule
