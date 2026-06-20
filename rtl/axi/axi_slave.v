module axi_slave (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] s_araddr,
    input  wire        s_arvalid,
    output reg         s_arready,
    output reg  [31:0] s_rdata,
    output reg         s_rvalid,
    input  wire        s_rready,
    input  wire [31:0] s_awaddr,
    input  wire        s_awvalid,
    output reg         s_awready,
    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wvalid,
    output reg         s_wready,
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
localparam IDLE=2'd0, RWAIT=2'd1, RRESP=2'd2, WRESP=2'd3;
reg [1:0] rd_state, wr_state;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_arready<=1; s_rvalid<=0; s_rdata<=0; mem_ren<=0; rd_state<=IDLE;
    end else begin
        mem_ren<=0;
        case(rd_state)
            IDLE: begin
                s_arready<=1;
                if(s_arvalid) begin
                    s_arready<=0; mem_addr<=s_araddr; mem_ren<=1; rd_state<=RWAIT;
                end
            end
            RWAIT: if(mem_rvalid) begin s_rdata<=mem_rdata; s_rvalid<=1; rd_state<=RRESP; end
            RRESP: if(s_rready) begin s_rvalid<=0; s_arready<=1; rd_state<=IDLE; end
            default: rd_state<=IDLE;
        endcase
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_awready<=1; s_wready<=1; s_bvalid<=0; mem_wen<=0; wr_state<=IDLE;
    end else begin
        mem_wen<=0;
        case(wr_state)
            IDLE: begin
                s_awready<=1; s_wready<=1;
                if(s_awvalid && s_wvalid) begin
                    s_awready<=0; s_wready<=0;
                    mem_addr<=s_awaddr; mem_wdata<=s_wdata;
                    mem_wstrb<=s_wstrb; mem_wen<=1;
                    s_bvalid<=1; wr_state<=WRESP;
                end
            end
            WRESP: if(s_bready) begin
                s_bvalid<=0; s_awready<=1; s_wready<=1; wr_state<=IDLE;
            end
            default: wr_state<=IDLE;
        endcase
    end
end
endmodule
