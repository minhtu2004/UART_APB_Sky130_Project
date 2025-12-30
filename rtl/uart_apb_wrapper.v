module uart_apb_wrapper (
    // 1. Giao diện APB (Nối với CPU)
    input  wire        PCLK,    // Xung nhịp hệ thống
    input  wire        PRESETn, // Reset (Tích cực mức THẤP - 0 là Reset)
    input  wire        PSEL,    // CPU chọn module này
    input  wire        PENABLE, // Tín hiệu cho phép
    input  wire        PWRITE,  // 1 = Ghi, 0 = Đọc
    input  wire [31:0] PADDR,   // Địa chỉ
    input  wire [31:0] PWDATA,  // Dữ liệu CPU gửi xuống
    output wire [31:0] PRDATA,  // Dữ liệu gửi lên CPU
    output wire        PREADY,  // Ready
    output wire        PSLVERR, // Error

    // 2. Giao diện UART (Nối ra chân chip)
    input  wire        uart_rx, // Chân nhận
    output wire        uart_tx  // Chân truyền
);

    // --- Khai báo dây nối với module uart_fifo bên trong ---
    wire [7:0] tx_data_in;
    wire       tx_valid;
    wire       tx_ready; 

    wire [7:0] rx_data_out;
    wire       rx_valid;
    wire       rx_ready;
    
    // Tạo tín hiệu Reset tích cực cao (Vì module con xài rst mức 1)
    wire sys_rst;
    assign sys_rst = ~PRESETn;

    // --- 3. LOGIC APB (MEMORY MAP) ---
    // GHI (CPU -> TX FIFO)
    assign tx_valid   = PSEL && PENABLE && PWRITE && (PADDR[3:0] == 4'h0);
    assign tx_data_in = PWDATA[7:0];

    // ĐỌC (RX FIFO -> CPU)
    assign rx_ready   = PSEL && PENABLE && !PWRITE && (PADDR[3:0] == 4'h0);

    // Dữ liệu trả về cho CPU (PRDATA)
    reg [31:0] r_prdata;
    always @(*) begin
        if (PADDR[3:0] == 4'h0) begin
            r_prdata = {24'b0, rx_data_out}; // Đọc data
        end else if (PADDR[3:0] == 4'h4) begin
            // Bit 0: TX Ready, Bit 1: RX Valid
            r_prdata = {30'b0, rx_valid, tx_ready}; 
        end else begin
            r_prdata = 32'b0;
        end
    end
    assign PRDATA = r_prdata;

    // Các tín hiệu APB khác
    assign PREADY  = 1'b1; 
    assign PSLVERR = 1'b0;

    // --- 4. NHÚNG MODULE UART_FIFO (Đã sửa tên chân cho đúng) ---
    uart_fifo uart_inst (
        .clk          (PCLK),
        .rst          (sys_rst), // Nối reset (đã đảo)
        
        // Nhánh TX (Gửi đi) -> Mapping: .ten_trong_fifo (ten_ben_ngoai)
        .tx_data_in   (tx_data_in),
        .tx_valid_in  (tx_valid),
        .tx_ready_out (tx_ready),
        
        // Nhánh RX (Nhận về)
        .rx_data_out  (rx_data_out),
        .rx_valid_out (rx_valid),
        .rx_ready_in  (rx_ready),

        // Chân vật lý
        .txd          (uart_tx), // Bên trong là txd, bên ngoài là uart_tx
        .rxd          (uart_rx), // Bên trong là rxd, bên ngoài là uart_rx

        // Cấu hình tốc độ (Prescale)
        // Clock 100MHz, Baud 115200 -> 100M/115200 = 868
        .prescale     (16'd108) 
    );

endmodule
