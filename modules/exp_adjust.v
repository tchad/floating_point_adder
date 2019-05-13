/*
* The module adjusts the resultin exponent of the resulting number.
* The constant shift by 2 term is the result of left extending the mantisa 
* register to accomodate for implicit 1 and possible addition overflow
*/

module exp_adjust(e,sh,e_out);
    input  [7:0] e;
    input  [4:0] sh;

    output [7:0] e_out;

    assign e_out = e + 2'b10 - sh;
endmodule
