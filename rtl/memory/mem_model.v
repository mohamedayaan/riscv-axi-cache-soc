module mem_model (
    input  wire        clk,
    input  wire        rst_n,

    // AR channel (Read Address)
    input  wire [31:0] s_araddr,
    input  wire        s_arvalid,
    output reg         s_arready,

    // R channel (Read Data)
    output reg  [31:0] s_rdata,
    output reg  [1:0]  s_rresp,
    output reg         s_rvalid,
    input  wire        s_rready,

    // AW channel (Write Address)
    input  wire [31:0] s_awaddr,
    input  wire        s_awvalid,
    output reg         s_awready,

    // W channel (Write Data)
    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wvalid,
    output reg         s_wready,

    // B channel (Write Response)
    output reg  [1:0]  s_bresp,
    output reg         s_bvalid,
    input  wire        s_bready
);

// Memory array: 16KB = 4096 locations of 32 bits each
reg [31:0] mem [0:4095];

// Internal address registers
reg [31:0] read_addr;
reg [31:0] write_addr;

// FSM States
localparam IDLE    = 2'd0;
localparam R_DATA  = 2'd1;
localparam W_DATA  = 2'd2;
localparam B_RESP  = 2'd3;

reg [1:0] rd_state;
reg [1:0] wr_state;

// Initialize memory to zero
integer i;
initial begin
    for (i = 0; i < 4096; i = i + 1)
        mem[i] = 32'd0;
end

// READ state machine
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_arready <= 0;
        s_rvalid  <= 0;
        s_rdata   <= 0;
        s_rresp   <= 2'b00;
        rd_state  <= IDLE;
    end else begin
        case (rd_state)
            IDLE: begin
                s_arready <= 1;  // always ready to accept address
                if (s_arvalid) begin
                    read_addr <= s_araddr;
                    s_arready <= 0;
                    rd_state  <= R_DATA;
                end
            end

            R_DATA: begin
                s_rdata  <= mem[read_addr[13:2]]; // word-aligned address
                s_rresp  <= 2'b00;  // OKAY
                s_rvalid <= 1;
                if (s_rready) begin
                    s_rvalid <= 0;
                    rd_state <= IDLE;
                end
            end

            default: rd_state <= IDLE;
        endcase
    end
end

// WRITE state machine
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_awready <= 0;
        s_wready  <= 0;
        s_bvalid  <= 0;
        s_bresp   <= 2'b00;
        wr_state  <= IDLE;
    end else begin
        case (wr_state)
            IDLE: begin
                s_awready <= 1;  // always ready to accept address
                if (s_awvalid) begin
                    write_addr <= s_awaddr;
                    s_awready  <= 0;
                    s_wready   <= 1;
                    wr_state   <= W_DATA;
                end
            end

            W_DATA: begin
                if (s_wvalid) begin
                    // Write only enabled bytes using wstrb
                    if (s_wstrb[0]) mem[write_addr[13:2]][7:0]   <= s_wdata[7:0];
                    if (s_wstrb[1]) mem[write_addr[13:2]][15:8]  <= s_wdata[15:8];
                    if (s_wstrb[2]) mem[write_addr[13:2]][23:16] <= s_wdata[23:16];
                    if (s_wstrb[3]) mem[write_addr[13:2]][31:24] <= s_wdata[31:24];
                    s_wready <= 0;
                    s_bvalid <= 1;
                    s_bresp  <= 2'b00;  // OKAY
                    wr_state <= B_RESP;
                end
            end

            B_RESP: begin
                if (s_bready) begin
                    s_bvalid <= 0;
                    wr_state <= IDLE;
                end
            end

            default: wr_state <= IDLE;
        endcase
    end
end

endmodule
