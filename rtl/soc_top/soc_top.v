module soc_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] cache_addr,
    input  wire [31:0] cache_wdata,
    input  wire        cache_wen,
    input  wire        cache_req,
    output wire [31:0] cache_rdata,
    output wire        cache_ack
);
wire [31:0] araddr,rdata,awaddr,wdata,mem_addr,mem_wdata,mem_rdata;
wire arvalid,arready,rvalid,rready,awvalid,awready,wvalid,wready,bvalid,bready;
wire [3:0] wstrb,mem_wstrb;
wire mem_wen,mem_ren,mem_rvalid;
axi_master u_master(.clk(clk),.rst_n(rst_n),
    .cache_addr(cache_addr),.cache_wdata(cache_wdata),
    .cache_wen(cache_wen),.cache_req(cache_req),
    .cache_rdata(cache_rdata),.cache_ack(cache_ack),
    .m_araddr(araddr),.m_arvalid(arvalid),.m_arready(arready),
    .m_rdata(rdata),.m_rvalid(rvalid),.m_rready(rready),
    .m_awaddr(awaddr),.m_awvalid(awvalid),.m_awready(awready),
    .m_wdata(wdata),.m_wstrb(wstrb),.m_wvalid(wvalid),.m_wready(wready),
    .m_bvalid(bvalid),.m_bready(bready));
axi_slave u_slave(.clk(clk),.rst_n(rst_n),
    .s_araddr(araddr),.s_arvalid(arvalid),.s_arready(arready),
    .s_rdata(rdata),.s_rvalid(rvalid),.s_rready(rready),
    .s_awaddr(awaddr),.s_awvalid(awvalid),.s_awready(awready),
    .s_wdata(wdata),.s_wstrb(wstrb),.s_wvalid(wvalid),.s_wready(wready),
    .s_bvalid(bvalid),.s_bready(bready),
    .mem_addr(mem_addr),.mem_wdata(mem_wdata),.mem_wstrb(mem_wstrb),
    .mem_wen(mem_wen),.mem_ren(mem_ren),
    .mem_rdata(mem_rdata),.mem_rvalid(mem_rvalid));
mem_model u_mem(.clk(clk),.rst_n(rst_n),
    .mem_addr(mem_addr),.mem_wdata(mem_wdata),.mem_wstrb(mem_wstrb),
    .mem_wen(mem_wen),.mem_ren(mem_ren),
    .mem_rdata(mem_rdata),.mem_rvalid(mem_rvalid));
endmodule
