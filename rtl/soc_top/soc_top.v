module soc_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] cache_addr,
    input  wire [31:0] cache_wdata,
    input  wire        cache_wen,
    input  wire        cache_req,
    input  wire [7:0]  cache_burst_len,
    output wire [31:0] cache_rdata,
    output wire        cache_ack,
    output wire        cache_last
);
wire [3:0] arid,rid,awid,bid;
wire [31:0] araddr,rdata,awaddr,wdata,mem_addr,mem_wdata,mem_rdata;
wire [7:0] arlen,awlen;
wire [2:0] arsize,awsize;
wire [1:0] arburst,awburst,rresp,bresp;
wire arvalid,arready,rvalid,rready,rlast;
wire awvalid,awready,wvalid,wready,wlast,bvalid,bready;
wire [3:0] wstrb,mem_wstrb;
wire mem_wen,mem_ren,mem_rvalid;

axi_master u_master(
    .clk(clk),.rst_n(rst_n),
    .cache_addr(cache_addr),.cache_wdata(cache_wdata),
    .cache_wen(cache_wen),.cache_req(cache_req),.cache_burst_len(cache_burst_len),
    .cache_rdata(cache_rdata),.cache_ack(cache_ack),.cache_last(cache_last),
    .m_arid(arid),.m_araddr(araddr),.m_arlen(arlen),.m_arsize(arsize),.m_arburst(arburst),
    .m_arvalid(arvalid),.m_arready(arready),
    .m_rid(rid),.m_rdata(rdata),.m_rresp(rresp),.m_rlast(rlast),.m_rvalid(rvalid),.m_rready(rready),
    .m_awid(awid),.m_awaddr(awaddr),.m_awlen(awlen),.m_awsize(awsize),.m_awburst(awburst),
    .m_awvalid(awvalid),.m_awready(awready),
    .m_wdata(wdata),.m_wstrb(wstrb),.m_wlast(wlast),.m_wvalid(wvalid),.m_wready(wready),
    .m_bid(bid),.m_bresp(bresp),.m_bvalid(bvalid),.m_bready(bready)
);
axi_slave u_slave(
    .clk(clk),.rst_n(rst_n),
    .s_arid(arid),.s_araddr(araddr),.s_arlen(arlen),.s_arsize(arsize),.s_arburst(arburst),
    .s_arvalid(arvalid),.s_arready(arready),
    .s_rid(rid),.s_rdata(rdata),.s_rresp(rresp),.s_rlast(rlast),.s_rvalid(rvalid),.s_rready(rready),
    .s_awid(awid),.s_awaddr(awaddr),.s_awlen(awlen),.s_awsize(awsize),.s_awburst(awburst),
    .s_awvalid(awvalid),.s_awready(awready),
    .s_wdata(wdata),.s_wstrb(wstrb),.s_wlast(wlast),.s_wvalid(wvalid),.s_wready(wready),
    .s_bid(bid),.s_bresp(bresp),.s_bvalid(bvalid),.s_bready(bready),
    .mem_addr(mem_addr),.mem_wdata(mem_wdata),.mem_wstrb(mem_wstrb),
    .mem_wen(mem_wen),.mem_ren(mem_ren),.mem_rdata(mem_rdata),.mem_rvalid(mem_rvalid)
);
mem_model u_mem(
    .clk(clk),.rst_n(rst_n),
    .mem_addr(mem_addr),.mem_wdata(mem_wdata),.mem_wstrb(mem_wstrb),
    .mem_wen(mem_wen),.mem_ren(mem_ren),.mem_rdata(mem_rdata),.mem_rvalid(mem_rvalid)
);
endmodule
