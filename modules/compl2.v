/*
* Module calculating 2's complement of a given number
*/

module compl2 (i, o);
    parameter WIDTH = 1;

    input  [WIDTH-1:0] i;

    output [WIDTH-1:0] o;

    assign o = ~i + 1'b1;
endmodule
