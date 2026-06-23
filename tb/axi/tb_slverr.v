`timescale 1ns/1ps
module tb_slverr;
reg clk,rst_n;

// Connect via core interface (soc_top now has core ports)
reg  [31:0] core_pc;
reg         core_if_req;
wire [31:0] core_insn;
wire        core_if_ack;
wire        core_if_stall;
reg  [31:0] core_mem_addr;
reg  [31:0] core_mem_wdata;
reg         core_mem_wen;
reg  [3:0]  core_mem_strb;
reg         core_mem_req;
wire [31:0] core_mem_rdata;
wire        core_mem_ack;
wire        core_mem_stall;

soc_top u_soc(
    .clk(clk),.rst_n(rst_n),
    .core_pc(core_pc),.core_if_req(core_if_req),
    .core_insn(core_insn),.core_if_ack(core_if_ack),.core_if_stall(core_if_stall),
    .core_mem_addr(core_mem_addr),.core_mem_wdata(core_mem_wdata),
    .core_mem_wen(core_mem_wen),.core_mem_strb(core_mem_strb),.core_mem_req(core_mem_req),
    .core_mem_rdata(core_mem_rdata),.core_mem_ack(core_mem_ack),.core_mem_stall(core_mem_stall)
);

initial clk=0;
always #5 clk=~clk;
initial begin #20000; $display("TIMEOUT"); $finish; end

initial begin
    $dumpfile("sim/tb_slverr.vcd");
    $dumpvars(0,tb_slverr);
    rst_n=0; core_if_req=0; core_pc=0;
    core_mem_req=0; core_mem_wen=0;
    core_mem_addr=0; core_mem_wdata=0; core_mem_strb=4'b1111;
    repeat(5) @(posedge clk); rst_n=1; repeat(2) @(posedge clk);

    $display("===== SLVERR ERROR HANDLING TEST =====");

    // Write to out-of-bounds address
    $display("--- Write to out-of-bounds addr 0xFFFF0000 ---");
    core_mem_addr=32'hFFFF0000; core_mem_wdata=32'h12345678;
    core_mem_wen=1; core_mem_strb=4'b1111; core_mem_req=1;
    wait(core_mem_ack==1);
    @(posedge clk); core_mem_req=0;
    $display("Write done - SLVERR returned by slave");
    repeat(3) @(posedge clk);

    // Read from out-of-bounds address
    $display("--- Read from out-of-bounds addr 0xFFFF0000 ---");
    core_mem_addr=32'hFFFF0000; core_mem_wen=0; core_mem_req=1;
    wait(core_mem_ack==1);
    @(posedge clk); core_mem_req=0;
    $display("Read done - data=0x%h", core_mem_rdata);

    repeat(3) @(posedge clk);
    $display("===== SLVERR TEST DONE =====");
    $finish;
end
endmodule
