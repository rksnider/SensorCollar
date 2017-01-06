function Scheduler_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_scheduler ;

%---------------------------------------------------------------------------
%   Entity Definitions
%---------------------------------------------------------------------------

clk_freq_g              = 50.0e3 ;

gps_time_bytes_c        = 9 ;
gps_time_nanobits_c     = 20 ;
gps_time_millibits_c    = 30 ;
gps_time_weekbits_c     = 16 ;
gps_time_bits_c         = gps_time_nanobits_c + gps_time_millibits_c +  ...
                          gps_time_weekbits_c ;

week_seconds_c          = 7 * 24 * 60 * 60 ;
millisec_week_c         = week_seconds_c * 1000 ;

system_nano             = uint32 (784911) ;


%---------------------------------------------------------------------------
%   Simulation Definitions.
%---------------------------------------------------------------------------

StepsPerClock           = 2 ;

sim_steprate            = clk_freq_g * StepsPerClock ;

%   Request information.

req_number_g            = 8 ;

if (req_number_g > 1)
  req_bits_c            = fix (log2 (req_number_g - 1)) + 1 ;
else
  req_bits_c            = 1 ;
end

req_secs_c              = fix (log2 (millisec_week_c / 1000 - 1)) + 1 ;


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


%   Timing information.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
milli_clk               = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [gps_time_bits_c 0 0 0] ;
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

%   Request information.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
req_received_in         = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
req_received_out        = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
req_type_in             = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [req_bits_c 0 0 0] ;
req_id_in               = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [gps_time_millibits_c 0 0 0] ;
req_time_in             = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [req_secs_c 0 0 0] ;
req_secs_in             = in_count ;

%   Completion signals.

out_count               = out_count + 1 ;
out_sig (out_count)     = req_number_g ;
done_out                = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
busy_out                = out_count ;


%---------------------------------------------------------------------------
%   Table of test vectors.  Each vector has:
%     start week and millisecond    The milli_clk will start at this time,
%                                   run for some cycles, then the request
%                                   information will be set and the
%                                   milli_clk will run for some additional
%                                   cycles.
%     request received              When one a request will be sent,
%                                   otherwise the request info is ignored.
%     request type, ID, time, & seconds
%---------------------------------------------------------------------------

prefix_cycles           = 4 ;
suffix_cycles           = 4 ;
clock_mult              = 10 ;

weekno                  = 1 ;
millisec                = weekno + 1 ;
received                = millisec + 1 ;
reqtype                 = received + 1 ;
reqID                   = reqtype + 1 ;
reqtime                 = reqID + 1 ;
reqsec                  = reqtime + 1 ;
reqlength               = reqsec ;

req_info                = [req_received_in req_type_in req_id_in        ...
                           req_time_in req_secs_in] ;

req_tbl                 = zeros (1, reqlength, 'uint32') ;

req_count               = 0 ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 12 0 0 0 0 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 35 0 0 0 0 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 84 0 0 0 0 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 118 1 1 2 130 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 128 0 0 0 0 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 145 0 0 0 0 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 160 1 1 2 220 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 170 1 1 0 200 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 180 1 1 1 210 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 198 0 0 0 0 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 208 0 0 0 0 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 218 0 0 0 0 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 240 1 1 2 120 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 260 1 1 0 100 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 280 1 1 1 110 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([0 millisec_week_c-3 0 0 0 0 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([1 20 1 1 4 110 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([1 30 1 1 3 100 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([1 40 1 1 1 120 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([1 50 1 0 2 0 0]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([1 98 0 0 0 0 0]) ;

use_secs                = 2 ^ gps_time_millibits_c - 1 ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([1 120 1 1 4 use_secs 3]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([1 130 1 1 3 use_secs 8]) ;

req_count               = req_count + 1 ;
req_tbl (req_count, :)  = uint32 ([1 140 1 1 1 use_secs 2]) ;


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

    %   Execute the trial.

    req_size      = size (req_tbl) ;

    for req_trial = 1 : req_size (1) ;

      %   Set the current time and walk through the prefix milliseconds.

      system_week       = req_tbl (req_trial, weekno) ;
      system_milli      = req_tbl (req_trial, millisec) ;

      for pref_count = 1 : prefix_cycles
        cur_time = bitor (bitor (bitshift (fi (system_week,  0,         ...
                                               gps_time_bits_c, 0),     ...
                                           gps_time_millibits_c +       ...
                                           gps_time_nanobits_c),        ...
                                 bitshift (fi (system_milli, 0,         ...
                                                gps_time_bits_c, 0),    ...
                                           gps_time_nanobits_c)),       ...
                           fi (system_nano,  0, gps_time_bits_c, 0)) ;

        in_vect {curtime_in}      = cur_time ;

        in_sig (milli_clk, 4)     = 1 ;
        in_vect {milli_clk}       =                                     ...
                      fi (in_sig (milli_clk, 4),                        ...
                          in_sig (milli_clk, 3),                        ...
                          in_sig (milli_clk, 1),                        ...
                          in_sig (milli_clk, 2)) ;

        for i = 1 : clock_mult
          [out_vect{:}]           = step (sim_hdl, in_vect {:}) ;
        end

        in_sig (milli_clk, 4)     = 0 ;
        in_vect {milli_clk}       =                                     ...
                      fi (in_sig (milli_clk, 4),                        ...
                          in_sig (milli_clk, 3),                        ...
                          in_sig (milli_clk, 1),                        ...
                          in_sig (milli_clk, 2)) ;

        for i = 1 : clock_mult
          [out_vect{:}]           = step (sim_hdl, in_vect {:}) ;
        end

        system_milli              = system_milli + 1 ;

        if (system_milli >= millisec_week_c)
          system_milli            = 0 ;
          system_week             = system_week + 1 ;
        end
      end

      %   Handle a new request.

      if (req_tbl (req_trial, received) == 1)
        in_sig (req_received_in, 4) = 1 ;
        in_sig (req_type_in, 4)     = req_tbl (req_trial, reqtype) ;
        in_sig (req_id_in, 4)       = req_tbl (req_trial, reqID) ;
        in_sig (req_time_in, 4)     = req_tbl (req_trial, reqtime) ;
        in_sig (req_secs_in, 4)     = req_tbl (req_trial, reqsec) ;

        for i = 1 : length (req_info)
          fld           = req_info (i) ;
          in_vect {fld} = fi (in_sig (fld, 4), in_sig (fld, 3),         ...
                            in_sig (fld, 1), in_sig (fld, 2)) ;
        end

        %   Send the request until the received out goes high.
        %   Set the received in low and wait until the received out goes
        %   low as well.

        received_out              = uint32 (0) ;

        while (received_out == 0)
          [out_vect{:}]           = step (sim_hdl, in_vect {:}) ;

          received_out            = uint32 (out_vect {req_received_out}) ;
        end

        in_sig (req_received_in, 4) = 0 ;
        in_vect {req_received_in}   =                                   ...
                      fi (in_sig (req_received_in, 4),                  ...
                          in_sig (req_received_in, 3),                  ...
                          in_sig (req_received_in, 1),                  ...
                          in_sig (req_received_in, 2)) ;

        while (received_out == 1)
          [out_vect{:}]           = step (sim_hdl, in_vect {:}) ;

          received_out            = uint32 (out_vect {req_received_out}) ;
        end
      end

      %   Walk through the suffix cycles.

      for suf_count = 1 : suffix_cycles
        cur_time = bitor (bitor (bitshift (fi (system_week,  0,         ...
                                               gps_time_bits_c, 0),     ...
                                           gps_time_millibits_c +       ...
                                           gps_time_nanobits_c),        ...
                                 bitshift (fi (system_milli, 0,         ...
                                                gps_time_bits_c, 0),    ...
                                           gps_time_nanobits_c)),       ...
                           fi (system_nano,  0, gps_time_bits_c, 0)) ;

        in_vect {curtime_in}      = cur_time ;

        in_sig (milli_clk, 4)     = 1 ;
        in_vect {milli_clk}       =                                     ...
                      fi (in_sig (milli_clk, 4),                        ...
                          in_sig (milli_clk, 3),                        ...
                          in_sig (milli_clk, 1),                        ...
                          in_sig (milli_clk, 2)) ;

        for i = 1 : clock_mult
          [out_vect{:}]           = step (sim_hdl, in_vect {:}) ;
        end

        in_sig (milli_clk, 4)     = 0 ;
        in_vect {milli_clk}       =                                     ...
                      fi (in_sig (milli_clk, 4),                        ...
                          in_sig (milli_clk, 3),                        ...
                          in_sig (milli_clk, 1),                        ...
                          in_sig (milli_clk, 2)) ;

        for i = 1 : clock_mult
          [out_vect{:}]           = step (sim_hdl, in_vect {:}) ;
        end

        system_milli              = system_milli + 1 ;

        if (system_milli >= millisec_week_c)
          system_milli            = 0 ;
          system_week             = system_week + 1 ;
        end
      end
    end
end
