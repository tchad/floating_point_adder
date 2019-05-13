/*
* This module detects the difference in exponents of two given number. 
* At its output it sends information about which number was smaller
* and how many spaces should its mantisa be shifted right.
* There is an upper bound of 24 places at which the number become
* insignificant and it si treated as zero.
*
* In the case when two numbers have the same exponent the signal to shift
* is by default made for number A with the right shift of 0.
*/
module exp_comp(e_a, e_b, shamt, sh_ab);

    input [7:0] e_a;
    input [7:0] e_b;

    output [4:0] shamt;
    output sh_ab;


    //internal connections
    reg [4:0] conn_shamt;
    reg conn_sh_ab;


    always @(*) begin
        if(e_a <= e_b) begin
            //reduce shift if over maximum 24
            if(e_b - e_a > 24)
                conn_shamt = 24;
            else
                conn_shamt = e_b - e_a;
            //shift A
            conn_sh_ab = 1'b0;
        end else begin
            //reduce shift if over maximum 24
            if(e_a - e_b > 24) 
                conn_shamt = 24;
            else
                conn_shamt = e_a - e_b;

            //shift B
            conn_sh_ab = 1'b1;
        end
    end

    assign shamt = conn_shamt;
    assign sh_ab = conn_sh_ab;
endmodule

