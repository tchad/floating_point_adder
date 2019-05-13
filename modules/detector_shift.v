/*
* Module is used in normalization of mantisa
* It detects the amount of shif required to bring
* the mantisa int 1.xxx form
*
* The two outputs are:
*  sh - is the amount of shift that has to be done on mantisa
*  exp_adj - is the adjustment of the resulting exponent
*
* The module handles special case when the result is zero, the module
* Makes adjustments necesarry for nest stage exponent adjustment component
* to correctly calculate resulting exponent of 0.
* 
* In general case the sh and exp_adj hold the same value
*/
module detector_shift(m, sh, exp_adj);
    parameter WIDTH = 1;

    input  [WIDTH-1:0] m;
    output [4:0]       sh;
    output [4:0]       exp_adj;

    //Internal connections
    reg    [4:0]       sh_d;
    reg    [4:0]       exp_adj_d;
    reg                done; 
    integer            i;

    always @(*) begin
        if( | m == 1'b0 ) begin // Zero case
            sh_d = 0;
            exp_adj_d = 2'b10; //add correction for next stage
        end else begin // Non zero case
            done = 1'b0;
            i=WIDTH-1;
            sh_d = 0;

            //iterate over array until bit value 1 is encountered
            while(done == 1'b0) begin
                sh_d = sh_d+1;
                if(m[i] == 1'b1 || i == 0) 
                    done = 1'b1;
                i = i-1;
            end
            exp_adj_d = sh;
        end
    end

    assign sh = sh_d;
    assign exp_adj = exp_adj_d;
endmodule
