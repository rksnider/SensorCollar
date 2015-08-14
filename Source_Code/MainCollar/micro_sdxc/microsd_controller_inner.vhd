----------------------------------------------------------------------------------------------------
--
-- Filename:           microsd_controller_inner.vhd
-- Description:        Source code for microsd serial data logger
-- Author:          Christopher Casebeer
-- Lab:                 Dr. Snider
-- Department:          Electrical and Computer Engineering
-- Institution:         Montana State University
-- Support:             This work was supported under NSF award No. DBI-1254309
-- Creation Date:      June 2014
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
--    This software is released under
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

------------------------------------------------------------------------------
--
--! @brief      microsd_controller_inner handles muxing microsd_data
--!             and microsd_init depending on which is active.
--! @details
--!
--! @param      CLK_DIVIDE      Divide value to take clk to ~400kHz for sd card
--!                             initialization.
--! @param      clk             Input clock, Data Component Logic Clk and Data Transmission Clock
--! @param      rst_n           Start signal from input pushbutton
--! @param      sd_init_start           Reset to initial conditions.
--! @param      sd_control              Used to select pathway in microsd_data.
--! @param      sd_status               Current State of State Machine.
--!
--! @param      block_byte_data         Read data from SD card memory
--! @param      block_byte_wren         Signals that a data byte has been read. Ram wr_en.
--! @param      block_read_sd_addr      Address to read block from on sd card.
--!
--! @param      block_byte_addr         Address to write read data to in ram.
--!
--! @param      block_write_sd_addr     Address where block is written on sd card.
--!
--! @param      block_write_data        Byte that will be written
--!
--! @param      num_blocks_to_write     Number of blocks to be written in CMD25.
--!
--!
--! @param      ram_read_address        Where block_write_data is read from.
--! @param      erase_start             Start address of erase.
--!
--! @param      erase_end               Stop address of erase.
--! @param      state_leds              Used to encode current state to Leds.
--! @param      prev_block_write_sd_addr        The last address to be successfully written valid on
--!                                             prev_block_write_sd_addr_pulse '1'
--!
--! @param      prev_block_write_sd_addr_pulse  prev_block_write_sd_addr is valid
--!
--! @param      cmd_write_en                    Tri State Enable
--! @param      D0_write_en         Tri State Enable
--! @param      D1_write_en         Tri State Enable
--! @param      D2_write_en         Tri State Enable
--! @param      D3_write_en         Tri State Enable
--!
--! @param      cmd_signal_in       Read value of the tri-stated line.
--! @param      D0_signal_in        Read value of the tri-stated line.
--! @param      D1_signal_in        Read value of the tri-stated line.
--! @param      D2_signal_in        Read value of the tri-stated line.
--! @param      D3_signal_in        Read value of the tri-stated line.
--!

--! @param      init_done           Card has passed init phase.
--! @param      signalling_18_en    Card should go into 1.8V mode during init.
--! @param      hs_sdr25_mode_en        Card should transition to hs_sdr25 mode before first CMD25.
--! @param      init_out_sclk_signal      400k init clocked out to voltage switching process.
--!
--! @param      dat0                dat0 line out
--! @param      dat1                dat1 line out
--! @param      dat2                dat2 line out
--! @param      dat3                dat3 line out
--! @param      cmd                 cmd line out
--! @param      sclk                clk sent to sd card
--!
--! @param      restart             Restart sd card because of repeated error
--!
--! @param      ext_trigger         External trigger bit. Used to trigger an Oscope if need arise.
--!
--
------------------------------------------------------------------------------


entity microsd_controller_inner is
    generic(

        CLK_DIVIDE              :natural;
        CLK_FREQ                :natural
);
    port(

        clk                      :in      std_logic;
        rst_n                    :in      std_logic;
        sd_init_start            :in      std_logic;


        sd_control              :in      std_logic_vector(7 downto 0);
        sd_status                :out  std_logic_vector(7 downto 0);


        block_byte_data          :out  std_logic_vector(7 downto 0);
        block_byte_wren          :out  std_logic;
        block_read_sd_addr      :in      std_logic_vector(31 downto 0);
        block_byte_addr          :out  std_logic_vector(8 downto 0) ;


        block_write_sd_addr      :in      std_logic_vector(31 downto 0);
        block_write_data        :in      std_logic_vector(7 downto 0);
        num_blocks_to_write      :in     integer range 0 to 2**16 - 1;
        ram_read_address        :out    std_logic_vector(8 downto 0);

        erase_start              :in   std_logic_vector(31 downto 0);
        erase_end                :in   std_logic_vector(31 downto 0);

        state_leds              :out  std_logic_vector(3 downto 0);

        prev_block_write_sd_addr       :out  std_logic_vector(31 downto 0);
        prev_block_write_sd_addr_pulse      :out  std_logic;

        cmd_write_en            :out    std_logic;
        D0_write_en              :out    std_logic;
        D1_write_en              :out    std_logic;
        D2_write_en              :out    std_logic;
        D3_write_en              :out    std_logic;

        cmd_signal_in            :in   std_logic;
        D0_signal_in            :in      std_logic;
        D1_signal_in            :in      std_logic;
        D2_signal_in            :in      std_logic;
        D3_signal_in            :in      std_logic;


        init_done                :out    std_logic;
        signalling_18_en        :in     std_logic;
        hs_sdr25_mode_en        :in     std_logic;

        vc_18_on                :out    std_logic;
        vc_33_on                :out    std_logic;

        --init_out_sclk_signal    :out    std_logic;

    --SD Signals
        dat0                  :out  std_logic;
        dat1                  :out  std_logic;
        dat2                  :out  std_logic;
        dat3                  :out  std_logic;
        cmd                    :out  std_logic;
        sclk                  :out  std_logic;

        restart               :out    std_logic;


        ext_trigger            :out     std_logic

);
end microsd_controller_inner;

--! microsd_controller inner simply muxes microsd_init and microsd_data
--! control lines and signals.  It also generates the 400k init clock.
--!
--!

architecture Behavioral of microsd_controller_inner is


component microsd_init
  generic(

        CLK_DIVIDE                  :natural;
        CLK_FREQ                    :natural
    );
    port(
        clk                :in      std_logic;
        rst_n             :in      std_logic;
        sd_init_start      :in      std_logic;
        dat0               :out    std_logic;
        cmd               :out    std_logic;
        sclk               :out    std_logic;
        dat3               :out    std_logic;
        D0_signal_in      :in    std_logic;
        init_done          :out  std_logic;
        signalling_18_en  :in   std_logic;
        cmd_write_en      :out   std_logic;
        D3_write_en        :out  std_logic;
        cmd_signal_in      :in    std_logic;
        vc_18_on          :out  std_logic;
        vc_33_on          :out  std_logic;
        rca_out            :out  std_logic_vector(15 downto 0);
        restart           :out  std_logic;
        state_leds        :out  std_logic_vector(3 downto 0);
        ext_trigger       :out  std_logic
);
end component;

component microsd_data is
  generic(
        CLK_DIVIDE              :natural;
        CLK_FREQ                :natural
    );
  port(

        clk                      :in      std_logic;
        rst_n                    :in      std_logic;



        sd_control              :in      std_logic_vector(7 downto 0);
        sd_status                :out  std_logic_vector(7 downto 0);



        block_byte_data          :out  std_logic_vector(7 downto 0);
        block_byte_wren          :out  std_logic;
        block_read_sd_addr      :in      std_logic_vector(31 downto 0);
        block_byte_addr          :out  std_logic_vector(8 downto 0) ;


        block_write_sd_addr                :in      std_logic_vector(31 downto 0);
        block_write_data                  :in      std_logic_vector(7 downto 0);
        num_blocks_to_write                :in     integer range 0 to 2**16 - 1;
        ram_read_address                  :out    std_logic_vector(8 downto 0);

        erase_start              :in   std_logic_vector(31 downto 0);
        erase_end                :in   std_logic_vector(31 downto 0);

        state_leds              :out  std_logic_vector(3 downto 0);

        prev_block_write_sd_addr       :out  std_logic_vector(31 downto 0);
        prev_block_write_sd_addr_pulse      :out  std_logic;

        cmd_write_en              :out    std_logic;
        D0_write_en                :out    std_logic;
        D1_write_en                :out    std_logic;
        D2_write_en                :out    std_logic;
        D3_write_en                :out    std_logic;

        cmd_signal_in              :in     std_logic;
        D0_signal_in              :in      std_logic;
        D1_signal_in              :in      std_logic;
        D2_signal_in              :in      std_logic;
        D3_signal_in              :in      std_logic;

        card_rca                   :in      std_logic_vector(15 downto 0);


        init_done                  :in    std_logic;

        hs_sdr25_mode_en          :in   std_logic;



    --SD Signals
        dat0                  :out  std_logic;
        dat1                  :out  std_logic;
        dat2                  :out  std_logic;
        dat3                  :out  std_logic;
        cmd                    :out  std_logic;
        sclk                  :out  std_logic;

        restart               :out  std_logic;
        data_send_crc_error   :out  std_logic;

        ext_trigger            :out  std_logic

    );
end component;


-----------------------
--Signal Declarations--
-----------------------

-- Input Signals
signal sd_init_start_signal    :std_logic;

-- Clock Signals
signal clk_400k_signal        :std_logic;
signal clk_400k_count          :integer range 0 to 2**9 - 1;

-- SD_INIT  Signals
signal init_dat0_signal        :std_logic;
signal  init_cmd_signal        :std_logic;
signal  init_sclk_signal      :std_logic;
signal  init_dat3_signal      :std_logic;
signal   init_done_signal      :std_logic;
signal   init_state_leds_signal    :std_logic_vector(3 downto 0);
signal  cmd_write_en_init      :std_logic;
signal  D3_write_en_init      :std_logic;
signal  init_restart          :std_logic;
signal  ext_trigger_init      :std_logic;

-- SD_DATA Signals
signal  data_cmd_signal        :std_logic;
signal  data_sclk_signal      :std_logic;
signal  data_dat3_signal      :std_logic;
signal  data_state_leds_signal    :std_logic_vector(3 downto 0);
signal   data_dat0_signal      :std_logic;
signal  cmd_write_en_data      :std_logic;
signal  D3_write_en_data      :std_logic;
signal  card_rca_signal        :std_logic_vector(15 downto 0);
signal  data_restart          :std_logic;
signal  ext_trigger_data      :std_logic;

signal  div_clk                :std_logic;
signal  div_clk_count          :unsigned(7 downto 0);

attribute keep                 : boolean ;

attribute keep of clk_400k_signal   : signal is true ;

begin

sd_init_start_signal <= sd_init_start;

init_done <= init_done_signal;

i_sd_init_0:  microsd_init
generic map(

CLK_DIVIDE              => CLK_DIVIDE,
CLK_FREQ                => CLK_FREQ
)
port map(
    clk                  => clk_400k_signal,
    rst_n               => rst_n,
    sd_init_start       => sd_init_start_signal,
    dat0                 => init_dat0_signal,
    cmd                 => init_cmd_signal,
    sclk                 => init_sclk_signal,
    dat3                 => init_dat3_signal,
    D0_signal_in        => D0_signal_in,
    init_done            => init_done_signal,
    signalling_18_en    => signalling_18_en,
    cmd_write_en        => cmd_write_en_init,
    D3_write_en          => D3_write_en_init,
    cmd_signal_in       => cmd_signal_in,
    state_leds          => init_state_leds_signal,
    ext_trigger          => ext_trigger_init,
    vc_18_on            => vc_18_on,
    vc_33_on            => vc_33_on,
    restart             => init_restart,
    rca_out             => card_rca_signal
    );

i_sd_data_0:  microsd_data
generic map(

CLK_DIVIDE            => CLK_DIVIDE,
CLK_FREQ              => CLK_FREQ
)
port map(
    clk                =>  clk,
    --clk               =>  div_clk,
    rst_n             =>  rst_n,
    dat0               =>  data_dat0_signal,
    cmd               =>  data_cmd_signal,
    sclk               =>  data_sclk_signal,
    dat3               =>  data_dat3_signal,
    dat1              =>  dat1,
    dat2              =>  dat2,
    cmd_write_en       =>  cmd_write_en_data,
    cmd_signal_in     =>  cmd_signal_in,
    D0_write_en       =>  D0_write_en,
    D1_write_en       =>  D1_write_en,
    D2_write_en       =>  D2_write_en,
    D3_write_en       =>  D3_write_en_data,
    D0_signal_in      =>  D0_signal_in,
    D1_signal_in      =>  D1_signal_in,
    D2_signal_in      =>  D2_signal_in,
    D3_signal_in      =>  D3_signal_in,
    card_rca          =>  card_rca_signal,
    init_done          =>  init_done_signal,
    block_read_sd_addr          =>  block_read_sd_addr,

    block_byte_data              =>  block_byte_data,
    block_byte_wren              =>  block_byte_wren,
    block_byte_addr              =>  block_byte_addr,


    prev_block_write_sd_addr     =>  prev_block_write_sd_addr,
    prev_block_write_sd_addr_pulse  =>  prev_block_write_sd_addr_pulse ,

    hs_sdr25_mode_en            =>  hs_sdr25_mode_en,

    block_write_sd_addr          =>  block_write_sd_addr,
    block_write_data            =>  block_write_data,

    sd_control                  =>  sd_control,
    sd_status                    =>  sd_status,
    state_leds                  =>  data_state_leds_signal,
    num_blocks_to_write          =>  num_blocks_to_write,
    erase_start                  =>  erase_start,
    ram_read_address            =>  ram_read_address,
    restart                     =>  data_restart,

    ext_trigger                  =>  ext_trigger_data  ,
    erase_end                    =>  erase_end
    );



  with init_done_signal select
      sclk    <=  data_sclk_signal when '1',
            init_sclk_signal when others;

  with init_done_signal select
      cmd     <=  data_cmd_signal when '1',
            init_cmd_signal when others;

  with init_done_signal select
      dat0    <=  data_dat0_signal when '1',
            init_dat0_signal when others;

  with init_done_signal select
      dat3    <=  data_dat3_signal when '1',
            init_dat3_signal when others;

  with init_done_signal select
      state_leds  <=  data_state_leds_signal when '1',
                init_state_leds_signal when others;

  with init_done_signal select
      cmd_write_en    <=  cmd_write_en_data when '1',
                  cmd_write_en_init when others;


  with init_done_signal select
      D3_write_en    <=  D3_write_en_data when '1',
                  D3_write_en_init when others;

    with init_done_signal select
      restart     <=      data_restart when '1',
                  init_restart when others;

    with init_done_signal select
      ext_trigger     <=      ext_trigger_data when '1',
                  ext_trigger_init when others;



  --Generate the 400k clock using the CLK_DIVIDE generic.
process(rst_n,clk)
begin
if (rst_n = '0') then

  clk_400k_signal <= '0';
  clk_400k_count <= 0;

elsif rising_edge(clk) then
        --Divides by count = (count+1)*2.

        --50 Mhz --> (CLK_DIVIDE(128)/2 - 1) + 1 * 2.
        --128/2 -1 == 63. + 1 == 64. * 2 == 128. 50Mhz/128 = .3906MHZ.

        if(clk_400k_count = CLK_DIVIDE/2 - 1) then
            clk_400k_signal <= not clk_400k_signal;
            clk_400k_count <= 0;
        elsif(init_done_signal = '1') then
            clk_400k_signal <= '0';
            clk_400k_count <= 0;
        else
            clk_400k_count <= clk_400k_count + 1;
        end if;
    end if;
end process;





end Behavioral;

