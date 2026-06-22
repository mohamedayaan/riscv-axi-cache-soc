module cache_arbiter (
    input  wire        clk,
    input  wire        rst_n,
    
    // I-cache port
    input  wire [31:0] i_addr,
    input  wire        i_req,
    output wire        i_grant,
    input  wire [31:0] i_wdata,
    input  wire        i_wen,
    input  wire [7:0]  i_burst_len,
    input  wire [3:0]  i_wstrb,
    output wire [31:0] i_rdata,
    output wire        i_ack,
    output wire        i_last,
    
    // D-cache port
    input  wire [31:0] d_addr,
    input  wire        d_req,
    output wire        d_grant,
    input  wire [31:0] d_wdata,
    input  wire        d_wen,
    input  wire [7:0]  d_burst_len,
    input  wire [3:0]  d_wstrb,
    output wire [31:0] d_rdata,
    output wire        d_ack,
    output wire        d_last,
    
    // To Ayaan's axi_master
    output reg  [31:0] cache_addr,
    output reg  [31:0] cache_wdata,
    output reg         cache_wen,
    output reg         cache_req,
    output reg  [7:0]  cache_burst_len,
    output reg  [3:0]  cache_wstrb,
    input  wire [31:0] cache_rdata,
    input  wire        cache_ack,
    input  wire        cache_last
);

    localparam IDLE = 2'b00;
    localparam I_BUSY = 2'b01;
    localparam D_BUSY = 2'b10;
    
    reg [1:0] state;
    reg       last_grant_i;
    
    reg [31:0] lat_addr;
    reg [31:0] lat_wdata;
    reg        lat_wen;
    reg [7:0]  lat_burst_len;
    reg [3:0]  lat_wstrb;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            last_grant_i <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (i_req && !d_req) begin
                        state <= I_BUSY;
                        last_grant_i <= 1'b1;
                        lat_addr <= i_addr;
                        lat_wdata <= i_wdata;
                        lat_wen <= i_wen;
                        lat_burst_len <= i_burst_len;
                        lat_wstrb <= i_wstrb;
                    end else if (!i_req && d_req) begin
                        state <= D_BUSY;
                        last_grant_i <= 1'b0;
                        lat_addr <= d_addr;
                        lat_wdata <= d_wdata;
                        lat_wen <= d_wen;
                        lat_burst_len <= d_burst_len;
                        lat_wstrb <= d_wstrb;
                    end else if (i_req && d_req) begin
                        if (!last_grant_i) begin
                            state <= I_BUSY;
                            last_grant_i <= 1'b1;
                            lat_addr <= i_addr;
                            lat_wdata <= i_wdata;
                            lat_wen <= i_wen;
                            lat_burst_len <= i_burst_len;
                            lat_wstrb <= i_wstrb;
                        end else begin
                            state <= D_BUSY;
                            last_grant_i <= 1'b0;
                            lat_addr <= d_addr;
                            lat_wdata <= d_wdata;
                            lat_wen <= d_wen;
                            lat_burst_len <= d_burst_len;
                            lat_wstrb <= d_wstrb;
                        end
                    end
                end
                
                I_BUSY: begin
                    if (cache_ack && (cache_last || lat_burst_len == 8'h0))
                        state <= IDLE;
                end
                
                D_BUSY: begin
                    if (cache_ack && (cache_last || lat_burst_len == 8'h0))
                        state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
  
    always @(*) begin
        if ((state == I_BUSY || state == D_BUSY) &&
            !(cache_ack && (cache_last || lat_burst_len == 8'h0))) begin
            // Drive cache_req throughout the busy state, EXCEPT on the
            // terminal beat. Terminal beat = cache_ack && (cache_last
            // for bursts, OR lat_burst_len==0 for single-beat writes,
            // which never assert cache_last at all).
            cache_addr = lat_addr; cache_wdata = lat_wdata; cache_wen = lat_wen;
            cache_req = 1'b1; cache_burst_len = lat_burst_len; cache_wstrb = lat_wstrb;
        end else begin
            // state == IDLE, OR the terminal beat of a busy state: hold
            // cache_req low so the mock/responder sees a clean deassert
            // exactly on the cycle the burst finishes.
            cache_addr = 32'h0; cache_wdata = 32'h0; cache_wen = 1'b0;
            cache_req = 1'b0; cache_burst_len = 8'h0; cache_wstrb = 4'h0;
        end
    end
    
    assign i_grant = (state == I_BUSY);
    assign d_grant = (state == D_BUSY);
    
    assign i_rdata = (state == I_BUSY) ? cache_rdata : 32'h0;
    assign i_ack   = (state == I_BUSY) ? cache_ack   : 1'b0;
    assign i_last  = (state == I_BUSY) ? cache_last  : 1'b0;
    
    assign d_rdata = (state == D_BUSY) ? cache_rdata : 32'h0;
    assign d_ack   = (state == D_BUSY) ? cache_ack   : 1'b0;
    assign d_last  = (state == D_BUSY) ? cache_last  : 1'b0;

endmodule