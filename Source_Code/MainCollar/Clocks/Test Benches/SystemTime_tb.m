function SystemTime_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_systemtime ;

%---------------------------------------------------------------------------
%   Entity Definitions
%---------------------------------------------------------------------------

clk_freq_g              = 50.0e3 ;
gpsmem_addrbits_g       = 10 ;
gpsmem_databits_g       = 8 ;

gps_time_bytes_c        = 9 ;
gps_time_nanobits_c     = 20 ;
gps_time_millibits_c    = 30 ;
gps_time_weekbits_c     = 16 ;
gps_time_bits_c         = gps_time_nanobits_c + gps_time_millibits_c +  ...
                          gps_time_weekbits_c ;

epoch70_secbits_c       = 32 ;
dt_totalbits_c          = 31 ;

week_seconds_c          = 7 * 24 * 60 * 60 ;
gps_epoch70_offset_c    = (365 * 10 + 2 + 5) * 86400 ;

dt_yearbits_c           = 5 ;
dt_monthbits_c          = 4 ;
dt_mdaybits_c           = 5 ;
dt_hourbits_c           = 5 ;
dt_minbits_c            = 6 ;
dt_secbits_c            = 6 ;

dt_totalbits_c          = dt_yearbits_c + dt_monthbits_c +              ...
                          dt_mdaybits_c + dt_hourbits_c  +              ...
                          dt_minbits_c  + dt_secbits_c     ;

%---------------------------------------------------------------------------
%   Simulation Definitions.
%---------------------------------------------------------------------------

StepsPerClock           = 2 ;

sim_steprate            = clk_freq_g * StepsPerClock ;

hold_time               = 10 ;

timezone                = -6 ;    % MDT

cur_time                = (now - datenum (1970, 1, 1, 0, 0, 0)) *       ...
                           86400 - timezone * 3600 ;

cur_second              = uint32 (fix (cur_time)) ;

%   Time Mark values.

gps_time                = cur_time - gps_epoch70_offset_c ;
gps_week                = uint32 (fix (gps_time / week_seconds_c)) ;
gps_milli               = uint32 (fix ((gps_time - double (gps_week) *  ...
                                                   week_seconds_c) * 1000)) ;
gps_nano                = uint32 (581463) ;

sample_week             = uint32 (0) ;
sample_milli            = uint32 (2 * 60 * 1000 + 17 * 1000 + 857) ;
sample_nano             = uint32 (784911) ;

%---------------------------------------------------------------------------
%   GPS Memory Definitions
%---------------------------------------------------------------------------

gpsmem_size                   = 1024 ;
gpsmem                        = zeros (1, gpsmem_size, 'uint8') ;

msg_ram_banks_c               = 2 ;
msg_ram_base_c                = 59 ;

msg_ram_temp_addr_c           = 45 * msg_ram_banks_c ;
msg_ram_temp_size_c           = 30 ;

msg_ram_postime_addr_c        =                                         ...
      msg_ram_temp_addr_c + msg_ram_temp_size_c * msg_ram_banks_c ;
msg_ram_postime_size_c        = gps_time_bytes_c ;

msg_ram_marktime_addr_c       =                                         ...
      msg_ram_postime_addr_c + msg_ram_postime_size_c * msg_ram_banks_c ;
msg_ram_marktime_size_c       = gps_time_bytes_c ;

msg_ubx_tim_tm2_ramaddr_c     = 30 * msg_ram_banks_c ;
msg_ubx_tim_tm2_ramused_c     = 15 ;

MUTTm2_wnF_size_c             = 2 ;
MUTTm2_wnF_offset_c           = 1 ;

MUTTm2_towMsF_size_c          = 4 ;
MUTTm2_towMsF_offset_c        = 3 ;

MUTTm2_towSubMsF_size_c       = 4 ;
MUTTm2_towSubMsF_offset_c     = 7 ;

%   Set the Timemark values in the RAM.

memsize = MUTTm2_wnF_size_c ;
memaddr = msg_ram_base_c + msg_ubx_tim_tm2_ramaddr_c +                  ...
          msg_ubx_tim_tm2_ramused_c + MUTTm2_wnF_offset_c + 1 ;
memend  = memaddr + memsize - 1 ;

gpsmem (memaddr : memend) = uint8 (byte_store (gps_week, memsize)) ;

memsize = MUTTm2_towMsF_size_c ;
memaddr = msg_ram_base_c + msg_ubx_tim_tm2_ramaddr_c +                  ...
          msg_ubx_tim_tm2_ramused_c + MUTTm2_towMsF_offset_c + 1 ;
memend  = memaddr + memsize - 1 ;

gpsmem (memaddr : memend) = uint8 (byte_store (gps_milli, memsize)) ;

memsize = MUTTm2_towSubMsF_size_c ;
memaddr = msg_ram_base_c + msg_ubx_tim_tm2_ramaddr_c +                  ...
          msg_ubx_tim_tm2_ramused_c + MUTTm2_towSubMsF_offset_c + 1 ;
memend  = memaddr + memsize - 1 ;

gpsmem (memaddr : memend) = uint8 (byte_store (gps_nano, memsize)) ;

%   Sample time in GPS_time binary format.

bits   = gps_time_bytes_c * 8 ;

sample = bitshift (fi (sample_week,  0, bits, 0),                       ...
                   gps_time_millibits_c + gps_time_nanobits_c) +        ...
         bitshift (fi (sample_milli, 0, bits, 0),                       ...
                   gps_time_nanobits_c) + fi (sample_nano,  0, bits, 0) ;

memsize = msg_ram_marktime_size_c ;
memaddr = msg_ram_base_c + msg_ram_marktime_addr_c +                    ...
          msg_ram_marktime_size_c + 1 ;
memend  = memaddr + memsize - 1 ;

gpsmem (memaddr : memend) = uint8 (byte_store (sample, memsize)) ;

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

%   Output Times.

out_count               = out_count + 1 ;
out_sig (out_count)     = gps_time_bits_c ;
startup_time_out        = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = gps_time_bits_c ;
gps_time_out            = out_count ;

%   Real Time Clock interface signals.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [epoch70_secbits_c 0 0 double(cur_second)] ;
rtc_sec_in              = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
rtc_sec_load_in         = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = epoch70_secbits_c ;
rtc_sec_out             = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
rtc_sec_set_out         = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = dt_totalbits_c ;
rtc_datetime_out        = out_count ;

%   GPS Memory Signals

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
gpsmem_syncbank_in      = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
gpsmem_req_out          = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
gpsmem_rcv_in           = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = gpsmem_addrbits_g ;
gpsmem_addr_out         = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [gpsmem_databits_g 0 0 0] ;
gpsmem_datafrom_in      = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
gpsmem_readen_out       = out_count ;

%   Alarm Signals

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [dt_totalbits_c 0 0 0] ;
alarm_time_in           = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = epoch70_secbits_c ;
alarm_time_out          = out_count ;

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

    % inmem_clk             = fi (0, 0, 1, 0) ;

    %   Initial operation values.


    %   Execute the trial for 10 seconds.

    for clk_count = uint32 (0) : uint32 (10 * sim_steprate)

      [out_vect{:}] = step (sim_hdl, in_vect {:}) ;

      %   Grant GPS memory access as soon as it is requested.

      in_sig (gpsmem_rcv_in, 4) = out_vect {gpsmem_req_out} ;

      in_vect {gpsmem_rcv_in}   =                                       ...
                      fi (in_sig (gpsmem_rcv_in, 4),                    ...
                          in_sig (gpsmem_rcv_in, 3),                    ...
                          in_sig (gpsmem_rcv_in, 1),                    ...
                          in_sig (gpsmem_rcv_in, 2)) ;

      %   Set the current time from the seconds.

      if (clk_count == uint32 (3e-3 * sim_steprate))
        in_sig (rtc_sec_load_in, 4) = 1 ;
      else
        in_sig (rtc_sec_load_in, 4) = 0 ;
      end

      in_vect {rtc_sec_load_in}    =                                    ...
                      fi (in_sig (rtc_sec_load_in, 4),                  ...
                          in_sig (rtc_sec_load_in, 3),                  ...
                          in_sig (rtc_sec_load_in, 1),                  ...
                          in_sig (rtc_sec_load_in, 2)) ;

      %   Set the current time from the GPS Timemark.

      if (clk_count == uint32 (4.2 * sim_steprate))
        in_sig (gpsmem_syncbank_in, 4) = 1 ;

        in_vect {gpsmem_syncbank_in}   =                                ...
                      fi (in_sig (gpsmem_syncbank_in, 4),               ...
                          in_sig (gpsmem_syncbank_in, 3),               ...
                          in_sig (gpsmem_syncbank_in, 1),               ...
                          in_sig (gpsmem_syncbank_in, 2)) ;
      end

      %   Set the alarm time from the local time.

      if (clk_count == uint32 (7.5 * sim_steprate))

        bits              = out_sig  (rtc_datetime_out) ;
        local_time        = out_vect {rtc_datetime_out} ;

        shift             = dt_totalbits_c - dt_yearbits_c ;
        mask              = fi (2 ^ dt_yearbits_c - 1, 0, bits, 0) ;
        local_year        = bitand (bitshift (local_time, - shift), mask) ;

        shift             = shift - dt_monthbits_c ;
        mask              = fi (2 ^ dt_monthbits_c - 1, 0, bits, 0) ;
        local_month       = bitand (bitshift (local_time, - shift), mask) ;

        shift             = shift - dt_mdaybits_c ;
        mask              = fi (2 ^ dt_mdaybits_c - 1, 0, bits, 0) ;
        local_mday        = bitand (bitshift (local_time, - shift), mask) ;

        local_hour        = fi (6,  0, bits, 0) ;
        local_min         = fi (15, 0, bits, 0) ;
        local_sec         = fi (0,  0, bits, 0) ;

        local_time        = fi (0, 0, bits, 0) ;

        shift             = dt_totalbits_c - dt_yearbits_c ;
        local_time        = bitor (local_time,                          ...
                                   bitshift (local_year, shift)) ;
        shift             = shift - dt_monthbits_c ;
        local_time        = bitor (local_time,                          ...
                                   bitshift (local_month, shift)) ;
        shift             = shift - dt_mdaybits_c ;
        local_time        = bitor (local_time,                          ...
                                   bitshift (local_mday, shift)) ;
        shift             = shift - dt_hourbits_c ;
        local_time        = bitor (local_time,                          ...
                                   bitshift (local_hour, shift)) ;
        shift             = shift - dt_minbits_c ;
        local_time        = bitor (local_time,                          ...
                                   bitshift (local_min, shift)) ;
        shift             = shift - dt_secbits_c ;
        local_time        = bitor (local_time,                          ...
                                   bitshift (local_sec, shift)) ;

        in_vect {alarm_time_in}     =  local_time ;

      end

      %   The gpsmem datafrom is set from the address only when read enable
      %   is set.

      gpsmem_read_en      = out_vect {gpsmem_readen_out} ;

      if (gpsmem_read_en)

        gpsmem_address    = out_vect {gpsmem_addr_out} + uint8 (1) ;

        in_sig (gpsmem_datafrom_in, 4) = gpsmem (gpsmem_address) ;
        in_vect {gpsmem_datafrom_in}   =                               ...
                          fi (in_sig (gpsmem_datafrom_in, 4),          ...
                              in_sig (gpsmem_datafrom_in, 3),          ...
                              in_sig (gpsmem_datafrom_in, 1),          ...
                              in_sig (gpsmem_datafrom_in, 2)) ;
      end

    end
end
