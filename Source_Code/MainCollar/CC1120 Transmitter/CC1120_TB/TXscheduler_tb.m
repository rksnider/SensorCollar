function TXscheduler_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_txscheduler;


%---------------------------------------------------------------------------
%   Simulation Definitions.
%---------------------------------------------------------------------------

sysclk_freq_g           = 10 ;

StepsPerClock           = 4 ;

sim_steprate            = sysclk_freq_g * StepsPerClock ;

clocks_per_sec          = uint32 (StepsPerClock * sysclk_freq_g) ;

system_id               = uint32 (2146892317) ;

min_secs                = uint64 (60) ;
hr_mins                 = uint64 (60) ;
day_hrs                 = uint64 (24) ;
yr_days                 = uint64 (365) ;

local_year              = uint64 (16) ;
local_month             = uint64 (9) ;
local_mday              = uint64 (15) ;
local_hour              = uint64 (15) ;
local_minute            = uint64 (20) ;
local_second            = uint64 (42) ;
local_leapyr            = uint64 (1) ;
local_in_dst            = uint64 (1) ;

local_ydays             = uint64 (31+28+local_leapyr+31+30+31+30+31+31+ ...
                                  15) ;

base_seconds            = double ((((local_year    * yr_days  +         ...
                                     local_ydays)  * day_hrs  +         ...
                                     local_hour)   * hr_mins  +         ...
                                     local_minute) * min_secs +         ...
                                     local_second) ;

% local_ydays             = uint64 (31+28+31+30+31+30+31+31+30+31+30+30) ;


% Simulate for trials (this will be the length of the simulation)

Trial_count   =   1 ;
clocks_needed =   1 ;   % Clock cycles needed per trial.

%---------------------------------------------------------------------------
%   Package and Generic definitions.
%---------------------------------------------------------------------------

sched_count_g           = 8 ;
millisec_week_c         = 7 * 24 * 60 * 60 * 1000 ;

sched_id_bits_c         = fix (log2 (sched_count_g-1)) + 1 ;
sched_delay_bits_c      = fix (log2 (millisec_week_c / 1000 - 1)) + 1 ;

dt_yearbits_c           = 5 ;
dt_ydaybits_c           = 9 ;
dt_monthbits_c          = 4 ;
dt_mdaybits_c           = 5 ;
dt_hourbits_c           = 5 ;
dt_minbits_c            = 6 ;
dt_secbits_c            = 6 ;
dt_lyearbits_c          = 1 ;
dt_indstbits_c          = 1 ;


dt_totalbits_c          = dt_yearbits_c  + dt_ydaybits_c  +             ...
                          dt_monthbits_c + dt_mdaybits_c  +             ...
                          dt_hourbits_c  + dt_minbits_c   +             ...
                          dt_secbits_c   + dt_lyearbits_c +             ...
                          dt_indstbits_c ;


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

%   Action signals.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [dt_totalbits_c 0 0 0] ;
localtime_in            = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
clockchg_in             = in_count ;

%   System's Identification.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [32 0 0 system_id] ;
system_id_in            = in_count ;

%   Startup/Shutdown signals.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
startup_in              = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
startup_out             = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
shutdown_in             = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
shutdown_out            = out_count ;

%   Messaging signals.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
send_in                 = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
receive_in              = in_count ;

%   Power control signals.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
power_in                = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
power_out               = out_count ;

%   Initialization signals.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
init_in                 = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
init_out                = out_count ;

%   Packet transmission signals.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
trx_in                  = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
trx_out                 = out_count ;

%   Packet receive signals.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
rcv_in                  = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
rcv_out                 = out_count ;

%   Scheduler request signals.

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
sched_req_out           = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
sched_rcv_in            = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
sched_type_out          = out_count ;

%   Scheduling signals.

out_count               = out_count + 1 ;
out_sig (out_count)     = sched_id_bits_c ;
sched_id_out            = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = sched_delay_bits_c ;
sched_delay_out         = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
sched_start_in          = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
sched_start_out         = out_count ;

%   Component busy signal.

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
busy_out                = out_count ;


%---------------------------------------------------------------------------
%   Schedule Memory contents.  It includes an extra value available for
%   extended operations when the event occurs.
%---------------------------------------------------------------------------

bit_ids       = [send_in receive_in clockchg_in startup_in shutdown_in] ;

send_id_c     = 0 ;
recv_id_c     = 1 ;
clockchg_id_c = 2 ;
startup_id_c  = 3 ;
shutdown_id_c = 4 ;

mem           = zeros (1, 3) ;

mem (1, :)    = [startup_id_c       10+base_seconds        0] ;
mem (2, :)    = [clockchg_id_c     130+base_seconds    -3610] ;
mem (3, :)    = [clockchg_id_c    3700+base_seconds   172800] ;
mem (4, :)    = [clockchg_id_c  180000+base_seconds  -129600] ;
mem (5, :)    = [shutdown_id_c  200000+base_seconds        0] ;

mem_size      = size (mem) ;
mem_cnt       = mem_size (1) ;


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

    sched_starting              = 0 ;

    shutdown                    = uint32 (0) ;
    busy                        = uint32 (0) ;

    sched_rcv                   = 0 ;

    clock                       = uint32 (0) ;
    seconds                     = uint64 (base_seconds) ;
    last_seconds                = uint64 (0) ;

    while (shutdown == 0 || busy == 1)

      clock                     = clock + uint32 (1) ;

      [out_vect{:}] = step (sim_hdl, in_vect {:}) ;

      if (rem (clock, StepsPerClock) == 1)

        %   Handle adding new scheduling events.

        sched_req               = uint32 (out_vect {sched_req_out}) ;

        if (sched_req == 1)
          sched_start           = uint32 (out_vect {sched_start_out}) ;

          if (sched_rcv == 0)
            sched_rcv           = 1 ;

            in_vect {sched_rcv_in} =                                    ...
                                  fi (sched_rcv,                        ...
                                      in_sig (sched_rcv_in, 3),         ...
                                      in_sig (sched_rcv_in, 1),         ...
                                      in_sig (sched_rcv_in, 2)) ;

          %   Add or remove an event.

          elseif (sched_start == 0)
            sched_starting      = 0 ;

            in_vect {sched_start_in} =                                  ...
                                  fi (sched_start,                      ...
                                      in_sig (sched_start_in, 3),       ...
                                      in_sig (sched_start_in, 1),       ...
                                      in_sig (sched_start_in, 2)) ;

          elseif (sched_start == 1)
            if (sched_starting == 0)
              sched_starting    = 1 ;
              sched_type        = uint32 (out_vect {sched_type_out}) ;
              sched_id          = uint32 (out_vect {sched_id_out}) ;
              sched_delay       = uint32 (out_vect {sched_delay_out}) + ...
                                  uint32 (seconds) ;

              in_vect {sched_start_in} =                                ...
                                  fi (sched_start,                      ...
                                      in_sig (sched_start_in, 3),       ...
                                      in_sig (sched_start_in, 1),       ...
                                      in_sig (sched_start_in, 2)) ;

              if (mem_cnt > 0)
                for i = 1 : mem_cnt
                  if (mem (i, 1) == sched_id)
                    if (mem_cnt > i)
                      mem (i : mem_cnt - 1, :) = mem (i + 1 : mem_cnt, :) ;
                    end

                    mem_cnt     = mem_cnt - 1 ;
                    break ;
                  end
                end
              end

              if (sched_type == 1)
                insert          = mem_cnt + 1 ;

                if (mem_cnt > 0)
                  for i = 1 : mem_cnt
                    if (mem (i, 2) > sched_delay)
                      mem (i + 1 : mem_cnt + 1, :)  = mem (i : mem_cnt, :) ;
                      insert    = i ;
                      break ;
                    end
                  end
                end

                mem (insert, :)   = [sched_id sched_delay 0] ;
                mem_cnt           = mem_cnt + 1 ;
              end
            end
          end

        %   Release the scheduler.

        elseif (sched_rcv == 1)
          sched_rcv               = 0 ;

          in_vect {sched_rcv_in}  = fi (sched_rcv,                      ...
                                        in_sig (sched_rcv_in, 3),       ...
                                        in_sig (sched_rcv_in, 1),       ...
                                        in_sig (sched_rcv_in, 2)) ;

        end

        %   Deactivate all signals currently activated.

        for i = 1 : length (bit_ids)
          in_index            = bit_ids (i) ;

          in_vect {in_index}  = fi (0,                                  ...
                                    in_sig (in_index, 3),               ...
                                    in_sig (in_index, 1),               ...
                                    in_sig (in_index, 2)) ;
        end

        %   Activate and remove all events that have reached their
        %   activation times.

        if (mem_cnt > 0)

          remove_cnt              = 0 ;
          new_seconds             = seconds ;

          for i = 1 : mem_cnt
            if (mem (i, 2) <= seconds)
              remove_cnt          = remove_cnt + 1 ;

              in_index            = bit_ids (mem (i, 1) + 1) ;

              in_vect {in_index}  = fi (1,                              ...
                                        in_sig (in_index, 3),           ...
                                        in_sig (in_index, 1),           ...
                                        in_sig (in_index, 2)) ;

              if (mem (i, 1)  == clockchg_id_c)
                new_seconds       = uint64 (double (seconds) + mem (i, 3)) ;
              end
            end
          end

          seconds                 = new_seconds ;

          if (remove_cnt > 0 && remove_cnt < mem_cnt)
            mem (1 : mem_cnt - remove_cnt, :)                           ...
                                  = mem (remove_cnt + 1 : mem_cnt, :) ;
          end

          mem_cnt                 = mem_cnt - remove_cnt ;
        end

        %   Set the initialization state immediately.

        in_vect {init_in}         = fi (uint32 (out_vect {init_out}),   ...
                                        in_sig (init_in, 3),            ...
                                        in_sig (init_in, 1),            ...
                                        in_sig (init_in, 2)) ;

        %   Set the power state immediately.

        in_vect {power_in}        = fi (uint32 (out_vect {power_out}),  ...
                                        in_sig (power_in, 3),           ...
                                        in_sig (power_in, 1),           ...
                                        in_sig (power_in, 2)) ;

        %   Set the transmit state immediately.

        in_vect {trx_in}          = fi (uint32 (out_vect {trx_out}),    ...
                                        in_sig (trx_in, 3),             ...
                                        in_sig (trx_in, 1),             ...
                                        in_sig (trx_in, 2)) ;

        %   Set the receive state every second.

        if (seconds ~= last_seconds)

          in_vect {rcv_in}          = fi (uint32 (out_vect {rcv_out}),  ...
                                          in_sig (rcv_in, 3),           ...
                                          in_sig (rcv_in, 1),           ...
                                          in_sig (rcv_in, 2)) ;
        end

        %   Set the shutdown state from the shutdown output.

        if (uint32 (out_vect {shutdown_out}) == 1)
          shutdown                = uint32 (1) ;
        end

        %   Update the local time.  The month and day-of-month are not used
        %   the leap year and in daylight savings time states are hard
        %   coded.

        if (seconds ~= last_seconds)
          last_seconds            = seconds ;

          temp_seconds            = seconds ;

          local_second            = rem (temp_seconds, min_secs) ;
          temp_minutes            = (temp_seconds - local_second ) /    ...
                                    min_secs ;
          local_minute            = rem (temp_minutes, hr_mins) ;
          temp_hours              = (temp_minutes - local_minute) /     ...
                                    hr_mins ;
          local_hour              = rem (temp_hours, day_hrs) ;
          temp_days               = (temp_hours - local_hour) / day_hrs ;
          local_yday              = rem (temp_days, yr_days) ;
          temp_years              = (temp_days - local_yday) / yr_days ;
          local_year              = temp_years ;

          loc_time                = local_year ;
          loc_time                = bitshift (loc_time,                 ...
                                              dt_ydaybits_c)    +       ...
                                    local_yday ;
          loc_time                = bitshift (loc_time,                 ...
                                              dt_monthbits_c)   +       ...
                                    local_month ;
          loc_time                = bitshift (loc_time,                 ...
                                              dt_mdaybits_c)    +       ...
                                    local_mday ;
          loc_time                = bitshift (loc_time,                 ...
                                              dt_hourbits_c)    +       ...
                                    local_hour ;
          loc_time                = bitshift (loc_time,                 ...
                                              dt_minbits_c) +           ...
                                    local_minute ;
          loc_time                = bitshift (loc_time,                 ...
                                              dt_secbits_c)    +        ...
                                    local_second ;
          loc_time                = bitshift (loc_time,                 ...
                                              dt_lyearbits_c)  +        ...
                                    local_leapyr ;
          loc_time                = bitshift (loc_time,                 ...
                                              dt_indstbits_c)  +        ...
                                    local_in_dst ;

          in_vect {localtime_in}  = fi (loc_time,                       ...
                                        in_sig (localtime_in, 3),       ...
                                        in_sig (localtime_in, 1),       ...
                                        in_sig (localtime_in, 2)) ;
        end

        %   Capture the busy state of the component.

        busy                      = uint32 (out_vect {busy_out}) ;
      end

      %   Update the second counter.

      if (rem (clock, clocks_per_sec) == 0)
        seconds                   = seconds + uint64 (1) ;
        
        if (rem (seconds, 60) == 0)
          fprintf (1, '%d\n', int64 (double (seconds) - base_seconds)) ;
        end
      end
    end

end
