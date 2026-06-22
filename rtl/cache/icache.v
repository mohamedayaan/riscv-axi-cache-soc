module icache (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [31:0] core_addr,
    input  wire        core_req,
    output reg         core_ack,
    output reg  [31:0] core_rdata,
    output reg         core_stall,

    output reg  [31:0] i_addr,
    output reg         i_req,
    input  wire        i_grant,
    output reg  [31:0] i_wdata,
    output reg         i_wen,
    output reg  [7:0]  i_burst_len,
    output reg  [3:0]  i_wstrb,
    input  wire [31:0] i_rdata,
    input  wire        i_ack,
    input  wire        i_last
);

    localparam IDLE   = 3'b000;
    localparam MISS   = 3'b001;
    localparam REFILL = 3'b010;
    localparam DONE   = 3'b011;

    reg [2:0] state;

    reg [20:0] tag_array   [0:63];
    reg [31:0] data_array  [0:63][0:7];
    reg        valid_array [0:63];

    reg [5:0]  r_idx;
    reg [20:0] r_tag;

    wire        c_valid = valid_array[r_idx];
    wire [20:0] c_tag   = tag_array  [r_idx];
    wire [31:0] c_word  = data_array [r_idx][core_addr[4:2]];

    wire hit = c_valid && (c_tag == r_tag);

    // Miss tracking
    reg [5:0]  miss_idx;
    reg [20:0] miss_tag;
    reg [2:0]  miss_woff;
    reg [3:0]  beat_cnt;
    reg [31:0] line_buffer [0:7];

    integer i, j;

    // Pre-register idx and tag every IDLE cycle
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_idx <= 6'h0;
            r_tag <= 21'h0;
        end else if (state == IDLE) begin
            r_idx <= core_addr[10:5];
            r_tag <= core_addr[31:11];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            core_ack    <= 1'b0;
            core_rdata  <= 32'h0;
            core_stall  <= 1'b0;
            i_req       <= 1'b0;
            i_addr      <= 32'h0;
            i_wdata     <= 32'h0;
            i_wen       <= 1'b0;
            i_burst_len <= 8'h0;
            i_wstrb     <= 4'h0;
            beat_cnt    <= 4'd0;
            miss_idx    <= 6'h0;
            miss_tag    <= 21'h0;
            miss_woff   <= 3'h0;
            for (i = 0; i < 64; i = i + 1) begin
                valid_array[i] <= 1'b0;
                tag_array[i]   <= 21'h0;
                for (j = 0; j < 8; j = j + 1)
                    data_array[i][j] <= 32'h0;
            end
            for (i = 0; i < 8; i = i + 1)
                line_buffer[i] <= 32'h0;

        end else begin
            core_ack <= 1'b0;

            case (state)
                IDLE: begin
                    core_stall <= 1'b0;

                    if (core_req) begin
                        if (hit) begin
                            core_rdata <= c_word;
                            core_ack   <= 1'b1;
                        end else begin
                            miss_idx     <= core_addr[10:5];
                            miss_tag     <= core_addr[31:11];
                            miss_woff    <= core_addr[4:2];
                            i_addr       <= {core_addr[31:5], 5'b0};
                            i_req        <= 1'b1;
                            i_wen        <= 1'b0;
                            i_burst_len  <= 8'd7;
                            i_wstrb      <= 4'b1111;
                            core_stall   <= 1'b1;
                            state        <= MISS;
                        end
                    end
                end

                MISS: begin
                    if (i_grant) begin
                        i_req    <= 1'b0;
                        beat_cnt <= 4'd0;
                        state    <= REFILL;
                    end
                end

                REFILL: begin
                    if (i_ack) begin
                        line_buffer[beat_cnt] <= i_rdata;
                        beat_cnt              <= beat_cnt + 1'b1;
                        if (i_last)
                            state <= DONE;
                    end
                end

                DONE: begin
                    tag_array  [miss_idx]    <= miss_tag;
                    valid_array[miss_idx]    <= 1'b1;
                    data_array [miss_idx][0] <= line_buffer[0];
                    data_array [miss_idx][1] <= line_buffer[1];
                    data_array [miss_idx][2] <= line_buffer[2];
                    data_array [miss_idx][3] <= line_buffer[3];
                    data_array [miss_idx][4] <= line_buffer[4];
                    data_array [miss_idx][5] <= line_buffer[5];
                    data_array [miss_idx][6] <= line_buffer[6];
                    data_array [miss_idx][7] <= line_buffer[7];
                    core_rdata  <= line_buffer[miss_woff];
                    core_ack    <= 1'b1;
                    core_stall  <= 1'b0;
                    state       <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule