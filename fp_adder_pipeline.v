`timescale 1ns/10ps

`include "modules/exp_comp.v"
`include "modules/sh_logic_right.v"
`include "modules/mux2.v"
`include "modules/lt_comp.v"
`include "modules/compl2.v"
`include "modules/selector_sign.v"
`include "modules/adder.v"
`include "modules/detector_shift.v"
`include "modules/sh_logic_left.v"
`include "modules/exp_adjust.v"

/*
* Main floating point adder module pipelined
*/

module fp_adder_pipeline(a, b, sum, clk);
    input [31:0] a;
    input [31:0] b;
    input        clk;

    output [31:0] sum;

    //State registers
    //Stage 1
    reg [31:0] reg_s1_a;
    reg [31:0] reg_s1_b;
    reg  [4:0] reg_s1_shamt;
    reg        reg_s1_sh_ab;

    //Stage 2
    reg [24:0] reg_s2_ma;
    reg [24:0] reg_s2_mb;
    reg  [7:0] reg_s2_e;
    reg        reg_s2_sa;
    reg        reg_s2_sb;

    //Stage 3
    reg [24:0] reg_s3_m1;
    reg [24:0] reg_s3_m2;
    reg  [7:0] reg_s3_e;
    reg        reg_s3_s;

    //Stage 4
    reg [24:0] reg_s4_m;
    reg  [7:0] reg_s4_e;
    reg        reg_s4_s;
    reg  [4:0] reg_s4_m_sh;
    reg  [4:0] reg_s4_exp_adj;

    //Stage 5
    reg [31:0] reg_s5_sum;

    //IMPLEMENTATION

    //----STAGE 1 ----//
    //Combinational part
    wire [4:0] s1_shamt;
    wire       s1_sh_ab;

    //detect which numbers mantisa to shift ans by how much
    exp_comp U1(.e_a(a[30:23]),
                .e_b(b[30:23]),
                .shamt(s1_shamt),
                .sh_ab(s1_sh_ab)
                );

    //Sequential part
    always @(posedge clk) begin
        reg_s1_a     <= #1 a;
        reg_s1_b     <= #1 b;
        reg_s1_shamt <= #1 s1_shamt;
        reg_s1_sh_ab <= #1 s1_sh_ab;
    end

    //----STAGE 2 ----//
    //Combinational part
    wire [24:0] s2_ma_shifted;
    wire [24:0] s2_mb_shifted;
    wire  [7:0] s2_e;
    wire        s2_sa;
    wire        s2_sb;
    wire [24:0] s2_m_zero; //Hardwired extended zero mantisa
    wire        s2_ma_zero_cond;
    wire        s2_mb_zero_cond;
    wire [24:0] s2_ma;
    wire [24:0] s2_mb;

    //Shift mantisa of number A to the right if enabled
    sh_logic_right U2(.d({2'b01,reg_s1_a[22:0]}),
                      .shamt(reg_s1_shamt),
                      .en(~reg_s1_sh_ab),
                      .out(s2_ma_shifted)
                      );

    //Shift mantisa of number B to the right if enabled
    sh_logic_right U3(.d({2'b01,reg_s1_b[22:0]}),
                      .shamt(reg_s1_shamt),
                      .en(reg_s1_sh_ab),
                      .out(s2_mb_shifted)
                      );

    //Select larger exponent to propagate
    mux2 #(.WIDTH(8)) U4(.i0(reg_s1_a[30:23]),
                         .i1(reg_s1_b[30:23]),
                         .o(s2_e),
                         .s(~reg_s1_sh_ab)
                         );

    //Propagate sign bits
    assign s2_sa = reg_s1_a[31];
    assign s2_sb = reg_s1_b[31];

    //Hardwired extended zero mantisa
    assign s2_m_zero = 25'b0;

    //Detecting the zero number for first argument
    //If detected propoagate 0 mantisa instead of 01.xxx mantisa
    assign s2_ma_zero_cond = (reg_s1_a[30:0] == 30'b0) ? 1'b1 : 1'b0;
    mux2 #(.WIDTH(25)) U5(.i0(s2_ma_shifted),
                          .i1(s2_m_zero),
                          .o(s2_ma),
                          .s(s2_ma_zero_cond)
                         );

    //Detecting the zero number for second arguent
    //If detected propoagate 0 mantisa instead of 01.xxx mantisa
    assign s2_mb_zero_cond = (reg_s1_b[30:0] == 30'b0) ? 1'b1 : 1'b0;
    mux2 #(.WIDTH(25)) U6(.i0(s2_mb_shifted),
                          .i1(s2_m_zero),
                          .o(s2_mb),
                          .s(s2_mb_zero_cond)
                         );
    //Sequential part
    always @(posedge clk) begin
        reg_s2_ma <= #1 s2_ma;
        reg_s2_mb <= #1 s2_mb;
        reg_s2_e  <= #1 s2_e;
        reg_s2_sa <= #1 s2_sa;
        reg_s2_sb <= #1 s2_sb;
    end

    //----STAGE 3 ----//
    //Combinational part
    wire        s3_altb;
    wire        s3_signs_diff;
    wire [24:0] s3_ma_compl2;
    wire [24:0] s3_mb_compl2;
    wire        s3_sel_ma_compl;
    wire [24:0] s3_m1;
    wire        s3_sel_mb_compl;
    wire [24:0] s3_m2;
    wire  [7:0] s3_e;
    wire        s3_s;

    //Testing which mantisa is smaller
    lt_comp #(.WIDTH(25)) U7(.a(reg_s2_ma),
                             .b(reg_s2_mb),
                             .o(s3_altb)
                            );
                            
    //Testing if signs are different
    assign s3_signs_diff = reg_s2_sa ^ reg_s2_sb;
    
    //precomputing the 2's complement of mantisa A
    compl2 #(.WIDTH(25)) U8(.i(reg_s2_ma),
                            .o(s3_ma_compl2)
                        );

    //precomputing the 2's complement of mantisa B
    compl2 #(.WIDTH(25)) U9(.i(reg_s2_mb),
                            .o(s3_mb_compl2)
                        );

    assign s3_sel_ma_compl = (s3_signs_diff==1'b1 && s3_altb==1'b1) ? 1'b1 
                                                                             : 1'b0;

    //Propagate 2's complement of mantisa A if mantisa_A < mantisa B and signs
    //are different
    mux2 #(.WIDTH(25)) U10(.i0(reg_s2_ma),
                           .i1(s3_ma_compl2),
                           .o(s3_m1),
                           .s(s3_sel_ma_compl)
                       );

    assign s3_sel_mb_compl = (s3_signs_diff==1'b1 && s3_altb==1'b0) ? 1'b1 
                                                                             : 1'b0;
    //Propagate 2's complement of mantisa B if mantisa_B < mantisa_A and signs
    //are different
    mux2 #(.WIDTH(25)) U11(.i0(reg_s2_mb),
                           .i1(s3_mb_compl2),
                           .o(s3_m2),
                           .s(s3_sel_mb_compl)
                       );

    //Select sign bit of A or B to propagate
    sign_selector U12(.sa(reg_s2_sa),
                      .sb(reg_s2_sb),
                      .a_lt_b(s3_altb),
                      .s(s3_s)
                  );

    //Propagate exponent
    assign s3_e = reg_s2_e;

    //Sequential part
    always @(posedge clk) begin
        reg_s3_m1 <= #1 s3_m1;
        reg_s3_m2 <= #1 s3_m2;
        reg_s3_e  <= #1 s3_e;
        reg_s3_s  <= #1 s3_s;
    end


    //----STAGE 4 ----//
    //Combinational part
    wire [24:0] s4_m;
    wire  [4:0] s4_sh;
    wire  [4:0] s4_exp_adj;
    wire  [7:0] s4_e;
    wire        s4_s;


    //Add mantisas
    adder #(.WIDTH(25)) U13(.a(reg_s3_m1),
                            .b(reg_s3_m2),
                            .sum(s4_m)
                        );

    //Determine the amount of shift for normalization
    detector_shift #(.WIDTH(25)) U14(.m(s4_m),
                                    .sh(s4_sh),
                                    .exp_adj(s4_exp_adj)
                                );
    assign s4_e = reg_s3_e;
    assign s4_s = reg_s3_s;

    //Sequential part
    always @(posedge clk) begin
        reg_s4_m       <= #1 s4_m;
        reg_s4_e       <= #1 s4_e;
        reg_s4_s       <= #1 s4_s;
        reg_s4_m_sh    <= #1 s4_sh;
        reg_s4_exp_adj <= #1 s4_exp_adj;
    end


    //----STAGE 5 ----//
    //Combinational part
    wire [22:0] s5_m_out;
    wire  [7:0] s5_e_out;
    wire [31:0] s5_sum;

    //Normalize mantisa
    sh_logic_left #(.WIDTH(25), .WIDTH_OUT(23)) U15(.m(reg_s4_m),
                                                    .sh(reg_s4_m_sh),
                                                    .out(s5_m_out)
                                                );

    //Adjust exponent
    exp_adjust U16(.e(reg_s4_e),
                   .sh(reg_s4_exp_adj),
                   .e_out(s5_e_out)
               );

    //Combine result
    assign s5_sum = {reg_s4_s, s5_e_out, s5_m_out};

    //Sequential part
    always @(posedge clk) begin
        reg_s5_sum <= #1 s5_sum;
    end
   
    //Output
    assign sum = reg_s5_sum;    
endmodule

