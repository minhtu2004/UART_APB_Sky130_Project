/*
 * AXI4-Stream Synchronous FIFO
 */
`timescale 1ns / 1ps

module axis_fifo #
(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4  // 2^4 = 16 vi tri nho (Depth)
)
(
    input  wire                   clk,
    input  wire                   rst,

    /*
     * AXI input (Viet vao)
     */
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,

    /*
     * AXI output (Doc ra)
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready
);

    // Dinh nghia bo nho (RAM)
    reg [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0];
    
    // Con tro ghi va doc
    reg [ADDR_WIDTH:0] write_ptr_reg = 0;
    reg [ADDR_WIDTH:0] read_ptr_reg = 0;
    
    // Wire noi bo
    wire [ADDR_WIDTH:0] write_ptr_next;
    wire [ADDR_WIDTH:0] read_ptr_next;
    
    wire empty;
    wire full;

    assign write_ptr_next = write_ptr_reg + 1;
    assign read_ptr_next  = read_ptr_reg  + 1;

    // Logic Empty/Full
    // Empty khi 2 con tro bang nhau
    assign empty = (write_ptr_reg == read_ptr_reg);
    // Full khi 2 con tro lech nhau dung 1 vong (bit cao nhat khac nhau, con lai giong nhau)
    assign full  = (write_ptr_reg[ADDR_WIDTH] != read_ptr_reg[ADDR_WIDTH]) &&
                   (write_ptr_reg[ADDR_WIDTH-1:0] == read_ptr_reg[ADDR_WIDTH-1:0]);

    // Gan tin hieu AXI
    // San sang nhan (Ready) neu chua Full
    assign s_axis_tready = !full;
    
    // Co du lieu ra (Valid) neu chua Empty
    assign m_axis_tvalid = !empty;
    
    // Du lieu ra luon lay tu vi tri Read Pointer
    assign m_axis_tdata  = mem[read_ptr_reg[ADDR_WIDTH-1:0]];

    // --- PROCESS GHI VAO FIFO ---
    always @(posedge clk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            mem[write_ptr_reg[ADDR_WIDTH-1:0]] <= s_axis_tdata;
            write_ptr_reg <= write_ptr_next;
        end
        if (rst) begin
            write_ptr_reg <= 0;
        end
    end

    // --- PROCESS DOC RA KHOI FIFO ---
    always @(posedge clk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            read_ptr_reg <= read_ptr_next;
        end
        if (rst) begin
            read_ptr_reg <= 0;
        end
    end

endmodule
