/*
* The module detects whether the given number in ieee format is 
* a zero
*
*/

module detector_zero(m, e, z);
    parameter WIDTH_M = 23;
    parameter WIDTH_E = 8;

    input [WIDTH_M-1:0] m;
    input [WIDTH_E-1:0] e;

    output              z;

    // If m=0 and e=0 then the value is zero
    assign z = (m == 0 && e == 0) ? 1'b1 : 1'b0;
endmodule
