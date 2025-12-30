`timescale 1ns / 1ps

module tb_uart_apb;

    // Tín hiệu APB
    reg         PCLK;
    reg         PRESETn;
    reg         PSEL;
    reg         PENABLE;
    reg         PWRITE;
    reg  [31:0] PADDR;
    reg  [31:0] PWDATA;
    wire [31:0] PRDATA;
    wire        PREADY;
    wire        PSLVERR;

    // Tín hiệu UART
    reg         uart_rx;
    wire        uart_tx;

    // Tham số Clock (100MHz)
    localparam CLK_PERIOD = 10; 
    // Baudrate 115200 -> Bit period ~ 8680ns
    localparam BIT_PERIOD = 8680; 

    // Gọi module cần test
    uart_apb_wrapper uut (
        .PCLK(PCLK), .PRESETn(PRESETn),
        .PSEL(PSEL), .PENABLE(PENABLE), .PWRITE(PWRITE),
        .PADDR(PADDR), .PWDATA(PWDATA), .PRDATA(PRDATA),
        .PREADY(PREADY), .PSLVERR(PSLVERR),
        .uart_rx(uart_rx), .uart_tx(uart_tx)
    );

    // Tạo Clock
    always #(CLK_PERIOD/2) PCLK = ~PCLK;

    // --- TASK: MÔ PHỎNG GHI APB (CPU Ghi lệnh) ---
    task apb_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge PCLK);
            PADDR   <= addr;
            PWDATA  <= data;
            PWRITE  <= 1;
            PSEL    <= 1;
            PENABLE <= 0; // Setup Phase
            @(posedge PCLK);
            PENABLE <= 1; // Access Phase
            @(posedge PCLK);
            // Chờ slave xong (dù bài này luôn xong ngay)
            while (!PREADY) @(posedge PCLK);
            PSEL    <= 0;
            PENABLE <= 0;
        end
    endtask

    // --- TASK: MÔ PHỎNG ĐỌC APB (CPU Đọc dữ liệu) ---
    task apb_read(input [31:0] addr);
        begin
            @(posedge PCLK);
            PADDR   <= addr;
            PWRITE  <= 0;
            PSEL    <= 1;
            PENABLE <= 0;
            @(posedge PCLK);
            PENABLE <= 1;
            @(posedge PCLK);
            while (!PREADY) @(posedge PCLK);
            $display("CPU Read Addr: 0x%h | Data: 0x%h", addr, PRDATA);
            PSEL    <= 0;
            PENABLE <= 0;
        end
    endtask

    // --- TASK: GỬI DỮ LIỆU VÀO CHÂN RX (Giả lập thiết bị ngoài gửi tới) ---
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            // Start bit (0)
            uart_rx = 0;
            #(BIT_PERIOD);
            // 8 Data bits
            for (i=0; i<8; i=i+1) begin
                uart_rx = data[i];
                #(BIT_PERIOD);
            end
            // Stop bit (1)
            uart_rx = 1;
            #(BIT_PERIOD);
        end
    endtask

    // --- KỊCH BẢN CHẠY ---
    initial begin
        // 1. Khởi tạo
        PCLK = 0; PRESETn = 0;
        PSEL = 0; PENABLE = 0; PWRITE = 0;
        uart_rx = 1; // Idle state của UART là 1
        
        // 2. Reset chip
        #100 PRESETn = 1;
        #100;

        // 3. TEST 1: CPU Gửi data đi (TX)
        $display("\n--- TEST 1: CPU Gửi ký tự 'A' (0x41) ---");
        apb_write(32'h00, 32'h41); 
        // Sau lệnh này, chân uart_tx sẽ bắt đầu nhấp nháy (xem Waveform)

        // 4. TEST 2: Nhận data từ ngoài vào (RX)
        #50000; // Chờ TX gửi xong chút đã
        $display("\n--- TEST 2: Thiết bị ngoài gửi ký tự 'B' (0x42) ---");
        uart_send_byte(8'h42);

        // 5. TEST 3: CPU Kiểm tra trạng thái (Status)
        #50000;
        $display("\n--- TEST 3: CPU Đọc trạng thái (Addr 0x04) ---");
        // Mong đợi: Bit 1 = 1 (RX Valid - Có hàng)
        apb_read(32'h04); 

        // 6. TEST 4: CPU Đọc dữ liệu ra (Addr 0x00)
        $display("\n--- TEST 4: CPU Đọc dữ liệu (Addr 0x00) ---");
        // Mong đợi: Data = 0x42 ('B')
        apb_read(32'h00);

        #2000 $finish;
    end

    // Xuất file sóng để xem
    initial begin
        $dumpfile("wave_apb.vcd");
        $dumpvars(0, tb_uart_apb);
    end

endmodule
