`timescale 1ns / 1ps

module vend_sim();
    reg clk;
    reg reset;
    reg Nickel;
    reg Dime;
    reg Quarter;

    wire Dispense;
    wire ReturnNickel;
    wire ReturnDime;
    wire ReturnTwoDimes;

    vending_machine dut (
        .clk(clk),
        .reset(reset),
        .Nickel(Nickel),
        .Dime(Dime),
        .Quarter(Quarter),
        .Dispense(Dispense),
        .ReturnNickel(ReturnNickel),
        .ReturnDime(ReturnDime),
        .ReturnTwoDimes(ReturnTwoDimes)
    );

    reg [7:0] vectors [0:255];
    integer i;
    reg [7:0] vec;
    integer errors;
    reg expDisp, expRN, expRD, expR2D;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $readmemb("test_vector.tv", vectors);
        reset = 1;
        Nickel = 0;
        Dime = 0;
        Quarter = 0;
        errors = 0;
        i = 0;

        repeat(2) @(posedge clk);
        reset = 0;

        forever begin
            @(negedge clk);
            vec = vectors[i];
            if (vec === 8'bxxxxxxxx) begin
                $display("Simulation complete. Errors = %0d", errors);
                $finish;
            end

            {reset, Nickel, Dime, Quarter, expDisp, expRN, expRD, expR2D} = vec;

            #1;
            if ({Dispense, ReturnNickel, ReturnDime, ReturnTwoDimes} !== {expDisp, expRN, expRD, expR2D}) begin
                errors = errors + 1;
                $display("Mismatch @%0t ns vec %0d: IN {rst N D Q}=%b%b%b%b  OUT={%b%b%b%b}  EXP={%b%b%b%b}",
                    $time, i,
                    reset, Nickel, Dime, Quarter,
                    Dispense, ReturnNickel, ReturnDime, ReturnTwoDimes,
                    expDisp, expRN, expRD, expR2D);
            end

            @(posedge clk);
            Nickel  = 0;
            Dime    = 0;
            Quarter = 0;
            reset   = 0;
            i = i + 1;
        end
    end
endmodule
