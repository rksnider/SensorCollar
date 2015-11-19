function GPSparserTest_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_gpsmessageparser;


%---------------------------------------------------------------------------
%   Simulation Definitions.
%---------------------------------------------------------------------------

fastclk_freq_g          = 50.0e6 ;
sysclk_freq_g           = 16.0e3 ;

StepsPerClock           = 8 ;

sim_steprate            = sysclk_freq_g * StepsPerClock ;

byte_received_rate_c    = 960 ;
byte_clock_period_c     = uint32 (sim_steprate / byte_received_rate_c) ;

timezone                = -7 ;    % MST

cur_time                = (now - datenum (1970, 1, 1, 0, 0, 0)) *       ...
                           86400 - timezone * 3600 ;

week_seconds_c          = 7 * 24 * 60 * 60 ;
gps_epoch70_offset_c    = (365 * 10 + 2 + 5) * 86400 ;

%-----------------------------------------------------------------
% Messages to request.
%-----------------------------------------------------------------

week            = 52 * 34 ;
milliweek       = 1024 ;
nanomilli       = 256 * 1024 ;

payload         = [1 96 20 0                                            ...
                   byte_store(milliweek, 4) 255 0 0 0 255 255 255 255   ...
                   byte_store(0, 4) byte_store(0, 4)] ;
nav_aopstatus1  = [0 181 98 payload calc_checksum(payload)] ;

payload         = [1 96 20 0                                            ...
                   byte_store(milliweek, 4) 255 255 0 0 255 255 255 255 ...
                   byte_store(0, 4) byte_store(0, 4)] ;
nav_aopstatus2  = [0 181 98 payload calc_checksum(payload)] ;

payload         = [1 6 52 0                                             ...
                   byte_store(milliweek, 4) byte_store(nanomilli, 4)    ...
                   byte_store(week, 2) 2 13 byte_store(-160363500, 4)   ...
                   byte_store(416730700, 4) byte_store(453934100, 4)    ...
                   byte_store(3000, 4)      byte_store(0, 4)            ...
                   byte_store(0, 4)         byte_store(0, 4)            ...
                   byte_store(0, 4)         byte_store(1000, 2)         ...
                   0 24 0 0 0 0] ;
nav_sol1        = [0 181 98 payload calc_checksum(payload)] ;

payload         = [13 3 28 0                                            ...
                   0 237 0 10 byte_store(week, 2) byte_store(week, 2)   ...
                   byte_store(milliweek - 1, 4)                         ...
                   byte_store(nanomilli, 4) byte_store(milliweek, 4)    ...
                   byte_store(nanomilli, 4) byte_store(1000, 4)] ;
tim_tm2         = [0 181 98 payload calc_checksum(payload)] ;

%   Unknown message.

payload         = [1 32 16 0                                            ...
                   byte_store(milliweek, 4) byte_store(nanomilli, 4)    ...
                   byte_store(week, 2) 14 7 byte_store(200, 4)]
nav_timegps     = [0 181 98 payload calc_checksum(payload)] ;

%   Invalid data.

payload         = [13 3 28 0                                            ...
                   0 247 0 10 byte_store(week, 2) byte_store(week, 2)   ...
                   byte_store(milliweek - 1, 4)                         ...
                   byte_store(nanomilli, 4) byte_store(milliweek, 4)    ...
                   byte_store(nanomilli, 4) byte_store(1000, 4)] ;
tim_tm2_invalid = [0 181 98 payload calc_checksum(payload)] ;

%   CRC missmatches.

payload         = [1 96 20 0                                            ...
                   byte_store(milliweek, 4) 255 0 0 0 255 255 255 255   ...
                   byte_store(0, 4) byte_store(0, 4)] ;
checksum        = calc_checksum (payload) ;
nav_aop_chkA    = [0 181 98 payload (checksum(1)+1) checksum(2)] ;
nav_aop_chkB    = [0 181 98 payload checksum(1) (checksum(2)+1)] ;

%   Invalid sync.

nav_aop_sync1   = [0 180 98 payload checksum] ;
nav_aop_sync2   = [0 181 100 payload checksum] ;

%   Short messages.

payload         = [1 96 16 0                                            ...
                   byte_store(milliweek, 4) 255 0 0 0 255 255 255 255   ...
                   byte_store(0, 4)] ;
nav_aop_short1   = [0 181 98 payload calc_checksum(payload)] ;

payload         = [1 96 14 0                                            ...
                   byte_store(milliweek, 4) 255 0 0 0 255 255 255 255   ...
                   byte_store(0, 2)] ;
nav_aop_short2   = [0 181 98 payload calc_checksum(payload)] ;

%   Message timeout.

payload         = [1 96 20 0                                            ...
                   byte_store(milliweek, 4) 255 0 0 0 255 255 255 255] ;
nav_aop_timeout1  = [200 181 98 payload] ;
nav_aop_timeout2  = [200 181 98 payload(1)] ;

message_tbl     = {nav_aopstatus1 nav_aopstatus2 nav_sol1 tim_tm2       ...
                   nav_timegps tim_tm2_invalid nav_aop_chkA             ...
                   nav_aop_chkB nav_aop_sync1 nav_aop_sync2             ...
                   nav_aop_short1 nav_aop_short2 nav_aop_timeout1       ...
                   nav_aop_timeout2} ;

%-----------------------------------------------------------------
% Memory contents
%-----------------------------------------------------------------

meminit = [ 17   9   9   5   3   2   9   9   9   9   8   8   8  ...
                 8   5   2   3   8                              ...
             8   9   3   3   2   2   9   8   8                  ...
            10   2   3   4   4   5   8   8   9   9   9          ...
           127   7   1  22  13  31   6   0  96   3   3   5      ...
             0  18  27                                          ...
             1   6   1  96  13   3                              ...
             6   1   8   0 129 240   7 128                      ...
             6   1   8   0 130 240   1   6 128                  ...
             6   1   8   0 130 240   2   6 128                  ...
             6   1   8   0 130 240   3   6 128                  ...
             6   1   8   0 130 240   4   6 128                  ...
             6   1   8   0 130 240   5   6 128                  ...
             6   1   8   0 130 240  65   6 128                  ...
             6  36  36   0 129   1   1 129   3  33 128          ...
             6  35  40   0   3 129  64  23 129   1  12 128      ...
             6  17   2   0 130   8   1 128                      ...
             6   2  10   0 129   1   9 128                      ...
             6  49  32   0   4 129  50   3 131  64  66  15   1  ...
               131  64  66  15   5 131 160 134   1   5 129 246  ...
                 3   0] ;

mem     = [meminit zeros(1, 1024-length(meminit))] ;

% Simulate for trials (this will be the length of the simulation)

Trial_count   =   1 ;
clocks_needed =   1 ;   % Clock cycles needed per trial.

%---------------------------------------------------------------------------
%   Package and Generic definitions.
%---------------------------------------------------------------------------

gps_time_nanobits_c     = 20 ;
gps_time_millibits_c    = 30 ;
gps_time_weekbits_c     = 16 ;

gps_time_bits_c         = gps_time_weekbits_c + gps_time_millibits_c +  ...
                          gps_time_nanobits_c ;

gps_time_nanomult_c     = 2 ^ 0 ;
gps_time_millimult_c    = 2 ^ gps_time_nanobits_c ;
gps_time_weekmult_c     = 2 ^ (gps_time_nanobits_c + gps_time_millibits_c) ;

gps_time_nanolimit_c    = 1000000 ;
gps_time_millilimit_c   = 1000 * 60 * 60 * 24 * 7 ;
gps_time_weeklimit_c    = 10000 ;

memaddr_bits_g          = 10 ;

init_week               = 0 ;
init_millisec           = 5 ;
init_nanosec            = 500 ;

init_time               = uint64 (init_week * gps_time_weekmult_c +      ...
                                  init_millisec * gps_time_millimult_c + ...
                                  init_nanosec * gps_time_nanomult_c) ;

%   Time Mark values.

marker_time             = cur_time - gps_epoch70_offset_c ;
marker_week             = uint64 (fix (marker_time / week_seconds_c)) ;
marker_millisec         = uint64 (fix ((marker_time -                   ...
                                        double (marker_week) *          ...
                                       week_seconds_c) * 1000)) ;
marker_nanosec          = uint64 (581463) ;


tm_time                 = uint64 (marker_week * gps_time_weekmult_c +   ...
                                  marker_millisec *                     ...
                                    gps_time_millimult_c +              ...
                                  marker_nanosec * gps_time_nanomult_c) ;

%   Startup time latch information.

gps_time_nanoincr_c     = 1e9 / (sim_steprate / 4) ;

dlatch_waveform         = [0 1 0 0] ;
vlatch_waveform         = [0 0 0 1] ;
valid_waveform          = [0 0 1 1] ;

%   Message information.

msg_ram_blocks_c        = 2 ;
msg_count_c             = 3 ;
msg_count_bits_c        = fix (log2 (msg_count_c)) + 1 ;

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

%   FPGA startup time.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [gps_time_bits_c 0 0 init_time] ;
curtime_in              = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
curtime_latch_in        = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
curtime_valid_in        = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
curtime_vlatch_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [gps_time_bits_c 0 0 tm_time] ;
markertime_in           = in_count ;

%   Input Data

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [8 0 0 0] ;
inbyte_in               = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
inready_in              = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
inreceived_out          = out_count ;

%   Memory Allocation and Control

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
memreq_out              = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
memrcv_in               = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = memaddr_bits_g ;
memaddr_out             = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [8 0 0 0] ;
meminput_in             = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 8 ;
memoutput_out           = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
memread_en_out          = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
memwrite_en_out         = out_count ;

%   Message Information

out_count               = out_count + 1 ;
out_sig (out_count)     = msg_ram_blocks_c ;
datavalid_out           = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
tempbank_out            = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = msg_count_bits_c ;
msgnumber_out           = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
msgreceived_out         = out_count ;

%   Busy Processing

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
busy_out                = out_count ;


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

    %   Initial time.

    startup_week          = init_week ;
    startup_millisec      = init_millisec ;
    startup_nanosec       = init_nanosec ;

    startup_time          = init_time ;

    %   Execute the trial.

    msg_done                = uint32 (0) ;
    clock_count             = uint32 (0) ;
    byte_clock              = uint32 (0) ;
    byte_index              = uint32 (1) ;
    message_index           = uint32 (1) ;
    message                 = message_tbl {message_index} ;
    delay                   = message (1) ;

    while (message_index < length (message_tbl) ||                      ...
           byte_index < length (message) ||                             ...
           byte_clock < byte_clock_period_c - 1 ||                      ...
           delay > 0)

      [out_vect{:}] = step (sim_hdl, in_vect {:}) ;

      %   Send a new byte periodically.

      byte_clock              = byte_clock + 1 ;

      if (byte_clock == byte_clock_period_c)
        byte_clock            = uint32 (0) ;

        if (byte_index >= length (message) && delay > 0)
          delay               = delay - 1 ;
        else
          if (byte_index >= length (message))
            message_index     = message_index + 1 ;
            message           = message_tbl {message_index} ;
            delay             = message (1) ;
            byte_index        = uint32 (1) ;
          end

          byte_index          = byte_index + 1 ;

          in_vect {inbyte_in} = fi (message (byte_index),               ...
                                    in_sig (inbyte_in, 3),              ...
                                    in_sig (inbyte_in, 1),              ...
                                    in_sig (inbyte_in, 2)) ;
          in_vect {inready_in}  = fi (1, 0, 1, 0) ;
        end
      elseif (out_vect {inreceived_out} > 0)
        in_vect {inready_in}  = fi (0, 0, 1, 0) ;
      end

      %   Update the current time every 4 sample times.

      clock_count           = clock_count + 1 ;

      in_vect {curtime_latch_in}  = fi (dlatch_waveform (clock_count),  ...
                                        0, 1, 0) ;
      in_vect {curtime_valid_in}  = fi (valid_waveform  (clock_count),  ...
                                        0, 1, 0) ;
      in_vect {curtime_vlatch_in} = fi (vlatch_waveform (clock_count),  ...
                                        0, 1, 0) ;

      if (clock_count == 4)
        clock_count           = uint32 (0) ;

        startup_nanosec       = startup_nanosec + gps_time_nanoincr_c ;

        if (startup_nanosec < gps_time_nanolimit_c)
          startup_time        = startup_time + gps_time_nanoincr_c ;
        else
          startup_nanosec     = rem (startup_nanosec, gps_time_nanolimit_c) ;
          startup_millisec    = startup_millisec + 1 ;

          if (startup_millisec == gps_time_millilimit_c)
            startup_millisec  = 0 ;
            startup_week      = startup_week + 1 ;
          end

          startup_time        = uint64 (startup_week *                  ...
                                        gps_time_weekmult_c +           ...
                                        startup_millisec *              ...
                                        gps_time_millimult_c +          ...
                                        startup_nanosec *               ...
                                        gps_time_nanomult_c) ;
        end

        in_vect {curtime_in}  = fi (startup_time, 0, gps_time_bits_c, 0) ;
      end

      %   Memory is allocated immediately after a request for it is
      %   received.

      in_vect {memrcv_in}   = out_vect {memreq_out} ;

      %   Memory is read or written only when that enable signal is high.

      if (out_vect {memread_en_out}.bin == '1')
        in_vect {meminput_in} = fi (mem (out_vect {memaddr_out} + 1),   ...
                                    in_sig (meminput_in, 3),            ...
                                    in_sig (meminput_in, 1),            ...
                                    in_sig (meminput_in, 2)) ;
      end

      if (out_vect {memwrite_en_out}.bin == '1')
        mem (out_vect {memaddr_out} + 1)  = out_vect {memoutput_out} ;
      end
    end

end
