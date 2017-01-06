function OnOffScheduler_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_onoffschedulerwrapper;


%---------------------------------------------------------------------------
%   Package and Generic definitions.
%---------------------------------------------------------------------------

alarm_bytes_g           = 3 ;

sched_count_g           = 8 ;
millisec_week_c         = 7 * 24 * 60 * 60 * 1000 ;

sched_id_bits_c         = fix (log2 (sched_count_g-1)) + 1 ;
sched_delay_bits_c      = fix (log2 (millisec_week_c / 1000 - 1)) + 1 ;

Epoch70_secbits_c       = 32 ;

er_end_shift            = 0 ;
er_str_shift            = er_end_shift  + Epoch70_secbits_c ;
er_range_shift          = er_str_shift  + Epoch70_secbits_c ;

E70_rangebits_c         = er_range_shift ;


%---------------------------------------------------------------------------
%   Simulation Definitions.
%---------------------------------------------------------------------------

sysclk_freq_g           = 10 ;

StepsPerClock           = 4 ;

sim_steprate            = sysclk_freq_g * StepsPerClock ;

clocks_per_sec          = uint32 (StepsPerClock * sysclk_freq_g) ;

min_secs                = uint32 (60) ;
hr_mins                 = uint32 (60) ;
day_hrs                 = uint32 (24) ;
yr_days                 = uint32 (365) ;

hr_secs                 = hr_mins * min_secs ;
day_secs                = day_hrs * hr_secs ;

local_year              = uint32 (16) ;
local_month             = uint32 (9) ;
local_mday              = uint32 (15) ;
local_hour              = uint32 (2) ;
local_minute            = uint32 (20) ;
local_second            = uint32 (42) ;
local_leapyr            = uint32 (1) ;
local_in_dst            = uint32 (1) ;

leapdays                = [0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4 5 5 5 5    ...
                           6 6 6 6 7 7 7 7 8 8 8 8 9 9 9 9] ;

local_leapdays          = leapdays (local_year + 1) ;

local_ydays             = uint32 (31+28+local_leapyr+31+30+31+30+31+31+ ...
                                  15) ;

epoch70_base            = (30 * yr_days + 7) * day_secs ;

day_start               = double ((local_year     * yr_days  +          ...
                                   local_leapdays +                     ...
                                   local_ydays)   * day_secs +          ...
                                   epoch70_base) ;

base_daystart           = local_hour * hr_secs +                        ...
                          local_minute * min_secs + local_second ;
base_seconds            = day_start + base_daystart ;

listen                  = 0 ;
listen_last             = 1 - listen ;
timingchg               = 0 ;
timingchg_last          = 0 ;

% Noon, dawn, and dusk information is based on timings taken from the
% sunrise/sunset MIF file.  Twilight starts or ends when the sun is 18
% degrees below the horizon.

today_noon                = uint32 (11 * hr_secs + 54 * min_secs + 58) ;
today_day_offset          = uint32 ( 6 * hr_secs + 15 * min_secs + 35) ;
today_twilight_offset     = uint32 (today_day_offset * 18.0 / 90.0) ;

today_dawn                = today_noon - today_day_offset -             ...
                            today_twilight_offset ;
today_dusk                = today_noon + today_day_offset +             ...
                            today_twilight_offset ;

tomorrow_noon             = uint32 (11 * hr_secs + 54 * min_secs + 37) ;
tomorrow_day_offset       = uint32 ( 6 * hr_secs + 14 * min_secs +  0) ;
tomorrow_twilight_offset  = uint32 (tomorrow_day_offset * 18.0 / 90.0) ;

tomorrow_dawn             = tomorrow_noon - tomorrow_day_offset -       ...
                            tomorrow_twilight_offset + day_secs ;
tomorrow_dusk             = tomorrow_noon + tomorrow_day_offset +       ...
                            tomorrow_twilight_offset + day_secs ;

% local_ydays             = uint32 (31+28+31+30+31+30+31+31+30+31+30+30) ;

% Simulate for trials (this will be the length of the simulation)

Trial_count   =   1 ;
clocks_needed =   1 ;   % Clock cycles needed per trial.

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
in_sig (in_count, :)    = [Epoch70_secbits_c 0 0 0] ;
rtctime_in              = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 timingchg] ;
timingchg_in            = in_count ;

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

%   On/Off signals.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
off_in                  = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
off_out                 = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times01_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times02_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times03_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times04_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times05_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times06_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times07_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times08_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times09_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times10_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times11_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times12_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times13_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times14_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times15_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times16_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times17_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times18_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times19_in       = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [E70_rangebits_c 0 0 0] ;
on_off_times20_in       = in_count ;

%   Alarm signals.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
alarm_set_in            = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
alarm_set_out           = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = alarm_bytes_g * 8 ;
alarm_out               = out_count ;

%   Scheduler request signals.

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
sched_req_out           = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
sched_rcv_in            = in_count ;

%   Scheduling signals.

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
sched_type_out          = out_count ;

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


% Create a vector of time ranges.

on_off_range            = zeros (1, 2, 'uint32') ;

on_off_range ( 1, :)    = [today_dawn             today_dawn+2*hr_secs  ] ;
on_off_range ( 2, :)    = [ 6*hr_secs-2*min_secs   6*hr_secs+min_secs   ] ;
on_off_range ( 3, :)    = [ 8*hr_secs-2*min_secs   8*hr_secs+min_secs   ] ;
on_off_range ( 4, :)    = [10*hr_secs-2*min_secs  10*hr_secs+min_secs   ] ;
on_off_range ( 5, :)    = [12*hr_secs-2*min_secs  12*hr_secs+min_secs   ] ;
on_off_range ( 6, :)    = [14*hr_secs-2*min_secs  14*hr_secs+min_secs   ] ;
on_off_range ( 7, :)    = [16*hr_secs-2*min_secs  16*hr_secs+min_secs   ] ;
on_off_range ( 8, :)    = [18*hr_secs-2*min_secs  18*hr_secs+min_secs   ] ;
on_off_range ( 9, :)    = [today_dusk-2*hr_secs   today_dusk            ] ;
on_off_range (10, :)    = [tomorrow_dawn                                ...
                           tomorrow_dawn+2*hr_secs                      ] ;
on_off_range (11, :)    = [30*hr_secs-2*min_secs  30*hr_secs+min_secs   ] ;
on_off_range (12, :)    = [32*hr_secs-2*min_secs  32*hr_secs+min_secs   ] ;
on_off_range (13, :)    = [34*hr_secs-2*min_secs  34*hr_secs+min_secs   ] ;
on_off_range (14, :)    = [36*hr_secs-2*min_secs  36*hr_secs+min_secs   ] ;
on_off_range (15, :)    = [38*hr_secs-2*min_secs  38*hr_secs+min_secs   ] ;
on_off_range (16, :)    = [40*hr_secs-2*min_secs  40*hr_secs+min_secs   ] ;
on_off_range (17, :)    = [42*hr_secs-2*min_secs  42*hr_secs+min_secs   ] ;
on_off_range (18, :)    = [tomorrow_dusk-2*hr_secs                      ...
                           tomorrow_dusk                                ] ;
on_off_range (19, :)    = [ 6*hr_secs              6*hr_secs            ] ;
on_off_range (20, :)    = [30*hr_secs             30*hr_secs            ] ;

on_off_range            = on_off_range + day_start ;

on_off_range_size       = size (on_off_range) ;
on_off_range_length     = on_off_range_size (1) ;

end_range               = uint32 (max (max (on_off_range))) ;

%---------------------------------------------------------------------------
%   Schedule Memory contents.  It includes an extra value available for
%   extended operations when the event occurs.
%---------------------------------------------------------------------------

bit_ids         = [off_in timingchg_in startup_in shutdown_in timingchg_in] ;

turnoff_id_c    = 0 ;
timingchg_id_c  = 1 ;
startup_id_c    = 2 ;
shutdown_id_c   = 3 ;
listen_id_c     = 4 ;

base_dawn       = double (day_start + today_dawn) ;
base_dusk       = double (day_start + today_dusk) ;
base_dawn2      = double (day_start + tomorrow_dawn) ;
base_dusk2      = double (day_start + tomorrow_dusk) ;

mem             = zeros (1, 3, 'double') ;

mem (1, :)      = [startup_id_c               10+base_dawn           0] ;
mem (2, :)      = [timingchg_id_c            130+base_dawn       -3610] ;
mem (3, :)      = [listen_id_c      10*3600-1*60+day_start           1] ;
mem (4, :)      = [listen_id_c     10*3600+15*60+day_start           0] ;
mem (5, :)      = [timingchg_id_c     14*3600+12+day_start      172800] ;
mem (6, :)      = [listen_id_c            172000+base_dusk           1] ;
mem (7, :)      = [listen_id_c            172400+base_dawn2          0] ;

end_time        = 345600 + base_seconds ;

mem_size        = size (mem) ;
mem_cnt         = mem_size (1) ;


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
    seconds                     = uint32 (base_seconds) ;
    last_seconds                = uint32 (0) ;

    while (shutdown == 0 || busy == 1)

      if (seconds > end_range || listen_last ~= listen)

        %   Advance the ranges by days if they have already all passed.

        while (seconds > end_range)
          on_off_range          = on_off_range + day_secs ;
          end_range             = uint32 (max (max (on_off_range))) ;
        end ;

        %   Update the listen ranges when the listen mode changes.
        %   They are empty when listen mode is zero and 12 hours when it
        %   is one.

        listen_last             = listen ;

        if (listen == 0)
          on_off_range (19, 2)  = on_off_range (19, 1) ;
          on_off_range (20, 2)  = on_off_range (20, 1) ;
        else
          on_off_range (19, 2)  = on_off_range (19, 1) + 12 * hr_secs ;
          on_off_range (20, 2)  = on_off_range (20, 1) + 12 * hr_secs ;
        end

        %   Update the ranges in the argment list.

        for i = 1 : on_off_range_length
          on_off                = uint64 (on_off_range (i, :)) ;
          on_off_value          = bitshift (on_off (1), er_str_shift) + ...
                                  bitshift (on_off (2), er_end_shift) ;
          in_vect {on_off_times01_in+i-1} =                             ...
                                  fi (on_off_value,                     ...
                                      in_sig (on_off_times01_in, 3),    ...
                                      in_sig (on_off_times01_in, 1),    ...
                                      in_sig (on_off_times01_in, 2)) ;
        end ;

        %   Indicate that a timing change has occured.

        timingchg               = 1 - timingchg_last ;

        in_vect {timingchg_in}  = fi (timingchg,                        ...
                                      in_sig (timingchg_in, 3),         ...
                                      in_sig (timingchg_in, 1),         ...
                                      in_sig (timingchg_in, 2)) ;
      end ;

      %   Take a simulation step.

      [out_vect{:}] = step (sim_hdl, in_vect {:}) ;

      timingchg_last            = timingchg ;

      clock                     = clock + uint32 (1) ;

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

        %   Deactivate some signals currently activated.

        for i = 1 : length (bit_ids)
          if (i - 1 ~= listen_id_c && i - 1 ~= timingchg_id_c)
            in_index            = bit_ids (i) ;

            in_vect {in_index}  = fi (0,                                ...
                                      in_sig (in_index, 3),             ...
                                      in_sig (in_index, 1),             ...
                                      in_sig (in_index, 2)) ;
          end
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

              if (mem (i, 1) == timingchg_id_c)
                new_seconds       = uint32 (double (seconds) + mem (i, 3)) ;
                timingchg         = 1 - timingchg_last ;

                in_vect {in_index}  = fi (timingchg,                    ...
                                          in_sig (in_index, 3),         ...
                                          in_sig (in_index, 1),         ...
                                          in_sig (in_index, 2)) ;

              elseif (mem (i, 1) == listen_id_c)
                listen            = mem (i, 3) ;

              else
                in_vect {in_index}  = fi (1,                            ...
                                          in_sig (in_index, 3),         ...
                                          in_sig (in_index, 1),         ...
                                          in_sig (in_index, 2)) ;
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

        %   Set the alarm state immediately.

        in_vect {alarm_set_in}    =                                     ...
                      fi (uint32 (out_vect {alarm_set_out}),            ...
                          in_sig (alarm_set_in, 3),                     ...
                          in_sig (alarm_set_in, 1),                     ...
                          in_sig (alarm_set_in, 2)) ;

        %   Set the shutdown state from the turnoff signal.

        in_vect {shutdown_in}     =                                     ...
                      fi (uint32 (out_vect {off_out}),                  ...
                          in_sig (shutdown_in, 3),                      ...
                          in_sig (shutdown_in, 1),                      ...
                          in_sig (shutdown_in, 2)) ;

        %   Update the time by the alarm amount when shutdown is done and
        %   signal a restart.

        if (uint32 (out_vect {shutdown_out}) == 1)
          seconds                 = seconds + uint32 (out_vect {alarm_out}) ;
          in_vect {startup_in}    = fi (1,                              ...
                                        in_sig (startup_in, 3),         ...
                                        in_sig (startup_in, 1),         ...
                                        in_sig (startup_in, 2)) ;
        end

        %   Set the shutdown state from the end.

        if (seconds >= end_time)
          shutdown                = uint32 (1) ;
        end

        %   Update the time.

        if (seconds ~= last_seconds)
          last_seconds            = seconds ;

          in_vect {rtctime_in}  = fi (seconds,                          ...
                                        in_sig (rtctime_in, 3),         ...
                                        in_sig (rtctime_in, 1),         ...
                                        in_sig (rtctime_in, 2)) ;
        end

        %   Capture the busy state of the component.

        busy                      = uint32 (out_vect {busy_out}) ;
      end

      %   Update the second counter.

      if (rem (clock, clocks_per_sec) == 0)
        seconds                   = seconds + uint32 (1) ;

        if (rem (seconds, 60) == 0)
          offset                  = double (seconds) - day_start ;
          days                    = int32 (fix (offset / double (day_secs))) ;
          offset                  =        rem (offset,  double (day_secs)) ;
          hours                   = int32 (fix (offset / double (hr_secs))) ;
          offset                  =        rem (offset,  double (hr_secs)) ;
          minutes                 = int32 (fix (offset / double (min_secs))) ;
          fprintf (1, '%d %d_%02d:%02d\n',                              ...
                   int32 (double (seconds) - base_seconds),             ...
                   days, hours, minutes) ;
        end
      end
    end

end
