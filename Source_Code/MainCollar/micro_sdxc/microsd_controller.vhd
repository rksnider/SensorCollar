----------------------------------------------------------------------------------------------------
--
-- Filename:     	    microsd_controller.vhd
-- Description:  	    Source code for microsd serial data logger
-- Author:			      Christopher Casebeer
-- Lab:               Dr. Snider
-- Department:        Electrical and Computer Engineering
-- Institution:       Montana State University
-- Support:           This work was supported under NSF award No. DBI-1254309
-- Creation Date:	    June 2014	
--		
-----------------------------------------------------------------------------------------------------
--
-- Version 1.0
--
-----------------------------------------------------------------------------------------------------
--
-- Modification Hisory (give date, author, description)
--
-- None
--
-- Please send bug reports and enhancement requests to Dr. Snider at rksnider@ece.montana.edu
--
-----------------------------------------------------------------------------------------------------
--
--	  This software is released under
--            
--    The MIT License (MIT)
--
--    Copyright (C) 2014  Christopher C. Casebeer and Ross K. Snider
--
--    Permission is hereby granted, free of charge, to any person obtaining a copy
--    of this software and associated documentation files (the "Software"), to deal
--    in the Software without restriction, including without limitation the rights
--    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--    copies of the Software, and to permit persons to whom the Software is
--    furnished to do so, subject to the following conditions:
--
--    The above copyright notice and this permission notice shall be included in
--    all copies or substantial portions of the Software.
--
--    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--    THE SOFTWARE.
--
--    Christopher Casebeer
--    Electrical and Computer Engineering
--    Montana State University
--    541 Cobleigh Hall
--    Bozeman, MT 59717
--    christopher.casebee1@msu.montana.edu
--
--    Ross K. Snider
--    Associate Professor
--    Electrical and Computer Engineering
--    Montana State University
--    538 Cobleigh Hall
--    Bozeman, MT 59717
--    rksnider@ece.montana.edu
--
--    Information on the MIT license can be found at http://opensource.org/licenses/MIT
--
-----------------------------------------------------------------------------------------------------


--The DOxygen system of commenting has been used for effecient documentation.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL ; 

--Library used for dual port ram.
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;


------------------------------------------------------------------------------
--
--! @brief      microsd_controller is the top component of the serial logging design.
--! @details    
--!
--! @param      CLK_FREQ            Frequency of the input clk. Used to generate
--!                                 new clocks and timeout values.
--! @param      buf_size_g          Number of bytes in the buffer. Must be specified as N * 512 bytes. 
--!
--! @param      buf_size_g          Size of microsd_controller internal buffer, bytes.
--! @param      block_size_g        Size of a sd card block. Minimal addressable data size.
--!  
--! @param      HS_SDR25_MODE       When operating clk @ 25Mhz or below, set '0'. @ above 25Mhz  set to '1'.
--!
--! @param      CLK_DIVIDE          The sd card init clock should be close to 400k. 
--!                                 Specify this number to divide the 
--!                                 provided data clock to an ~400k init clock. 
--! @param      signalling_18_en    Set this bit to either attempt to change initialization to 
--!                                 switch into 1.8V signalling mode. This requires a differet ACMD41 in init
--!                                 as well as control of a level shifter in use with the lines of the sdcard.  
--!
--! @param      rst_n               Reset will cause the card to reinitialize immediately back 
--!                                 to the waiting for data state.
--!
--! @param      clk                 Data Transmission Clock. Clock can be from 400kHz 
--!                                 to 50MHz depending on timing of target device.
--! @param      clock_enable        Disable the component. The component will finish 
--!                                 its current write if writing, and then gate its clock.

--! @param      data_input          Data presented a byte at a time.   
--!                                 This is written into the component's buffer. 
--!                               
--! @param      data_we             Data is clocked into the internal buffer on the rising edge.
--!                                 Host should control this clock appropriately. 
--!                              
--! @param      data_full           Buffer is full. Stop sending data.
--!
--! @param      data_sd_start_address       The beginning block address on the card 
--!                                         the sent data should be written.
--!                              
--! @param      data_nblocks        The number of blocks the host intends 
--!                                 to send to component and write to SD card.
--!                              
--!
--! @param      data_current_block_written      This is the sd block address which 
--!                                             was last written successfully. It passed CRC response check.
--! @param      sd_block_written_flag           This flag is pulsed on successful block write.   
--!                                             data_current_block_written is valid.       
--!
--! @param      sd_clk              sd_clk wired to IO bank.          
--! @param      sd_cmd              sd_cmd wired to IO bank.      
--! @param      sd_dat              sd_dat wired to IO bank.  
--! 
--! @param      V_3_3_ON_OFF        Wired to 3.3 switch on/off control. 
--!                                 Output of switch goes to level translator 
--!                                 sd card side bank control.
--! @param      V_1_8_ON_OFF        Wired to 1.8 switch on/off control. 
--!                                 Output of switch goes to level translator 
--!                                 sd card side bank control.
--! @param      init_start          Start the init process.
--! @param      user_led_n_out      Data FSM encoding used for LEDs. 
--
------------------------------------------------------------------------------





entity microsd_controller is
 generic(
    
    CLK_FREQ                :natural    := 50E6;
    buf_size_g              :natural    := 2048;     
    block_size_g            :natural    := 512;    
		HS_SDR25_MODE						:std_logic  := '1';                  
    CLK_DIVIDE              :natural    := 128;
    signalling_18_en				:std_logic  := '1'  
    );

    port(

    rst_n                               :in      std_logic;                                     
    clk                                 :in      std_logic;                                     
    clock_enable                        :in      std_logic;                                     
    


    data_input                          :in      std_logic_vector(7 downto 0);                  
   -- data_clk                            :in      std_logic;
    data_we                             :in      std_logic;
    data_full                           :out     std_logic;                                     


    
    data_sd_start_address               :in      std_logic_vector(31 downto 0);                 
    data_nblocks                        :in      std_logic_vector(31 downto 0);                 
                       

                      
    data_current_block_written          :out     std_logic_vector(31 downto 0);                 
    sd_block_written_flag               :out     std_logic; 
    buffer_level                        :out     std_logic_vector (natural(trunc(log2(real(buf_size_g/block_size_g)))) downto 0); 

 
		sd_clk                         	    :out     std_logic;                                                                      
       
		sd_cmd                              :inout   std_logic;                                                            
    sd_dat                        		  :inout   std_logic_vector(3 downto 0);                  


        
    V_3_3_ON_OFF                        :out     std_logic;                                     
    V_1_8_ON_OFF                        :out     std_logic;                                     
    
    
    --Personal Debug for now
    
    init_start                          :in     std_logic;                                  
    user_led_n_out                      :out    std_logic_vector(3 downto 0);
    ext_trigger                         :out    std_logic

	);
end microsd_controller;


--!A chunk of data of N blocks (a block is 512 bytes) is signalled to to be written through use of data_nblocks.
--!The card expects the N blocks to flow through its internal buffer. The component should be presented with 
--!data only on the rising edge of mem_clk and not when data_full is '1';
--!The number of blocks to be written to the card will be written starting at sd card block 
--!address data_sd_start_address. data_nblocks represents the number of blocks (512 bytes each) which
--!will be sent to the component's buffers and written to the sd card starting at 
--!data_sd_start_address. The component will reset its buffers after it has written data_nblocks blocks. 
--!The component signals with the sd_block_written_flag pulse that the last block written at data_current_block_written 
--!address was successful. The bidirectional lines are tri-states internally. 
--!sd_cmd and sd_dat thus must be inout to top entity and tied to bidirectional pins.
--!By default the card will transmit data at 3.3V signalling level. To achieve a 1.8V signalling level a 
--!level translator must be present between the FPGA GPIO and the sd card. The outputs of the switches 
--!are tied together and routed to the voltage reference port of the level translator. 
--!The component will handle the switching of the sd card side supply voltage pin 
--!of the level translator. An internal signal of the design can also be changed easily to run  the card in 
--!3.3V mode if so desired.

architecture rtl of microsd_controller is
		
  component microsd_controller_dir is
   generic(

      CLK_FREQ                :natural    := 50E6;
      buf_size_g              :natural    := 2048;
      block_size_g            :natural    := 512;
      HS_SDR25_MODE           :std_logic  := '1';
      CLK_DIVIDE              :natural    := 128;
      signalling_18_en        :std_logic  := '1'
      );

      port(

      rst_n                               :in      std_logic;
      clk                                 :in      std_logic;
      clock_enable                        :in      std_logic;



      data_input                          :in      std_logic_vector(7 downto 0);
     -- data_clk                            :in      std_logic;
      data_we                             :in      std_logic;
      data_full                           :out     std_logic;



      data_sd_start_address               :in      std_logic_vector(31 downto 0);
      data_nblocks                        :in      std_logic_vector(31 downto 0);



      data_current_block_written          :out     std_logic_vector(31 downto 0);
      sd_block_written_flag               :out     std_logic;
      buffer_level                        :out     std_logic_vector (natural(trunc(log2(real(buf_size_g/block_size_g)))) downto 0);


      sd_clk                               :out     std_logic;

      sd_cmd_in                           : in      std_logic ;
      sd_cmd_out                          : out     std_logic ;
      sd_cmd_dir                          : out     std_logic ;
      sd_dat_in                           : in      std_logic_vector (3 downto 0) ;
      sd_dat_out                          : out     std_logic_vector (3 downto 0) ;
      sd_dat_dir                          : out     std_logic_vector (3 downto 0) ;


      V_3_3_ON_OFF                        :out     std_logic;
      V_1_8_ON_OFF                        :out     std_logic;


      --Personal Debug for now

      init_start                          :in     std_logic;
      user_led_n_out                      :out    std_logic_vector(3 downto 0);
      ext_trigger                         :out    std_logic

    );
  end component microsd_controller_dir;

  --  Translation signals.
  
  signal sd_cmd_in_tr             : std_logic ;
  signal sd_cmd_out_tr            : std_logic ;
  signal sd_cmd_dir_tr            : std_logic ;
  signal sd_dat_in_tr             : std_logic_vector (sd_dat'length-1
                                                      downto 0) ;
  signal sd_dat_out_tr            : std_logic_vector (sd_dat'length-1
                                                      downto 0) ;
  signal sd_dat_dir_tr            : std_logic_vector (sd_dat'length-1
                                                      downto 0) ;
  
begin

  mc : microsd_controller_dir
   generic map (
      CLK_FREQ                    => CLK_FREQ,
      buf_size_g                  => buf_size_g,
      block_size_g                => block_size_g,
      HS_SDR25_MODE               => HS_SDR25_MODE,
      CLK_DIVIDE                  => CLK_DIVIDE,
      signalling_18_en            => signalling_18_en
    )
    port map (
      rst_n                       => rst_n,
      clk                         => clk,
      clock_enable                => clock_enable,
      data_input                  => data_input,
      data_we                     => data_we,
      data_full                   => data_full,
      data_sd_start_address       => data_sd_start_address,
      data_nblocks                => data_nblocks,
      data_current_block_written  => data_current_block_written,
      sd_block_written_flag       => sd_block_written_flag,
      buffer_level                => buffer_level,
      sd_clk                      => sd_clk,
      sd_cmd_in                   => sd_cmd_in_tr,
      sd_cmd_out                  => sd_cmd_out_tr,
      sd_cmd_dir                  => sd_cmd_dir_tr,
      sd_dat_in                   => sd_dat_in_tr,
      sd_dat_out                  => sd_dat_out_tr,
      sd_dat_dir                  => sd_dat_dir_tr,
      V_3_3_ON_OFF                => V_3_3_ON_OFF,
      V_1_8_ON_OFF                => V_1_8_ON_OFF,
      init_start                  => init_start,
      user_led_n_out              => user_led_n_out,
      ext_trigger                 => ext_trigger
    );

  --  Translate in/out signals to and from directed signals.
  
  sd_cmd_in_tr      <= sd_cmd ;
  sd_dat_in_tr      <= sd_dat ;
  
  sd_cmd            <= sd_cmd_out when (sd_cmd_dir = '1') else 'Z' ;
  
  tr_dat :
    for i in (sd_dat'length-1 downto 0) generate
      sd_dat (i)    <= sd_dat_out (i) when (sd_dat_dir (i) = '1') else 'Z' ;
    end generate tr_dat ;

end rtl;
