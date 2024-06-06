/*
=====================================================================================
=                                                                                   =
=   Author: Hoang Van Quyen - UET - VNU                                             =
=                                                                                   =
=====================================================================================
*/
module exp_2_block_16 
#(
    parameter                           data_size = 16
)
(
    input                               clock_i                                                                 ,
    input                               reset_n_i                                                               ,
    input           [data_size - 1:0]   exp_data_i                                                              , // 1.7.8
    input                               exp_data_valid_i                                                        ,
    input                               exp_sub_2_done_i                                                        ,
    
    //Master AXI4 Stream
    input                               m_axis_ready_i                                                          ,
    output  reg                         m_axis_last_o                                                           ,
    output  reg                         m_axis_valid_o                                                          ,
    output  reg     [2*data_size - 1:0] m_axis_data_o
);
    //----------------------------------------internal variable-------------------------------------------------
    integer                             i                                                                       ;
    reg             [7:0]               save_fxp_16_counter                                                     ;
    reg             [7:0]               m_axis_counter                                                          ;
    reg             [7:0]               number_of_data                                                          ;
    reg             [data_size - 1:0]   LUT_EXP                [11:0]                                           ;
    reg                                 exp_data_valid_o_temp                                                   ;
    
    
    
    reg             [4*data_size - 1:0] exp_data_o_temp                                                         ;

    reg             [data_size - 1:0]   fxp_16_output_buffer   [9:0]                                            ;
    reg             [2*data_size - 1:0] fp_32_output_buffer    [9:0]                                            ;



    reg             [data_size - 1:0]   input_buffer  [9:0]                                                     ;
    reg             [7:0]               counter_for_input                                                       ;

    reg             [7:0]               counter_for_compute                                                     ;
    reg             [7:0]               lut_counter                                                             ;

    //------------------------------------------------save input from sub 2 block---------------------------------
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
    
    //------------------------------------------------get number of data----------------------------------------
    always @(posedge clock_i)
    begin
        if (~reset_n_i)
            number_of_data <= 0                                                                                 ;
        else
            if (exp_sub_2_done_i)
                number_of_data <= counter_for_input                                                             ;
    end

    //-----------------------------------------------save output FXP_16-----------------------------------------
    always @(posedge clock_i)
    begin
        if (~reset_n_i)
            for(i = 0 ; i < 10 ; i = i + 1)
                fxp_16_output_buffer[i] <= 0                                                                    ;
        else
            if (exp_data_valid_o_temp)
                fxp_16_output_buffer[save_fxp_16_counter] <= exp_data_o_temp[63:48]                             ;
    end

    always @(posedge clock_i)
    begin
        if (~reset_n_i)
            save_fxp_16_counter <= 0                                                                            ;
        else
            if (exp_data_valid_o_temp)
                save_fxp_16_counter <= save_fxp_16_counter + 1                                                  ;
    end


    //------------------------------------------AXI4 STREAM TRANSACTION-----------------------------------------
    
    always @(posedge clock_i) 
    begin
        if (~reset_n_i)
            begin
                m_axis_last_o <= 0                                                                              ;
                m_axis_counter <= 0                                                                             ;         
                m_axis_valid_o <= 0                                                                             ;
                m_axis_data_o <= 0                                                                              ;
            end
        else
            begin
                if (save_fxp_16_counter == number_of_data && m_axis_counter < number_of_data && number_of_data)
                    begin
                        m_axis_valid_o <= 1                                                                     ;
                        m_axis_data_o <= {fxp_16_output_buffer[m_axis_counter], 16'b0}                          ;
                        m_axis_counter <= m_axis_counter + 1                                                    ;
                    end
                else if (m_axis_counter == number_of_data && m_axis_ready_i)
                    m_axis_valid_o = 0                                                                          ;
                if (m_axis_counter == number_of_data - 1)
                    m_axis_last_o <= 1                                                                          ;
                if (m_axis_ready_i && m_axis_valid_o && m_axis_counter < number_of_data)
                    begin
                        m_axis_data_o <= {fxp_16_output_buffer[m_axis_counter], 16'b0}                          ;
                        m_axis_counter <= m_axis_counter + 1                                                    ;
                    end
                if (m_axis_last_o && m_axis_ready_i)
                    m_axis_last_o <= 0                                                                          ;
            end
    end


    //-------------------------------------------LUT EXP--------------------------------------------------------

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