`timescale 1ns/10ps

`include "fp_adder_single_cycle.v"

/*
* Top module test bench of single cycle floating point adder
*/
module top();
    reg [31:0] test_A [0:7];
    reg [31:0] test_B [0:7];
    reg [31:0] test_SUM [0:7];
    
    integer test_num_cases;

    //Populate set with test vectors
    task populate_test_set;
    begin
        test_A[0] =   32'b0_10000101_10001000000000000000000; //98
        test_B[0] =   32'b0_10000110_01010010000000000000000; //169
        test_SUM[0] = 32'b0_10000111_00001011000000000000000; //267 

        test_A[1] =   32'b0_10000101_10001100000000000000000; //99
        test_B[1] =   32'b1_10000101_01100100000000000000000; //-89
        test_SUM[1] = 32'b0_10000010_01000000000000000000000; //10
        
        test_A[2] =   32'b1_10000100_01101000000000000000000; //-45
        test_B[2] =   32'b0_10000101_00111100000000000000000; //79
        test_SUM[2] = 32'b0_10000100_00010000000000000000000; //34

        test_A[3] =   32'b1_10000111_00011011000000000000000; //-283
        test_B[3] =   32'b1_10000101_00001000000000000000000; //-66
        test_SUM[3] = 32'b1_10000111_01011101000000000000000; //-349

        test_A[4] =   32'b0_00000000_00000000000000000000000; //0
        test_B[4] =   32'b0_00000000_00000000000000000000000; //0
        test_SUM[4] = 32'b0_00000000_00000000000000000000000; //0

        test_A[5] =   32'b0_00000000_00000000000000000000000; //0
        test_B[5] =   32'b1_10000101_11010100000000000000000; //-117
        test_SUM[5] = 32'b1_10000101_11010100000000000000000;

        test_A[6] =   32'b1_10000101_10111000100000000000000; //-110.125
        test_B[6] =   32'b0_10000101_10001111100000000000000; //99.875
        test_SUM[6] = 32'b1_10000010_01001000000000000000000; //-10.25

        test_A[7] =   32'b0_10000101_10111011100000000000000; //110.875
        test_B[7] =   32'b0_10000101_10001100100000000000000; //99.125
        test_SUM[7] = 32'b0_10000110_10100100000000000000000; //210

        test_num_cases = 8;
    end
    endtask


    //Instantiate device under test
    reg  [31:0] FP_ADD_SC_I_A;
    reg  [31:0] FP_ADD_SC_I_B;
    wire [31:0] FP_ADD_SC_O_SUM;
    fp_adder_single_cycle FP_ADD_SC_DUT(.a(FP_ADD_SC_I_A),
                                        .b(FP_ADD_SC_I_B),
                                        .sum(FP_ADD_SC_O_SUM)
                                        );


    //Testing procedure
    //For single entry in test vector set the inputs and compare
    //the output with expected value
    task test_1cycle;
        integer i;
    begin
        $display("Testing single cycle floating point adder");
        for(i=0; i< test_num_cases; i=i+1) begin
            FP_ADD_SC_I_A = test_A[i];
            FP_ADD_SC_I_B = test_B[i];

            #1;
            $display("-------------------------");
            $display("Test case: %d", i);
            $display("A:       %b", FP_ADD_SC_I_A);
            $display("B:       %b", FP_ADD_SC_I_B);
            $display("SUM:     %b", FP_ADD_SC_O_SUM);
            $display("EXP SUM: %b", test_SUM[i]);

            if(FP_ADD_SC_O_SUM == test_SUM[i]) begin
                $display("PASSED");
            end else begin
                $display("FAILED");
            end

        end
    end
    endtask

    initial begin : TEST_MAIN
        //Dump variables for timing diagrams
        $dumpfile("test_single_cycle.vcd");
        $dumpvars;

        populate_test_set();
        test_1cycle();
        
        $finish();
    end
endmodule

