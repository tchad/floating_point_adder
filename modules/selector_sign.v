/* This module makes the selection of which value(A or B)
* sign should be propagated further in the following way:
* 
* if signs different then
*   if mantisaA < mantisa B then
*       propagate sign_bit_B
*   otherwise
*       propagate sign_bit_A
*   endif
* otherwise
*   propagate sign_bit_A
* endif
*
*/

module sign_selector(sa, sb, a_lt_b, s);
    input   sa;
    input   sb;
    input   a_lt_b;

    output  s;

    //internal connections
    reg s_d;

    always @(*) begin
        if( (sa ^ sb) == 1'b1) begin
            if(a_lt_b == 1'b1)
                s_d = sb;
            else
                s_d = sa;
        end else begin
            s_d = sa;
        end
    end

    assign s = s_d;
endmodule
