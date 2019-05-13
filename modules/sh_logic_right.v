/* 
* This module performs right shift by given amount
* when enable bit is high
*/

module sh_logic_right(d, shamt, en, out);
    input [24:0] d;
    input  [4:0] shamt;
    input        en;
    
    output [24:0] out;

    assign out = (en == 1'b1) ? d >> shamt : d;

endmodule
   

