module controlunit (
        input  wire [5:0]  opcode,
        input  wire [5:0]  funct,
        output wire        branch,
        output wire        jump,
        output wire        reg_dst,
        output wire        we_reg,
        output wire        alu_src,
        output wire        we_dm,
        output wire        dm2reg,
        output wire [2:0]  alu_ctrl,
        output wire        jr_mux_ctrl,
        output wire [1:0]  hilo_mux_ctrl,
        output wire        hilo_we,
        output wire        jal_mux_ctrl
    );
    
    wire [1:0] alu_op;

    maindec md (
        .opcode         (opcode),
        .branch         (branch),
        .jump           (jump),
        .reg_dst        (reg_dst),
        .we_reg         (we_reg),
        .alu_src        (alu_src),
        .we_dm          (we_dm),
        .dm2reg         (dm2reg),
        .alu_op         (alu_op),
        .jal_mux_ctrl   (jal_mux_ctrl)
    );
    
    auxdec ad (
        .alu_op         (alu_op),
        .funct          (funct),
        .alu_ctrl       (alu_ctrl),
        .hilo_mux_ctrl  (hilo_mux_ctrl),
        .hilo_we        (hilo_we),
        .jr_mux_ctrl    (jr_mux_ctrl)
    );

endmodule