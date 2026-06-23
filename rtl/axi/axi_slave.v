module axi_slave (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  s_arid,
    input  wire [31:0] s_araddr,
    input  wire [7:0]  s_arlen,
    input  wire [2:0]  s_arsize,
    input  wire [1:0]  s_arburst,
    input  wire        s_arvalid,
    output reg         s_arready,
    output reg  [3:0]  s_rid,
    output reg  [31:0] s_rdata,
    output reg  [1:0]  s_rresp,
    output reg         s_rlast,
    output reg         s_rvalid,
    input  wire        s_rready,
    input  wire [3:0]  s_awid,
    input  wire [31:0] s_awaddr,
    input  wire [7:0]  s_awlen,
    input  wire [2:0]  s_awsize,
    input  wire [1:0]  s_awburst,
    input  wire        s_awvalid,
    output reg         s_awready,
    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wlast,
    input  wire        s_wvalid,
    output reg         s_wready,
    output reg  [3:0]  s_bid,
    output reg  [1:0]  s_bresp,
    output reg         s_bvalid,
    input  wire        s_bready,
    output reg  [31:0] mem_addr,
    output reg  [31:0] mem_wdata,
    output reg  [3:0]  mem_wstrb,
    output reg         mem_wen,
    output reg         mem_ren,
    input  wire [31:0] mem_rdata,
    input  wire        mem_rvalid
);

localparam MEM_TOP  = 32'h0000_7FFF;
localparam OKAY     = 2'b00;
localparam SLVERR   = 2'b10;

localparam RD_IDLE=3'd0,RD_FETCH=3'd1,RD_WAIT=3'd2,RD_SEND=3'd3,RD_ERR=3'd4,RD_ERR_WAIT=3'd5;
localparam WR_IDLE=2'd0,WR_DATA=2'd1,WR_RESP=2'd2;

reg [2:0] rd_state;
reg [1:0] wr_state;
reg [7:0] rd_beat,rd_len;
reg [31:0] rd_addr,wr_addr;
reg [3:0] rd_id,wr_id;
reg wr_error;

function addr_ok;
    input [31:0] a;
    addr_ok = (a <= MEM_TOP);
endfunction

// READ FSM
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        s_arready<=1; s_rvalid<=0; s_rdata<=0; s_rlast<=0;
        s_rresp<=0; s_rid<=0; mem_ren<=0;
        rd_state<=RD_IDLE; rd_beat<=0; rd_len<=0; rd_addr<=0; rd_id<=0;
    end else begin
        mem_ren<=0;
        case(rd_state)
            RD_IDLE: begin
                s_arready<=1;
                if(s_arvalid) begin
                    s_arready<=0;
                    rd_addr<=s_araddr; rd_len<=s_arlen;
                    rd_id<=s_arid; rd_beat<=0;
                    if(addr_ok(s_araddr)) rd_state<=RD_FETCH;
                    else begin
                        $display("[AXI_SLAVE] SLVERR: Read out-of-bounds 0x%08h",s_araddr);
                        rd_state<=RD_ERR;
                    end
                end
            end
            RD_FETCH: begin mem_addr<=rd_addr; mem_ren<=1; rd_state<=RD_WAIT; end
            RD_WAIT: begin
                if(mem_rvalid) begin
                    s_rdata<=mem_rdata; s_rid<=rd_id; s_rresp<=OKAY;
                    s_rlast<=(rd_beat==rd_len); s_rvalid<=1; rd_state<=RD_SEND;
                end
            end
            RD_SEND: begin
                if(s_rready) begin
                    s_rvalid<=0;
                    if(rd_beat==rd_len) begin s_rlast<=0; s_arready<=1; rd_state<=RD_IDLE; end
                    else begin
                        rd_beat<=rd_beat+1; rd_addr<=rd_addr+4;
                        rd_state<=addr_ok(rd_addr+4) ? RD_FETCH : RD_ERR;
                    end
                end
            end
            RD_ERR: begin
                s_rdata<=32'hDEAD_DEAD; s_rid<=rd_id;
                s_rresp<=SLVERR; s_rlast<=(rd_beat==rd_len);
                s_rvalid<=1; rd_state<=RD_ERR_WAIT;
            end
            RD_ERR_WAIT: begin
                if(s_rready) begin
                    s_rvalid<=0;
                    if(rd_beat==rd_len) begin s_rlast<=0; s_arready<=1; rd_state<=RD_IDLE; end
                    else begin rd_beat<=rd_beat+1; rd_addr<=rd_addr+4; rd_state<=RD_ERR; end
                end
            end
            default: rd_state<=RD_IDLE;
        endcase
    end
end

// WRITE FSM
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        s_awready<=1; s_wready<=0; s_bvalid<=0;
        s_bresp<=0; s_bid<=0; mem_wen<=0;
        wr_state<=WR_IDLE; wr_addr<=0; wr_id<=0; wr_error<=0;
    end else begin
        mem_wen<=0;
        case(wr_state)
            WR_IDLE: begin
                s_awready<=1; s_wready<=0;
                if(s_awvalid) begin
                    s_awready<=0; wr_addr<=s_awaddr; wr_id<=s_awid;
                    wr_error<=!addr_ok(s_awaddr);
                    if(!addr_ok(s_awaddr))
                        $display("[AXI_SLAVE] SLVERR: Write out-of-bounds 0x%08h",s_awaddr);
                    s_wready<=1; wr_state<=WR_DATA;
                end
            end
            WR_DATA: begin
                if(s_wvalid) begin
                    if(addr_ok(wr_addr)) begin
                        mem_addr<=wr_addr; mem_wdata<=s_wdata;
                        mem_wstrb<=s_wstrb; mem_wen<=1;
                    end else wr_error<=1;
                    wr_addr<=wr_addr+4;
                    if(s_wlast) begin
                        s_wready<=0; s_bid<=wr_id;
                        s_bresp<=wr_error ? SLVERR : OKAY;
                        s_bvalid<=1; wr_state<=WR_RESP;
                    end
                end
            end
            WR_RESP: begin
                if(s_bready) begin
                    s_bvalid<=0; s_awready<=1; wr_error<=0; wr_state<=WR_IDLE;
                end
            end
            default: wr_state<=WR_IDLE;
        endcase
    end
end
endmodule
