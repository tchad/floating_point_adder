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
* Main floating point adder module single cycle
*/

module fp_adder_single_cycle(a, b, sum);
    input [31:0] a;
    input [31:0] b;

    output [31:0] sum;

    wire [4:0] U1_shamt;
    wire       U1_sh_ab;

    //detect which numbers mantisa to shift ans by how much
    exp_comp U1(.e_a(a[30:23]),
                .e_b(b[30:23]),
                .shamt(U1_shamt),
                .sh_ab(U1_sh_ab)
                );



    wire [24:0] U2_o;
    
    //Shift mantisa of number A to the right if enabled
    sh_logic_right U2(.d({2'b01,a[22:0]}),
                      .shamt(U1_shamt),
                      .en(~U1_sh_ab),
                      .out(U2_o)
                      );

    wire [24:0] U3_o;
    
    //Shift mantisa of number B to the right if enabled
    sh_logic_right U3(.d({2'b01,b[22:0]}),
                      .shamt(U1_shamt),
                      .en(U1_sh_ab),
                      .out(U3_o)
                      );


    wire [7:0] U4_e;

    //Select larger exponent to propagate
    mux2 #(.WIDTH(8)) U4(.i0(a[30:23]),
                         .i1(b[30:23]),
                         .o(U4_e),
                         .s(~U1_sh_ab)
                         );

    wire        sa;
    wire        sb;

    //Propagate sign bits
    assign sa = a[31];
    assign sb = b[31];

    //Hardwired extended zero mantisa
    wire [24:0] m_exp_zero;
    assign m_exp_zero = 25'b0;

    //Detecting the zero number for first argument
    //If detected propoagate 0 mantisa instead of 01.xxx mantisa
    wire ma_zero_cond;
    assign ma_zero_cond = (a[30:0] == 30'b0) ? 1'b1 : 1'b0;
    wire [24:0] U5_ma;
    mux2 #(.WIDTH(25)) U5(.i0(U2_o),
                          .i1(m_exp_zero),
                          .o(U5_ma),
                          .s(ma_zero_cond)
                         );

    //Detecting the zero number for second arguent
    //If detected propoagate 0 mantisa instead of 01.xxx mantisa
    wire mb_zero_cond;
    assign mb_zero_cond = (b[30:0] == 30'b0) ? 1'b1 : 1'b0;
    wire [24:0] U6_mb;
    mux2 #(.WIDTH(25)) U6(.i0(U3_o),
                          .i1(m_exp_zero),
                          .o(U6_mb),
                          .s(mb_zero_cond)
                         );

    //Testing which mantisa is smaller
    wire U7_a_lt_b;
    lt_comp #(.WIDTH(25)) U7(.a(U5_ma),
                             .b(U6_mb),
                             .o(U7_a_lt_b)
                            );
                            
    wire signs_diff;

    //Testing if signs are different
    assign signs_diff = sa ^ sb;
    
    wire [24:0] U8_ma_compl2;

    //precomputing the 2's complement of mantisa A
    compl2 #(.WIDTH(25)) U8(.i(U5_ma),
                            .o(U8_ma_compl2)
                        );

    wire [24:0] U9_mb_compl2;

    //precomputing the 2's complement of mantisa B
    compl2 #(.WIDTH(25)) U9(.i(U6_mb),
                            .o(U9_mb_compl2)
                        );

    wire sel_ma_compl;
    assign sel_ma_compl = (signs_diff==1'b1 && U7_a_lt_b==1'b1) ? 1'b1 : 1'b0;

    wire [24:0] U10_m1;
    
    //Propagate 2's complement of mantisa A if mantisa_A < mantisa B and signs
    //are different
    mux2 #(.WIDTH(25)) U10(.i0(U5_ma),
                           .i1(U8_ma_compl2),
                           .o(U10_m1),
                           .s(sel_ma_compl)
                       );

    wire sel_mb_compl;
    assign sel_mb_compl = (signs_diff==1'b1 && U7_a_lt_b==1'b0) ? 1'b1 : 1'b0;

    wire [24:0] U11_m2;

    //Propagate 2's complement of mantisa B if mantisa_B < mantisa_A and signs
    //are different
    mux2 #(.WIDTH(25)) U11(.i0(U6_mb),
                           .i1(U9_mb_compl2),
                           .o(U11_m2),
                           .s(sel_mb_compl)
                       );

    wire U12_s;

    //Select sign bit of A or B to propagate
    sign_selector U12(.sa(sa),
                      .sb(sb),
                      .a_lt_b(U7_a_lt_b),
                      .s(U12_s)
                  );

    //Add mantisas
    wire [24:0] U13_m;
    adder #(.WIDTH(25)) U13(.a(U10_m1),
                            .b(U11_m2),
                            .sum(U13_m)
                        );

    wire [4:0] U14_sh;
    wire [4:0] U14_exp_adj;
    
    //Determine the amount of shift for normalization
    detector_shift #(.WIDTH(25)) U14(.m(U13_m),
                                    .sh(U14_sh),
                                    .exp_adj(U14_exp_adj)
                                );

    wire [22:0] U15_m_out;

    //Normalize mantisa
    sh_logic_left #(.WIDTH(25), .WIDTH_OUT(23)) U15(.m(U13_m),
                                                    .sh(U14_sh),
                                                    .out(U15_m_out)
                                                );

    //Adjust exponent
    wire [7:0] U16_e_out;
    exp_adjust U16(.e(U4_e),
                   .sh(U14_exp_adj),
                   .e_out(U16_e_out)
               );

    //Combine result
    assign sum = {U12_s, U16_e_out, U15_m_out};

endmodule

