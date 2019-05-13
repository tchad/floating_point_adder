/*
* This module performs shifting left of the mantisa by given amount
* It also reduce the width of resulting vector from the extended
* size used in mantisa addition to IEEE size. Both sizes
* are parametrized to allow flexibility
*/

module sh_logic_left(m, sh, out);
    parameter WIDTH = 1;
    parameter WIDTH_OUT = 1;

    input [WIDTH-1:0]       m;
    input [4:0]            sh;

    output[WIDTH_OUT-1:0] out;

    wire   [WIDTH-1:0] m_d;

    assign m_d = m << sh;
    assign out = m_d[WIDTH-1:WIDTH-WIDTH_OUT];
endmodule
