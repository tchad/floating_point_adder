/*
* This module detects the condition
* mantisa_A < mantisa_B
*/
module lt_comp(a, b, o);
    parameter WIDTH = 1;

    input [WIDTH-1:0] a;
    input [WIDTH-1:0] b;

    output            o;

    assign o = a < b;
endmodule
