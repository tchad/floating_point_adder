`timescale 1ns/10ps

`include "fp_adder_pipeline.v"

/*
* Top module test bench of pipelined floating point adder
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
    reg  [31:0] FP_ADD_I_A;
    reg  [31:0] FP_ADD_I_B;
    wire [31:0] FP_ADD_O_SUM;
    reg         CLK;
    fp_adder_pipeline FP_ADD_PIPELINE_DUT(.a(FP_ADD_I_A),
                                          .b(FP_ADD_I_B),
                                          .sum(FP_ADD_O_SUM),
                                          .clk(CLK)
                                          );

    //Test output value against expected value at a given index
    //in test vectors
    task verify_cycle;
        input [31:0] result;
        input integer expected_idx;
    begin
        $display("-------------------------");
        $display("Test case: %d", expected_idx);
        $display("A:       %b", test_A[expected_idx]);
        $display("B:       %b", test_B[expected_idx]);
        $display("SUM:     %b", result);
        $display("EXP SUM: %b", test_SUM[expected_idx]);

        if(result == test_SUM[expected_idx]) begin
            $display("PASSED");
        end else begin
            $display("FAILED");
        end
    end
    endtask

    //Advance one clock cycle
    task advance_clock;
    begin
        #1 CLK = 1'b1;
        #1 CLK = 1'b0;
    end
    endtask

    //The output value is expected to appear after 5 cycles.
    //Following the rule where the output of a module should be held by
    //register instead of coming out from output logic
    `define CYCLE_VERIFY_BEGIN 5
    `define TOTAL_CYCLES 13
    
    initial 
    begin : TEST_MAIN
        integer i;
        integer idx;

        //Dump variables for timing diagrams
        $dumpfile("test_pipeline.vcd");
        $dumpvars;

        populate_test_set();
        CLK = 1'b0;

        //Iterate over expected total number of cycles
        for(i=0; i< `TOTAL_CYCLES; i=i+1) begin
            //Feed test data into pipeline for the first N cycles 
            //equal to the number of test cases
            if(i < test_num_cases) begin
                FP_ADD_I_A = test_A[i];
                FP_ADD_I_B = test_B[i];
            end

            //advance clock 
            advance_clock();

            //If current cycle numbe reached expected cycle at which 
            //output is present start testing the results for correctness
            if( i >= `CYCLE_VERIFY_BEGIN) begin
                idx = i - `CYCLE_VERIFY_BEGIN;
                verify_cycle(FP_ADD_O_SUM, idx);
            end

        end

        $finish();
    end
endmodule

