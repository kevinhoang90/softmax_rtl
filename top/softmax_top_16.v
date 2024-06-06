/*
=====================================================================================
=                                                                                   =
=   Author: Hoang Van Quyen - UET - VNU                                             =
=                                                                                   =
=====================================================================================
*/
module softmax_top_16
#(
    parameter                           data_size = 16
)
(
    input                               axi_clock_i                                                             ,
    input                               axi_reset_n_i                                                           ,
    //slave axi4 stream
    input                               s_axis_valid_i                                                          ,
    input                               s_axis_last_i                                                           ,
    input           [2*data_size - 1:0] s_axis_data_i                                                           ,
    output                              s_axis_ready_o                                                          ,

    //master axi4 stream
    input                               m_axis_ready_i                                                          ,
    output          [2*data_size - 1:0] m_axis_data_o                                                           ,
    output                              m_axis_valid_o                                                          ,
    output                              m_axis_last_o
    
);
    //internal downscale
    wire                                downscale_data_valid_o                                                  ;
    wire            [data_size - 1:0]   downscale_data_o                                                        ;
    wire            [7:0]               downscale_number_of_data_o                                              ;                    

    wire            [data_size - 1:0]   exp_1_data_o                                                            ;
    wire                                exp_1_done_signal_o                                                     ;
    wire                                exp_1_data_valid_o                                                      ;
    
    wire            [data_size - 1:0]   adder_data_o                                                            ;
    wire                                adder_data_valid_o                                                      ;

    wire            [data_size - 1:0]   ln_data_o                                                               ;
    wire                                ln_data_valid_o                                                         ;


    wire            [data_size - 1:0]   sub_2_data_o                                                            ;
    wire                                sub_2_data_valid_o                                                      ;
    wire                                sub_2_done_o                                                            ;
    
    downscale_block_16 #(data_size) downscale(
        //input
        .clock_i(axi_clock_i)                                                                                   ,
        .reset_n_i(axi_reset_n_i)                                                                               ,
        .s_axis_valid_i(s_axis_valid_i)                                                                         ,
        .s_axis_data_i(s_axis_data_i)                                                                           ,
        .s_axis_last_i(s_axis_last_i)                                                                           ,
        .s_axis_ready_o(s_axis_ready_o)                                                                         ,
        //output
        .downscale_data_valid_o(downscale_data_valid_o)                                                         ,
        .downscale_number_of_data_o(downscale_number_of_data_o)                                                 ,
        .downscale_data_o(downscale_data_o)
    );

    exp_1_block_16 #(data_size) exp_1(
        //input
        .clock_i(axi_clock_i)                                                                                   ,
        .reset_n_i(axi_reset_n_i)                                                                               ,
        .exp_data_i(downscale_data_o)                                                                           ,
        .exp_data_valid_i(downscale_data_valid_o)                                                               ,
        //output
        .exp_done_o(exp_1_done_signal_o)                                                                        ,
        .exp_data_valid_o(exp_1_data_valid_o)                                                                   ,
        .exp_data_o(exp_1_data_o)
    );
    
    adder_block_16 #(data_size) adder_16(
        .clock_i(axi_clock_i)                                                                                   ,
        .reset_n_i(axi_reset_n_i)                                                                               ,
        .adder_data_i(exp_1_data_o)                                                                             ,
        .adder_data_valid_i(exp_1_data_valid_o)                                                                 ,
        .exp_done_i(exp_1_done_signal_o)                                                                        ,
        
        .adder_data_o(adder_data_o)                                                                             ,
        .adder_data_valid_o(adder_data_valid_o) 
    );

    ln_block_16 #(data_size) ln_16(
        .clock_i(axi_clock_i)                                                                                   ,
        .reset_n_i(axi_reset_n_i)                                                                               ,
        .ln_data_i(adder_data_o)                                                                                ,
        .ln_data_valid_i(adder_data_valid_o)                                                                    ,

        .ln_data_o(ln_data_o)                                                                                   ,
        .ln_data_valid_o(ln_data_valid_o)
    );

    sub_2_block_16 #(data_size) sub_2_16(
        .clock_i(axi_clock_i)                                                                                   ,
        .reset_n_i(axi_reset_n_i)                                                                               ,
        .sub_2_ln_data_i(ln_data_o)                                                                             ,
        .sub_2_ln_data_valid_i(ln_data_valid_o)                                                                 ,
        .sub_2_downscale_data_i(downscale_data_o)                                                               ,
        .sub_2_downscale_data_valid_i(downscale_data_valid_o)                                                   ,
        .sub_2_downscale_number_of_data_i(downscale_number_of_data_o)                                           ,
        
        .sub_2_done_o(sub_2_done_o)                                                                             ,
        .sub_2_data_o(sub_2_data_o)                                                                             ,
        .sub_2_data_valid_o(sub_2_data_valid_o)
    );

     exp_2_block_16 #(data_size) exp_2(
        //input
        .clock_i(axi_clock_i)                                                                                   ,
        .reset_n_i(axi_reset_n_i)                                                                               ,
        .exp_data_i(sub_2_data_o)                                                                               ,
        .exp_data_valid_i(sub_2_data_valid_o)                                                                   ,
        .exp_sub_2_done_i(sub_2_done_o)                                                                         ,
        .m_axis_ready_i(m_axis_ready_i)                                                                         ,
        //output
        .m_axis_last_o(m_axis_last_o)                                                                           ,
        .m_axis_valid_o(m_axis_valid_o)                                                                         ,
        .m_axis_data_o(m_axis_data_o)
    );
endmodule