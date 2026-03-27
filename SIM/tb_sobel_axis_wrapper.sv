`timescale 1ns / 1ps
import video_pkg::*;

module tb_sobel_axis_wrapper();

    logic clk = 0;
    logic rst_n = 0;
    always #5 clk = ~clk; // 100MHz clock

    localparam int TDATA_W = 16;
    localparam int H_ACTIVE = 10; // Tiny 10x10 frame for fast simulation
    localparam int V_ACTIVE = 10;
    
    logic [7:0]         THRESHOLD = 8'd50;
    

    logic [TDATA_W-1:0] s_axis_tdata = '0;
    logic               s_axis_tvalid = 0;
    logic               s_axis_tready;
    logic               s_axis_tuser = 0;
    logic               s_axis_tlast = 0;


    logic [TDATA_W-1:0] m_axis_tdata;
    logic               m_axis_tvalid;
    logic               m_axis_tready = 1; // Start ready
    logic               m_axis_tuser;
    logic               m_axis_tlast;

    // 3. Instantiate the DUT
    sobel_axis_wrapper #(
        .TDATA_W(TDATA_W),
        .H_ACTIVE(H_ACTIVE),
        .V_ACTIVE(V_ACTIVE)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .THRESHOLD(THRESHOLD),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tuser(s_axis_tuser),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tuser(m_axis_tuser),
        .m_axis_tlast(m_axis_tlast)
    );

    initial begin
        #100;
        
        // Randomly throttle the TREADY signal to test the pipeline stall logic
        forever begin
            @(posedge clk);
            // 30% chance the VDMA says "Wait, I'm busy!"
            if ($urandom_range(0, 100) < 30) begin
                m_axis_tready <= 1'b0; 
            end else begin
                m_axis_tready <= 1'b1;
            end
        end
    end

    initial begin
        // Reset sequence
        rst_n = 0;
        #50;
        rst_n = 1;
        #50;
        
        $display("--- Starting 10x10 Frame Transmission ---");
        
        for (int y = 0; y < V_ACTIVE; y++) begin

            for (int x = 0; x < H_ACTIVE; x++) begin
                
                while (!s_axis_tready) @(posedge clk);
                
                s_axis_tvalid <= 1'b1;
                s_axis_tdata  <= (y * H_ACTIVE) + x; 
                s_axis_tuser  <= (x == 0 && y == 0) ? 1'b1 : 1'b0; // SOF on very first pixel
                s_axis_tlast  <= (x == H_ACTIVE - 1) ? 1'b1 : 1'b0; // EOL on last pixel of row
                
                @(posedge clk); 
                s_axis_tvalid <= 1'b0; 
                s_axis_tuser  <= 1'b0;
                s_axis_tlast  <= 1'b0;
            end
            
            #100; 
        end
        
        $display("--- Frame Transmission Complete ---");
        #1000;
        $finish;
    end

endmodule