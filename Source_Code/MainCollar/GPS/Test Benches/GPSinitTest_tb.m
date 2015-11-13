function GPSinitTest_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_gpsinit;


%---------------------------------------------------------------------------
%   Simulation Definitions.
%---------------------------------------------------------------------------

fastclk_freq_g          = 50.0e6 ;
sysclk_freq_g           = 16.0e3 ;

StepsPerClock           = 8 ;

sim_steprate            = sysclk_freq_g * StepsPerClock ;

hold_time               = 10 ;


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

mem     = [meminit zeros(1, 512-length(meminit))] ;

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

gps_time_nanoincr_c     = 1e9 / (sim_steprate / 4) ;

dlatch_waveform         = [0 1 0 0] ;
vlatch_waveform         = [0 0 0 1] ;
valid_waveform          = [0 0 1 1] ;

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
dlatch_in               = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
vlatch_in               = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
valid_in                = in_count ;

%   Initialization

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 1] ;
init_start_in           = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
init_done_out           = out_count ;

%   Message Sender Allocation

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
sendreq_out             = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
sendrcv_in              = in_count ;

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

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
memread_en_out          = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
memwrite_en_out         = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [8 0 0 0] ;
meminput_in             = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 8 ;
memoutput_out           = out_count ;

%   Message Information

out_count               = out_count + 1 ;
out_sig (out_count)     = 8 ;
msgclass_out            = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 8 ;
msgid_out               = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 16 ;
msglength_out           = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = memaddr_bits_g ;
msgaddress_out          = out_count ;

%   Message Sender Control

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
sendready_in            = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
outsend_out             = out_count ;

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

    init_done               = uint32 (0) ;
    clock_count             = uint32 (0) ;

    while (init_done == 0)

      [out_vect{:}] = step (sim_hdl, in_vect {:}) ;

      %   Get the initialization done value.

      init_done             = uint32 (out_vect {init_done_out}) ;

      %   Update the current time every 4 sample times.

      clock_count           = clock_count + 1 ;

      in_vect {dlatch_in}   = fi (dlatch_waveform (clock_count), 0, 1, 0) ;
      in_vect {vlatch_in}   = fi (vlatch_waveform (clock_count), 0, 1, 0) ;
      in_vect {valid_in}    = fi (valid_waveform  (clock_count), 0, 1, 0) ;

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
        
        in_vect {init_start_in} = fi (0, 0, 1, 0) ;
      end

      %   Sender and memory are allocated immediately after a request for
      %   them is received.

      in_vect {sendrcv_in}  = out_vect {sendreq_out} ;
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

      %   The sender finishes the command immediately.

      in_vect {sendready_in}  = fi (1 - out_vect {outsend_out}, 0, 1, 0) ;

    end

end
