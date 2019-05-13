/*
* Two input mutex
*/

module mux2(i0, i1, o, s);
    parameter WIDTH = 1;

    input  [WIDTH-1:0] i0;
    input  [WIDTH-1:0] i1;
    input              s;

    output [WIDTH-1:0] o;

    assign o = (s == 1'b0) ? i0 : i1;
endmodule
