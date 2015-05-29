function SDRAM_Controller_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_sdram_controller ;

%---------------------------------------------------------------------------
%   Simulation Definitions.
%---------------------------------------------------------------------------

sysclk_freq_g           = 50.0e6 ;

StepsPerClock           = 4 ;

sim_steprate            = sysclk_freq_g * StepsPerClock ;

hold_time               = 10 ;


%---------------------------------------------------------------------------
%   SDRAM Memory Definitions.
%---------------------------------------------------------------------------

sdram_rowbits           = uint32 (16384) ;
sdram_rowcount          = uint32 (8192) ;
sdram_banks             = uint32 (4) ;
sdram_addrbits          = uint32 (14) ;
sdram_databits          = uint32 (16) ;
sdram_cmdbits           = uint32 (4) ;

sdram_colwords          = sdram_rowbits / sdram_databits ;
sdram_wordbytes         = sdram_databits / uint32 (8) ;

sdram_size              = sdram_banks * sdram_rowcount * sdram_colwords ;

sdram                   = zeros (1, sdram_size, 'uint16') ;

%---------------------------------------------------------------------------
%   Output Memory Definitions.
%---------------------------------------------------------------------------

outmem_buffrows_g       = uint32 (1) ;
outmem_buffcount_g      = uint32 (2) ;

outmem_buffwords        = outmem_buffrows_g * sdram_colwords ;

outmem_size             = outmem_buffcount_g * outmem_buffwords ;

outmem                  = zeros (1, outmem_size, 'uint16') ;

outmem_readrate         = 60000000 ;    % Bytes per second.


output_read_count       = fix (sim_steprate /                         ...
                               (outmem_readrate /                     ...
                                double ((outmem_buffwords *           ...
                                         sdram_wordbytes)))) ;


%---------------------------------------------------------------------------
%   Input Memory Definitions.
%---------------------------------------------------------------------------

inmem_buffouts_g        = uint32 (1) ;
inmem_buffcount_g       = uint32 (2) ;

inmem_buffwords         = inmem_buffouts_g * outmem_buffwords ;

inmem_size              = inmem_buffcount_g * inmem_buffwords ;

inmem                   = zeros (1, inmem_size, 'uint16') ;

inmem_writerate         = 2500000 ;     % Bytes per second.

input_write_count       = fix (sim_steprate /                         ...
                               (inmem_writerate /                     ...
                                double ((inmem_buffwords *            ...
                                         sdram_wordbytes)))) ;

force_empty_count       = input_write_count * 8 ;


%---------------------------------------------------------------------------
%   Define the input signals and other needed signal information.
%   The word width of the fixed point data type must match the
%   width of the std_logic_vector input.  Signals that are
%   std_logic have a width of 1.
%
%   Input signal vector information is:
%     [width in bits, fraction in bits, 0 - unsigned 1 - signed, value]
%   Output signal vector information is:
%     width in bits
%---------------------------------------------------------------------------

in_count                = 0 ;
out_count               = 0 ;

in_sig                  = zeros (1, 4) ;
out_sig                 = zeros (1, 1) ;

%   System is ready for operation.

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
ready_out               = out_count ;

%   Input Memory signals

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
inmem_buffready_in      = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [sdram_databits 0 0 0] ;
inmem_datafrom_in       = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = fix (log2 (double (inmem_size) - 1) + 1) ;
inmem_address_out       = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
inmem_read_en_out       = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
inmem_clk_out           = out_count ;

%   Output Memory signals

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
outmem_buffready_in     = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = sdram_databits ;
outmem_datato_out       = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = fix (log2 (double (outmem_size))) + 1 ;
outmem_address_out      = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
outmem_write_en_out     = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
outmem_clk_out          = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = fix (log2 (double (sdram_banks *            ...
                                             sdram_rowcount *         ...
                                             sdram_rowbits) / 8 - 1) + 1) ;
outmem_amt_out          = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
outmem_writing_out      = out_count ;

%   SDRAM Memory signals

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [sdram_databits 0 0 0] ;
sdram_data_in           = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = sdram_databits ;
sdram_data_out          = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
sdram_data_dir          = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = sdram_databits / 8 ;
sdram_mask_out          = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = sdram_addrbits ;
sdram_address_out       = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = fix (log2 (double (sdram_banks) - 1) + 1) ;
sdram_bank_out          = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = sdram_cmdbits ;
sdram_command_out       = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
sdram_clk_en_out        = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
sdram_clk_out           = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
sdram_empty_out         = out_count ;

%   Force the data to be written from SD Memory to Output Memory.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
sdram_forceout_in       = in_count ;

%---------------------------------------------------------------------------
%   SDRAM commands.
%---------------------------------------------------------------------------

sdcmd_noop              = uint8 (7) ;
sdcmd_active            = uint8 (3) ;
sdcmd_read              = uint8 (5) ;
sdcmd_write             = uint8 (4) ;
sdcmd_burse_term        = uint8 (6) ;
sdcmd_load_mode         = uint8 (0) ;


%---------------------------------------------------------------------------
%   Clock through the module.
%---------------------------------------------------------------------------


Trial_count             = 1 ;

for trialno=1:Trial_count

    %-----------------------------------------------------------------------
    %   Create our input vectors at each trial, which must be fixed-point
    %   data types.
    %-----------------------------------------------------------------------

    %   Initialize a trial.

    in_vect       = cell (1, in_count) ;
    out_vect      = cell (1, out_count) ;

    for i = 1 : in_count
      in_vect {i} = fi (in_sig (i, 4), in_sig (i, 3), in_sig (i, 1),  ...
                        in_sig (i, 2)) ;
    end

    %   Initial signal values.

    inmem_clk             = fi (0, 0, 1, 0) ;
    outmem_clk            = fi (0, 0, 1, 0) ;
    sdram_clk             = fi (0, 0, 1, 0) ;

    %   Initial operation values.

    burst_read            = false ;
    burst_write           = false ;

    burst_delay           = 0 ;
    burst_wait            = 0 ;

    input_number          = 0 ;
    input_count           = 0 ;
    inmem_buffready       = false ;
    inmem_buffready_last  = false ;
    inmem_buffnext        = 0 ;

    empty_count           = 0 ;
    sdram_forceout        = false ;
    sdram_forceout_last   = false ;

    output_number         = 0 ;
    output_count          = 0 ;
    outmem_buffready      = false ;
    outmem_buffready_last = false ;
    outmem_buffnext       = 0 ;
    outmem_reading        = false ;

    %   Execute the trial.

    output_done           = 4294967295 ;

    while (output_number < output_done)

      [out_vect{:}] = step (sim_hdl, in_vect {:}) ;

      sdram_ready         = uint8 (out_vect {ready_out}) ;

      if (~ sdram_ready)
        continue ;
      end

      %   Detect signal edges.

      inmem_clk_fwl       = inmem_clk ;
      outmem_clk_fwl      = outmem_clk ;
      sdram_clk_fwl       = sdram_clk ;

      inmem_clk           = out_vect {inmem_clk_out} ;
      outmem_clk          = out_vect {outmem_clk_out} ;
      sdram_clk           = out_vect {sdram_clk_out} ;

      inmem_clk_rising    = (inmem_clk_fwl ~= inmem_clk &&            ...
                             inmem_clk == uint8 (1)) ;
      outmem_clk_rising   = (outmem_clk_fwl ~= outmem_clk &&          ...
                             outmem_clk == uint8 (1)) ;
      sdram_clk_rising    = (sdram_clk_fwl ~= sdram_clk &&            ...
                             sdram_clk == uint8 (1)) ;

      %   Process SDRAM commands.

      sdram_command       = uint8 (out_vect {sdram_command_out}) ;

      if (sdram_clk_rising)

        %   Continue operation only if a NOP is received.  The burst delay
        %   value is one higher than the number of clocks needed between
        %   a read or write command and the first word access.

        if (sdram_command ~= sdcmd_noop)
          burst_delay     = 0 ;
        end

        %   Act on commands.

        switch (sdram_command)
          case sdcmd_active,
            row_address   = out_vect {sdram_address_out} ;

          case sdcmd_read,
            sdram_address = (out_vect {sdram_bank_out} *            ...
                             sdram_rowcount + row_address) *        ...
                             sdram_colwords +                       ...
                            mod (out_vect {sdram_address_out},      ...
                                 sdram_colwords) + uint8 (1) ;
            burst_read    = true ;
            burst_delay   = 4 ;
            burst_wait    = 0 ;

          case sdcmd_write,
            sdram_address = (out_vect {sdram_bank_out} *            ...
                             sdram_rowcount + row_address) *        ...
                             sdram_colwords +                       ...
                            mod (out_vect {sdram_address_out},      ...
                                 sdram_colwords) + uint8 (1) ;
            burst_write   = true ;
            burst_delay   = 1 ;
            burst_wait    = 0 ;
        end

        %   Update the delay counters.  While the wait counter is less than
        %   the delay count skip the clock cycles.  While the wait
        %   counter is greater than the delay count decrement it and carry
        %   out the operation until it has reached zero.

        if (burst_wait < burst_delay)
          burst_wait      = burst_wait + 1 ;
        elseif (burst_wait > burst_delay)
          burst_wait      = burst_wait - 1 ;

          if (burst_wait == 0)
            burst_read    = false ;
            burst_write   = false ;
          end
        end
      end

      %   The inmem datafrom is set from the address only when read enable
      %   is set on rising clock edge.

      inmem_read_en       = out_vect {inmem_read_en_out} ;

      if (inmem_clk_rising && inmem_read_en)

        inmem_address     = out_vect {inmem_address_out} + uint8 (1) ;

        in_sig (inmem_datafrom_in, 4) = inmem (inmem_address) ;
        in_vect {inmem_datafrom_in}   =                               ...
                          fi (in_sig (inmem_datafrom_in, 4),          ...
                              in_sig (inmem_datafrom_in, 3),          ...
                              in_sig (inmem_datafrom_in, 1),          ...
                              in_sig (inmem_datafrom_in, 2)) ;
      end

      %   The outmem datato is written to the address only when write enable
      %   is set on the rising clock edge.

      outmem_write_en     = out_vect {outmem_write_en_out} ;

      if (outmem_clk_rising && outmem_write_en)

        outmem_address    = out_vect {outmem_address_out} + uint8 (1) ;

        outmem (outmem_address) =                                     ...
                            uint16 (out_vect {outmem_datato_out}) ;
      end

      %   The sdram data_in is set from the address only during burst
      %   read commands on the rising clock edge.

      if (sdram_clk_rising && burst_read && burst_wait >= burst_delay)

        in_sig (sdram_data_in, 4) = sdram (sdram_address) ;
        in_vect {sdram_data_in}   =                                   ...
                          fi (in_sig (sdram_data_in, 4),              ...
                              in_sig (sdram_data_in, 3),              ...
                              in_sig (sdram_data_in, 1),              ...
                              in_sig (sdram_data_in, 2)) ;
        sdram_address     = sdram_address + uint8 (1) ;
      end

      %   The sdram data_out is written to memory only during burst write
      %   commands on the rising clock edge.

      sdram_mask          = out_vect {sdram_mask_out} ;

      if (sdram_clk_rising && burst_write &&                          ...
          burst_wait >= burst_delay && sdram_mask == 0)

        sdram (sdram_address)     = uint16 (out_vect {sdram_data_out}) ;
        sdram_address             = sdram_address + uint8 (1) ;
      end


      %   Periodicaly add a buffer of sequencial numbers to the input.

      input_count         = input_count + 1 ;

      if (input_count >= input_write_count)
        input_count       = 0 ;

        buff_start        = inmem_buffnext * inmem_buffwords ;

        for i = buff_start : 2 : buff_start + inmem_buffwords - 1
          input_number    = input_number + 1 ;

          inmem (i + 1)   =           bitand (input_number,      65535) ;
          inmem (i + 2)   = bitshift (bitand (input_number,           ...
                                              4294901760), -16) ;
        end

        inmem_buffready   = true ;
        inmem_buffnext    = inmem_buffnext + 1 ;

        if (inmem_buffnext >= inmem_buffcount_g)
          inmem_buffnext  = 0 ;
        end
      elseif (input_count == hold_time)
        inmem_buffready   = false ;
      end

      if (inmem_buffready_last ~= inmem_buffready)
        inmem_buffready_last            = inmem_buffready ;

        in_sig (inmem_buffready_in, 4)  = inmem_buffready ;
        in_vect {inmem_buffready_in}    =                             ...
                          fi (in_sig (inmem_buffready_in, 4),         ...
                              in_sig (inmem_buffready_in, 3),         ...
                              in_sig (inmem_buffready_in, 1),         ...
                              in_sig (inmem_buffready_in, 2)) ;
      end

      %   Periodicaly read a buffer from the output.

      outmem_writing      = out_vect {outmem_writing_out} ;

      if (~ outmem_reading && outmem_writing)

        outmem_reading    = true ;
        outmem_amount     = double (out_vect {outmem_amt_out}) ;
        outmem_amtread    = 0 ;
      end

      if (outmem_reading)
        output_count        = output_count + 1 ;

        if (output_count >= output_read_count)
          output_count      = 0 ;

          buff_start        = outmem_buffnext * outmem_buffwords ;

          for i = buff_start : 2 : buff_start + outmem_buffwords - 1
            output_number   = output_number + 1 ;
            stored_number   = bitshift (double (outmem (i + 2)), 16) +  ...
                              double (outmem (i + 1)) ;

            if (output_number ~= stored_number)
              fprintf (2,                                               ...
                  'mismatch at %08X: %9u (%08X) <> %9u (%08X)\n',       ...
                  i,                                                    ...
                  output_number, output_number,                         ...
                  stored_number, stored_number) ;
            end
          end

          outmem_buffready  = true ;
          outmem_buffnext   = outmem_buffnext + 1 ;

          if (outmem_buffnext >= outmem_buffcount_g)
            outmem_buffnext = 0 ;
          end

          outmem_amtread    = outmem_amtread + outmem_buffwords *       ...
                                               sdram_wordbytes ;

          fprintf (1, 'Output read %08X of %08X\n',                     ...
                   outmem_amtread, outmem_amount) ;

        elseif (output_count == hold_time)
          outmem_buffready    = false ;

          if (outmem_amtread >= outmem_amount)
            outmem_reading    = false ;
            output_count      = 0 ;
          end
        end
      end

      if (outmem_buffready_last ~= outmem_buffready)
        outmem_buffready_last           = outmem_buffready ;

        in_sig (outmem_buffready_in, 4) = outmem_buffready ;
        in_vect {outmem_buffready_in}   =                             ...
                          fi (in_sig (outmem_buffready_in, 4),        ...
                              in_sig (outmem_buffready_in, 3),        ...
                              in_sig (outmem_buffready_in, 1),        ...
                              in_sig (outmem_buffready_in, 2)) ;
      end

      %   Force output periodically.

      empty_count         = empty_count + 1 ;

      if (empty_count >= force_empty_count)
        empty_count       = 0 ;

        sdram_forceout    = true ;
      end

      sdram_empty         = out_vect {sdram_empty_out} ;

      if (sdram_forceout && sdram_empty)
        sdram_forceout    = false ;
      end

      if (sdram_forceout_last ~= sdram_forceout)
        sdram_forceout_last           = sdram_forceout ;

        in_sig (sdram_forceout_in, 4) = sdram_forceout ;
        in_vect {sdram_forceout_in}   =                               ...
                          fi (in_sig (sdram_forceout_in, 4),          ...
                              in_sig (sdram_forceout_in, 3),          ...
                              in_sig (sdram_forceout_in, 1),          ...
                              in_sig (sdram_forceout_in, 2)) ;
      end
    end
end
