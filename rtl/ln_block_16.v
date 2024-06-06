/*
=====================================================================================
=                                                                                   =
=   Author: Hoang Van Quyen - UET - VNU                                             =
=                                                                                   =
=====================================================================================
*/
module ln_block_16
#(
    parameter                           data_size = 16
)
(
    input                               clock_i                                                                 ,
    input                               reset_n_i                                                               ,
    input           [data_size - 1:0]   ln_data_i                                                               ,  //data from adder block 4 integer, 28 fractional
    input                               ln_data_valid_i                                                         ,
    
    output                              ln_data_valid_o                                                         ,
    output          [data_size - 1:0]   ln_data_o
);
    reg                                 input_ready                                                             ;
    reg             [data_size - 1:0]   fxp_data_i_temp                                                         ;
    reg             [data_size - 1:0]   fp_data                                                                 ;
    reg                                 fp_data_valid                                                           ;
    
    reg                                 ln2_exp_valid                                                           ;
    reg             [data_size - 1:0]   ln2_exp                                                                 ;


    reg             [data_size - 1:0]   ln_data_o_temp                                                          ;
    reg                                 ln_data_valid_o_temp                                                    ;

    wire                                fp_data_valid_wire                                                      ;
    wire            [data_size - 1:0]   lut_ln_man_wire                                                         ;//LUT LN 16 bit
    wire            [data_size/2 - 1:0] lut_ln_man_input_wire                                                   ;
    wire                                lut_ln_man_valid_wire                                                   ;


    assign ln_data_o = ln_data_o_temp                                                                           ;
    assign ln_data_valid_o = ln_data_valid_o_temp                                                               ;
    
    always @(posedge clock_i)
    begin
        if (~reset_n_i)
            begin
                fp_data_valid <= 0                                                                              ;
                fp_data <= {1'b0, 5'b10010, 10'b0}                                                              ;
                fxp_data_i_temp <= 0                                                                            ;
                input_ready <= 0                                                                                ;
            end
        else
            if (ln_data_valid_i)
            begin
                if (~input_ready)
                begin
                    fxp_data_i_temp <= ln_data_i                                                                ;
                    input_ready <= 1                                                                            ;
                end
                if (input_ready && ~fp_data_valid)
                begin
                    if (fxp_data_i_temp[data_size - 1])
                        begin
                            fp_data_valid <= 1                                                                  ;
                            fp_data[14:10] <= fp_data[14:10]                                                    ;
                            fp_data[9:0] <= fxp_data_i_temp[14:5]                                               ;
                        end
                    else
                        begin
                            fxp_data_i_temp <= fxp_data_i_temp << 1                                             ;
                            fp_data[14:10] <= fp_data[14:10] - 1                                                ;
                        end
                end    
            end
    end
    
    //ln(2) * (exp - 127): 2 integer 30 fraction
    always @(posedge clock_i)
    begin
        if (~reset_n_i)
            begin
                ln2_exp_valid <= 0                                                                              ;
                ln2_exp <= 0                                                                                    ;
            end
        else
            begin
                if (fp_data_valid && ~ln2_exp_valid)
                    begin
                        $display("%0d", fp_data[14:10])                                                         ;
                        if (fp_data[14:10] == 8'b01111)
                            ln2_exp <= 16'b0                                                                    ;
                        else if (fp_data[14:10] == 8'b10000)
                            ln2_exp <= 16'b0010_1100_0101_1100                                                  ;
                        else if (fp_data[14:10] == 5'b10001)
                            ln2_exp <= 16'b0101_1000_1011_1001                                                  ;
                        else if (fp_data[14:10] == 5'b10010)
                            ln2_exp <= 16'b1000_0101_0001_0101                                                  ;
                        ln2_exp_valid <= 1                                                                      ;
                    end
            end
    end

    //LUT LN (1.man)
    assign  lut_ln_man_input_wire = fp_data[9:2]                                                                ;
    assign  fp_data_valid_wire = fp_data_valid                                                                  ;
    lut_ln_16 lut_16(
        .clock_i(clock_i)                                                                                       ,
        .reset_n_i(reset_n_i)                                                                                   ,
        .lut_ln_data_i(lut_ln_man_input_wire)                                                                   ,
        .lut_ln_data_valid_i(fp_data_valid_wire)                                                                ,

        .lut_ln_data_o(lut_ln_man_wire)                                                                         ,
        .lut_ln_data_valid_o(lut_ln_man_valid_wire)
    );


    //ln(x) = ln(2) * (exp - 127) + ln(1,man)
    always @(posedge clock_i) 
    begin
        if (~reset_n_i)
            begin
                ln_data_o_temp <= 0                                                                             ;
                ln_data_valid_o_temp <= 0                                                                       ;
            end
        else
            begin
                if (ln2_exp_valid && lut_ln_man_valid_wire && ~ln_data_valid_o_temp)
                    begin
                        ln_data_o_temp <= {2'b0, lut_ln_man_wire[15:2]} + ln2_exp                               ;//LUT LN 16 bits
                        ln_data_valid_o_temp <= 1                                                               ;
                    end
            end
    end
endmodule