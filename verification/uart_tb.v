`timescale 1ns / 1ps

module tb_uart;

    // 1. Khai báo tham s?
    parameter DATA_WIDTH = 8;
    
    // Clock 50MHz, Baud 115200 -> Prescale = 54
    reg clk = 0;
    reg rst = 0;
    reg [15:0] prescale = 16'd54; 

    // 2. Dây n?i cho User Interface (G?i vào FIFO TX)
    reg [DATA_WIDTH-1:0] tx_data_in = 0;   // Tên m?i
    reg                  tx_valid_in = 0;  // Tên m?i
    wire                 tx_ready_out;     // Tên m?i

    // 3. Dây n?i cho User Interface (Nh?n t? FIFO RX)
    wire [DATA_WIDTH-1:0] rx_data_out;     // Tên m?i
    wire                  rx_valid_out;    // Tên m?i
    reg                   rx_ready_in = 1; // Luôn s?n sàng nh?n

    // 4. Dây v?t lý UART
    wire txd;
    wire rxd;

    // --- SETUP CLOCK 50MHz ---
    always #10 clk = ~clk;

    // --- LOOPBACK: N?i m?m TX vào tai RX ---
    assign rxd = txd; 

    // --- G?I MODULE UART_FIFO RA CHI?N ---
    // (L?u ý: Tên module ph?i trùng v?i tên trong file uart_fifo.v)
    uart_fifo #(
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        
        // N?i dây phía G?i (User -> TX FIFO)
        .tx_data_in(tx_data_in),
        .tx_valid_in(tx_valid_in),
        .tx_ready_out(tx_ready_out),
        
        // N?i dây phía Nh?n (RX FIFO -> User)
        .rx_data_out(rx_data_out),
        .rx_valid_out(rx_valid_out),
        .rx_ready_in(rx_ready_in),
        
        // V?t lý
        .rxd(rxd),
        .txd(txd),
        
        // Config
        .prescale(prescale)
    );

    // --- K?CH B?N TEST: G?I NGUYÊN CHU?I "HELLO" ---
    initial begin
        // 1. Reset
        $display("--- BAT DAU SIMULATION ---");
        rst = 1;
        #100;
        rst = 0;
        #100;

        // 2. N?p ??n liên thanh vào FIFO (G?i 5 byte liên t?c)
        // FIFO giúp ní làm vi?c này c?c nhanh, không c?n ch? UART g?i xong
        
        // G?i 'H' (0x48)
        wait(tx_ready_out); @(posedge clk);
        tx_data_in = 8'h48; tx_valid_in = 1; 
        
        // G?i 'E' (0x45)
        @(posedge clk); // Vì FIFO còn ch?, c? ném ti?p vào luôn
        tx_data_in = 8'h45;
        
        // G?i 'L' (0x4C)
        @(posedge clk);
        tx_data_in = 8'h4C;
        
        // G?i 'L' (0x4C)
        @(posedge clk);
        tx_data_in = 8'h4C;
        
        // G?i 'O' (0x4F)
        @(posedge clk);
        tx_data_in = 8'h4F;
        
        // Ng?t tín hi?u n?p
        @(posedge clk);
        tx_valid_in = 0;

        $display("--- Da n?p xong 5 ky tu vao FIFO trong tich tac! ---");

        // 3. Bây gi? ng?i xem UART nó t? làm vi?c (Sóng s? ch?y r?t dài)
        // Ní m? Wave lên s? th?y txd nh?y múa liên t?c
        
        #500000; // ??i ?? lâu cho 5 ký t? ?i qua (Kho?ng 500us)
        
        $display("--- KET THUC ---");
        $stop;
    end

endmodule