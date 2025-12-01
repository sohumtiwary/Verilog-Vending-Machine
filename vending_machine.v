`timescale 1ns / 1ps

module vending_machine(
    input clk,
    input reset,
    input Nickel,
    input Dime,
    input Quarter,
    output reg Dispense,
    output reg ReturnNickel,
    output reg ReturnDime,
    output reg ReturnTwoDimes
);

    reg [2:0] state, next_state;
    reg [2:0] refund_state;
    reg refund_active;

    localparam S0  = 3'd0,
               S5  = 3'd1,
               S10 = 3'd2,
               S15 = 3'd3,
               S20 = 3'd4;

    always @(*) begin
        Dispense        = 0;
        ReturnNickel    = 0;
        ReturnDime      = 0;
        ReturnTwoDimes  = 0;
        next_state      = state;

        // Normal FSM behavior
        if (!refund_active) begin
            case (state)
                S0: begin
                    if (Nickel)       next_state = S5;
                    else if (Dime)    next_state = S10;
                    else if (Quarter) begin Dispense = 1; next_state = S0; end
                end
                S5: begin
                    if (Nickel)       next_state = S10;
                    else if (Dime)    next_state = S15;
                    else if (Quarter) begin Dispense = 1; ReturnNickel = 1; next_state = S0; end
                end
                S10: begin
                    if (Nickel)       next_state = S15;
                    else if (Dime)    next_state = S20;
                    else if (Quarter) begin Dispense = 1; ReturnDime = 1; next_state = S0; end
                end
                S15: begin
                    if (Nickel)       next_state = S20;
                    else if (Dime)    begin Dispense = 1; next_state = S0; end
                    else if (Quarter) begin Dispense = 1; ReturnNickel = 1; ReturnDime = 1; next_state = S0; end
                end
                S20: begin
                    if (Nickel)       begin Dispense = 1; next_state = S0; end
                    else if (Dime)    begin Dispense = 1; ReturnNickel = 1; next_state = S0; end
                    else if (Quarter) begin Dispense = 1; ReturnTwoDimes = 1; next_state = S0; end
                end
                default: next_state = S0;
            endcase
        end

        // Refund pulse (one-cycle after reset)
        if (refund_active) begin
            case (refund_state)
                S5:  ReturnNickel   = 1;
                S10: ReturnDime     = 1;
                S15: begin ReturnNickel = 1; ReturnDime = 1; end
                S20: ReturnTwoDimes = 1;
                default: ;
            endcase
        end
    end

    // state machine + refund trigger
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            refund_state  <= state;   // save credit state
            refund_active <= 1'b0;    // arm refund, will go high next cycle
            state <= S0;
        end
        else begin
            state <= next_state;
            refund_active <= refund_state != S0; // trigger refund next cycle if credit existed
            if (refund_active)
                refund_state <= S0; // clear refund after one cycle
        end
    end

endmodule
