module datapath (
        input  wire        clk,
        input  wire        rst,
        input  wire        branch,
        input  wire        jump,
        input  wire        reg_dst,
        input  wire        we_reg,
        input  wire        alu_src,
        input  wire        dm2reg,
        input  wire        hilo_we,
        input  wire [1:0]  hilo_mux_ctrl,
        input  wire        jal_mux_ctrl,
        input  wire        jr_mux_ctrl,
        input  wire [2:0]  alu_ctrl,
        input  wire [4:0]  ra3,
        input  wire [31:0] instr,
        input  wire [31:0] rd_dm,
        output wire [31:0] pc_current,
        output wire [31:0] alu_out,
        output wire [31:0] wd_dm,
        output wire [31:0] rd3
    );

    wire [4:0]  rf_wa;
    wire        pc_src;
    wire [31:0] pc_plus4;
    wire [31:0] pc_pre;
    wire [31:0] pc_next;
    wire [31:0] sext_imm;
    wire [31:0] ba;
    wire [31:0] bta;
    wire [31:0] jta;
    wire [31:0] alu_pa;
    wire [31:0] alu_pb;
    wire [31:0] wd_rf;
    wire        zero;
    wire [63:0] mult_out;
    wire [31:0] rf_wd_mux_out;
    wire [31:0] wd_rf_writeback;
    wire [31:0] hl_hi;
    wire [31:0] hl_lo;
    wire [4:0] rf_wa_mux_out;
    wire [31:0] pc_jmp_mux_out;
    
    assign pc_src = branch & zero;
    assign ba = {sext_imm[29:0], 2'b00};
    assign jta = {pc_plus4[31:28], instr[25:0], 2'b00};
    
    // --- PC Logic --- //
    dreg pc_reg (
            .clk            (clk),
            .rst            (rst),
            .d              (pc_next),
            .q              (pc_current)
        );

    adder pc_plus_4 (
            .a              (pc_current),
            .b              (32'd4),
            .y              (pc_plus4)
        );

    adder pc_plus_br (
            .a              (pc_plus4),
            .b              (ba),
            .y              (bta)
        );

    mux2 #(32) pc_src_mux (
            .sel            (pc_src),
            .a              (pc_plus4),
            .b              (bta),
            .y              (pc_pre)
        );

    mux2 #(32) pc_jmp_mux (
            .sel            (jump),
            .a              (pc_pre),
            .b              (jta),
            .y              (pc_jmp_mux_out)
        );
        
    mux2 #(32) pc_jr_mux (
            .sel            (jr_mux_ctrl),
            .a              (pc_jmp_mux_out),
            .b              (alu_pa),
            .y              (pc_next)
        );

    // --- RF Logic --- //
    mux2 #(5) rf_wa_mux (
            .sel            (reg_dst),
            .a              (instr[20:16]),
            .b              (instr[15:11]),
            .y              (rf_wa_mux_out)
        );
        
    mux2 #(5) jal_wa_mux (
            .sel            (jal_mux_ctrl),
            .a              (rf_wa_mux_out),
            .b              (5'd31),
            .y              (rf_wa)        
    );

    regfile rf (
            .clk            (clk),
            .we             (we_reg),
            .ra1            (instr[25:21]),
            .ra2            (instr[20:16]),
            .ra3            (ra3),
            .wa             (rf_wa),
            .wd             (wd_rf),
            .rd1            (alu_pa),
            .rd2            (wd_dm),
            .rd3            (rd3)
        );

    signext se (
            .a              (instr[15:0]),
            .y              (sext_imm)
        );

    // --- ALU Logic --- //
    mux2 #(32) alu_pb_mux (
            .sel            (alu_src),
            .a              (wd_dm),
            .b              (sext_imm),
            .y              (alu_pb)
        );

    alu alu (
            .op             (alu_ctrl),
            .shamt          (instr[10:6]),
            .a              (alu_pa),
            .b              (alu_pb),
            .zero           (zero),
            .y              (alu_out)
        );
        
    // --- MULT logic --- //
    multiplier mult(
            .a              (alu_pa),
            .b              (wd_dm),
            .out            (mult_out)
    );
    
    hl_reg mult_reg(
        .clk                (clk),
        .rst                (rst),
        .we                 (hilo_we),
        .h_in               (mult_out[63:32]),
        .l_in               (mult_out[31:0]),
        .h_out              (hl_hi),
        .l_out              (hl_lo)
    );
    
    // --- JAL Logic --- //
    mux2 #(32) jal_mux (
        .sel                (jal_mux_ctrl),
        .a                  (wd_rf_writeback),
        .b                  (pc_plus4),
        .y                  (wd_rf)
    );

    // --- MEM Logic --- //
    mux2 #(32) rf_wd_mux (
            .sel            (dm2reg),
            .a              (alu_out),
            .b              (rd_dm),
            .y              (rf_wd_mux_out)
    );
        
    mux4 #(32) rf_wd_mult_mux(
        .sel                (hilo_mux_ctrl),
        .c                  (hl_hi),
        .b                  (hl_lo),
        .a                  (rf_wd_mux_out),
        .y                  (wd_rf_writeback)
    );

endmodule