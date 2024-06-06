/*
=====================================================================================
=                                                                                   =
=   Author: Hoang Van Quyen - UET - VNU                                             =
=                                                                                   =
=====================================================================================
*/
module exp_1_block_16 
#(
    parameter                           data_size = 16
)
(
    input                               clock_i                                                                 ,
    input                               reset_n_i                                                               ,
    input           [data_size - 1:0]   exp_data_i                                                              , // 1.7.8
    input                               exp_data_valid_i                                                        ,
    
    output  reg                         exp_done_o                                                              ,
    output  reg                         exp_data_valid_o                                                        ,
    output  reg     [data_size - 1:0]   exp_data_o
);
    //----------------------------------------internal variable-------------------------------------------------
    reg             [data_size - 1:0]   LUT_EXP         [11:0]                                                  ;
    
    reg                                 exp_data_valid_o_temp                                                   ;
    reg             [4*data_size - 1:0] exp_data_o_temp                                                         ;
    
    reg                                 exp_data_valid_i_temp                                                   ;
    
    reg             [data_size - 1:0]   input_buffer  [9:0]                                                     ;
    reg             [7:0]               counter_for_input                                                       ;
    integer                             i                                                                       ;

    reg             [7:0]               counter_for_compute                                                     ;
    reg             [7:0]               lut_counter                                                             ;
    
    //------------------------------------------get input from downscale block----------------------------------
    always @(posedge clock_i) 
    begin
        if (~reset_n_i)
                for (i = 0 ; i < 10 ; i = i + 1)
                    input_buffer[i] <= 0                                                                        ;
        else
            if (exp_data_valid_i)
                input_buffer[counter_for_input] <= ~exp_data_i + 1                                              ;
    end

    always @(posedge clock_i) 
    begin
        if (~reset_n_i)
            counter_for_input <= 0                                                                              ;
        else
            if (exp_data_valid_i)
                counter_for_input <= counter_for_input + 1                                                      ;
    end
    
    //-------------------------------------------------done signal----------------------------------------------
    always @(posedge clock_i) 
    begin
        if (~reset_n_i)
            begin
                exp_data_valid_o <= 0                                                                           ;
                exp_done_o <= 0                                                                                 ;
                exp_data_o <= 0                                                                                 ;
            end
        else
            begin
                exp_data_valid_o <= exp_data_valid_o_temp                                                       ;
                exp_data_o <= exp_data_o_temp[63:48]                                                            ;
                if (counter_for_compute == counter_for_input && counter_for_input)
                    exp_done_o <= 1                                                                             ;
            end
    end

    //-------------------------------------------------LUT EXP--------------------------------------------------
    always @(posedge clock_i) 
    begin
        if (~reset_n_i)
            counter_for_compute <= 0                                                                            ;
        else
            if (exp_data_valid_o_temp && counter_for_compute < counter_for_input)
                counter_for_compute <= counter_for_compute + 1                                                  ;
    end
    

    always @(posedge clock_i)
    begin
        if (~reset_n_i)
            begin
                exp_data_o_temp <= 0                                                                            ;
                exp_data_valid_o_temp <= 0                                                                      ;
                lut_counter <= 0                                                                                ;
            end
        else
            begin
                if (counter_for_compute < counter_for_input && ~exp_data_valid_o_temp)
                begin
                    if (input_buffer[counter_for_compute] == 0)
                        begin
                            exp_data_o_temp <= 64'hffffffffffffffff                                             ;
                            exp_data_valid_o_temp <= 1                                                          ;
                        end
                    else
                        begin
                            if (input_buffer[counter_for_compute][14:12])
                                begin
                                    exp_data_o_temp <= 0                                                        ;
                                    exp_data_valid_o_temp <= 1                                                  ;
                                end
                            else
                                begin
                                    if (lut_counter == 0)
                                        begin
                                            exp_data_o_temp <= input_buffer[counter_for_compute][lut_counter] ? 
                                                (input_buffer[counter_for_compute][lut_counter + 1] ? 
                                                {LUT_EXP[lut_counter], 16'b0} * {LUT_EXP[lut_counter + 1], 16'b0} 
                                                : {LUT_EXP[lut_counter], 48'b0}) 
                                                : (input_buffer[counter_for_compute][lut_counter + 1] 
                                                ? {LUT_EXP[lut_counter + 1], 48'b0} : 64'b0)                    ;
                                            lut_counter <= lut_counter + 1                                      ;
                                        end
                                    else if (lut_counter < 11)
                                        begin
                                            exp_data_o_temp <= exp_data_o_temp[63:32] ? (input_buffer[counter_for_compute][lut_counter + 1] 
                                                ? exp_data_o_temp[63:32] * {LUT_EXP[lut_counter + 1], 16'b0} : {exp_data_o_temp[63:32], 32'b0})
                                                : (input_buffer[counter_for_compute][lut_counter + 1] ? 
                                                {LUT_EXP[lut_counter + 1], 48'b0} : 64'b0)                      ;
                                            lut_counter <= lut_counter + 1                                      ;
                                        end
                                    else
                                        begin
                                            lut_counter <= 0                                                    ;
                                            exp_data_valid_o_temp <= 1                                          ;
                                        end
                                end
                        end
                end
            
                if (exp_data_valid_o_temp)
                begin
                     exp_data_valid_o_temp <= 0                                                                 ;
                     exp_data_o_temp <= 0                                                                       ;
                end
            end
    end


    always @(posedge clock_i) 
    begin
        if (~reset_n_i)
        begin
            //fixed point 0 signed, 0 integer, 32 fraction
            LUT_EXP[11] <= 32'b0000_0000_0001_0101                                                              ; //e^-(2^3)
            LUT_EXP[10] <= 16'b0000_0100_1011_0000                                                              ; //e^-(2^2)
            LUT_EXP[9]  <= 16'b0010_0010_1010_0101                                                              ; //e^-(2^1)
            LUT_EXP[8]  <= 16'b0101_1110_0010_1101                                                              ; //e^-(2^0)
            LUT_EXP[7]  <= 16'b1001_1011_0100_0101                                                              ; //e^-(2^-1)
            LUT_EXP[6]  <= 16'b1100_0111_0101_1111                                                              ; //e^-(2^-2)
            LUT_EXP[5]  <= 16'b1110_0001_1110_1011                                                              ; //e^-(2^-3)
            LUT_EXP[4]  <= 16'b1111_0000_0111_1101                                                              ; //e^-(2^-4)
            LUT_EXP[3]  <= 16'b1111_1000_0001_1111                                                              ; //e^-(2^-5)
            LUT_EXP[2]  <= 16'b1111_1100_0000_0111                                                              ; //e^-(2^-6)
            LUT_EXP[1]  <= 16'b1111_1110_0000_0001                                                              ; //e^-(2^-7)
            LUT_EXP[0]  <= 16'b1111_1111_0000_0000                                                              ; //e^-(2^-8)
        end
    end

endmodule