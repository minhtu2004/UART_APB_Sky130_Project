`timescale 1ns / 1ps

module uart_fifo #
(
    parameter DATA_WIDTH = 8
)
(
    input  wire                   clk,
    input  wire                   rst,

    // Giao dien phia USER (CPU/Logic khac)
    // 1. Muon gui di (Noi vao TX FIFO)
    input  wire [DATA_WIDTH-1:0]  tx_data_in,
    input  wire                   tx_valid_in,
    output wire                   tx_ready_out, // FIFO bao: "Tao con cho, nhet vao di"

    // 2. Muon nhan ve (Lay tu RX FIFO)
    output wire [DATA_WIDTH-1:0]  rx_data_out,
    output wire                   rx_valid_out, // FIFO bao: "Tao co hang, lay di"
    input  wire                   rx_ready_in,

    // Giao dien vat ly UART (Ra ngoai chip)
    input  wire                   rxd,
    output wire                   txd,
    
    // Cau hinh Toc do
    input  wire [15:0]            prescale
);

    // --- DAY NOI NOI BO ---
    // Giua TX FIFO va UART TX
    wire [DATA_WIDTH-1:0] fifo_tx_data;
    wire                  fifo_tx_valid;
    wire                  fifo_tx_ready;

    // Giua UART RX va RX FIFO
    wire [DATA_WIDTH-1:0] uart_rx_data;
    wire                  uart_rx_valid;
    wire                  uart_rx_ready;

    // Cac day Status bo qua (khong dung den)
    wire tx_busy, rx_busy, rx_overrun, rx_frame_err;

    // ----------------------------------------------------------------
    // 1. INSTANCE: TX FIFO (Bo dem truyen)
    // ----------------------------------------------------------------
    axis_fifo #( .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(4) ) 
    fifo_tx_inst (
        .clk(clk), .rst(rst),
        // Input tu User
        .s_axis_tdata(tx_data_in), .s_axis_tvalid(tx_valid_in), .s_axis_tready(tx_ready_out),
        // Output noi vao UART
        .m_axis_tdata(fifo_tx_data), .m_axis_tvalid(fifo_tx_valid), .m_axis_tready(fifo_tx_ready)
    );

    // ----------------------------------------------------------------
    // 2. INSTANCE: CORE UART (Cai cu)
    // ----------------------------------------------------------------
    uart #( .DATA_WIDTH(DATA_WIDTH) ) 
    uart_core_inst (
        .clk(clk), .rst(rst),
        // TX Path (Lay tu FIFO TX)
        .s_axis_tdata(fifo_tx_data), .s_axis_tvalid(fifo_tx_valid), .s_axis_tready(fifo_tx_ready),
        // RX Path (Day vao FIFO RX)
        .m_axis_tdata(uart_rx_data), .m_axis_tvalid(uart_rx_valid), .m_axis_tready(uart_rx_ready),
        // Physical
        .rxd(rxd), .txd(txd),
        // Status & Config
        .tx_busy(tx_busy), .rx_busy(rx_busy),
        .rx_overrun_error(rx_overrun), .rx_frame_error(rx_frame_err),
        .prescale(prescale)
    );

    // ----------------------------------------------------------------
    // 3. INSTANCE: RX FIFO (Bo dem nhan)
    // ----------------------------------------------------------------
    axis_fifo #( .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(4) ) 
    fifo_rx_inst (
        .clk(clk), .rst(rst),
        // Input tu UART
        .s_axis_tdata(uart_rx_data), .s_axis_tvalid(uart_rx_valid), .s_axis_tready(uart_rx_ready),
        // Output ra User
        .m_axis_tdata(rx_data_out), .m_axis_tvalid(rx_valid_out), .m_axis_tready(rx_ready_in)
    );

endmodule


