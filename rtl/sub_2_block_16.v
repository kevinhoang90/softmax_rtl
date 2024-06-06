/*
=====================================================================================
=                                                                                   =
=   Author: Hoang Van Quyen - UET - VNU                                             =
=                                                                                   =
=====================================================================================
*/
module sub_2_block_16 
#(
    parameter                           data_size = 16
)
(
    input                               clock_i                                                                 ,
    input                               reset_n_i                                                               ,
    input           [data_size - 1:0]   sub_2_ln_data_i                                                         ,
    input                               sub_2_ln_data_valid_i                                                   ,

    input           [data_size - 1:0]   sub_2_downscale_data_i                                                  ,
    input                               sub_2_downscale_data_valid_i                                            ,
    input           [7:0]               sub_2_downscale_number_of_data_i                                        ,

    output          [data_size - 1:0]   sub_2_data_o                                                            ,
    output                              sub_2_done_o                                                            ,
    output                              sub_2_data_valid_o
);
    //internal variables for input
    integer                             i                                                                       ;
    reg             [7:0]               counter_downscale_input_stream                                          ;
    reg             [data_size - 1:0]   sub_2_input_buffer  [9:0]                                               ;
    reg                                 sub_2_input_buffer_valid                                                ;

    reg                                 sub_2_ln_data_i_valid_temp                                              ;
    reg             [data_size - 1:0]   sub_2_ln_data_i_temp                                                    ;

    //internal variables for output
    reg                                 sub_2_data_valid_o_temp                                                 ;
    reg             [data_size:0]       sub_2_data_o_temp                                                       ;
    reg             [7:0]               counter_sub_2_output_stream                                             ;
    reg                                 sub_2_done_o_temp                                                       ;
    
    //variables for FSM
    localparam                          IDLE = 0                                                                ;
    localparam                          SUBTRACTOR = 1                                                          ;
    localparam                          POST_SUB = 2                                                            ;

    reg             [1:0]               sub_2_current_state                                                     ;
    reg             [1:0]               sub_2_next_state                                                        ;

    //-------------------------------------------------update output--------------------------------------------
    assign sub_2_done_o = sub_2_done_o_temp                                                                     ;
    assign sub_2_data_o = ~sub_2_data_o_temp[15:0] + 1                                                          ;
    assign sub_2_data_valid_o = sub_2_data_valid_o_temp                                                         ;

    //--------------------------------------------------input stream--------------------------------------------
    //catch data from downscale block
    always @(posedge clock_i) 
    begin
        if (~reset_n_i)
            for(i = 0 ; i < 10 ; i = i + 1)
                sub_2_input_buffer[i] <= 0                                                                      ;
        else
            if (sub_2_downscale_data_valid_i)
                sub_2_input_buffer[counter_downscale_input_stream] <= sub_2_downscale_data_i                    ;

    end

    //handle counter data input
    always @(posedge clock_i) 
    begin
        if (~reset_n_i)
            counter_downscale_input_stream <= 0                                                                 ;
        else
            if (sub_2_downscale_data_valid_i)
                counter_downscale_input_stream <= counter_downscale_input_stream + 1                            ;
    end

    


    //capture data from ln block
    always @(posedge clock_i) 
    begin
        if (~reset_n_i)
            begin
                sub_2_ln_data_i_temp <= 0                                                                       ;
            end
        else
            begin
                sub_2_ln_data_i_valid_temp <= sub_2_ln_data_valid_i                                             ;
                if (sub_2_ln_data_valid_i)
                    sub_2_ln_data_i_temp <= sub_2_ln_data_i                                                     ;
            end
    end

    
    always @(posedge clock_i) 
    begin
        if (~reset_n_i)
            sub_2_input_buffer_valid <= 0                                                                       ;
        else
            if (counter_downscale_input_stream > counter_sub_2_output_stream && ~sub_2_input_buffer_valid)
                sub_2_input_buffer_valid <= 1                                                                   ;
            if (sub_2_input_buffer_valid)
                sub_2_input_buffer_valid <= 0                                                                   ;
    end

    //-----------------------------------------------------FSM--------------------------------------------------
    always @(posedge clock_i) 
    begin
        if (~reset_n_i)
            sub_2_current_state <= IDLE                                                                         ;
        else
            sub_2_current_state <= sub_2_next_state                                                             ;
    end

    always @* 
    begin
        case (sub_2_current_state)
            IDLE:
                if (sub_2_input_buffer_valid && sub_2_ln_data_i_valid_temp)
                    sub_2_next_state = SUBTRACTOR                                                               ;
                else
                    sub_2_next_state = IDLE                                                                     ;
            SUBTRACTOR:
                if (sub_2_data_valid_o_temp)
                    sub_2_next_state = POST_SUB                                                                 ;
                else
                    sub_2_next_state = SUBTRACTOR                                                               ;
            POST_SUB: 
                if (~sub_2_data_valid_o_temp && counter_sub_2_output_stream < sub_2_downscale_number_of_data_i - 1 
                    && ~sub_2_downscale_number_of_data_i)
                    sub_2_next_state = SUBTRACTOR                                                               ;
                else if (counter_sub_2_output_stream == sub_2_downscale_number_of_data_i - 1 && ~sub_2_downscale_number_of_data_i)
                    sub_2_next_state = IDLE                                                                     ;
                else
                    sub_2_next_state = POST_SUB                                                                 ;
            default:
                sub_2_next_state = IDLE                                                                         ; 
        endcase
    end

    always @* 
    begin
        case (sub_2_current_state)
            IDLE:
            begin
                sub_2_data_valid_o_temp = 0                                                                     ;
                sub_2_data_o_temp = 0                                                                           ;
            end
            SUBTRACTOR:
            begin
                sub_2_data_o_temp = {(~sub_2_input_buffer[counter_sub_2_output_stream] + 1) + 
                                          {6'b0, sub_2_ln_data_i_temp[15:6]}}                                   ;
                sub_2_data_valid_o_temp = 1                                                                     ;
            end
            POST_SUB:
            begin
                sub_2_data_valid_o_temp = 0                                                                     ;
                sub_2_data_o_temp = 0                                                                           ;
            end    
            default:
            begin
                sub_2_data_valid_o_temp = 0                                                                     ;
                sub_2_data_o_temp = 0                                                                           ;
            end
        endcase
    end

    always @(posedge clock_i) 
    begin
        if (~reset_n_i)
            counter_sub_2_output_stream <= 0                                                                    ;
        else
            if (sub_2_current_state == POST_SUB && counter_sub_2_output_stream < sub_2_downscale_number_of_data_i && ~sub_2_downscale_number_of_data_i)
                counter_sub_2_output_stream <= counter_sub_2_output_stream + 1                                  ;
    end
    
    always @(posedge clock_i)
    begin
        if (~reset_n_i)
            sub_2_done_o_temp <= 0                                                                              ;
        else
            if (counter_sub_2_output_stream == sub_2_downscale_number_of_data_i - 1)
                sub_2_done_o_temp <= 1                                                                          ;
    end
endmodule