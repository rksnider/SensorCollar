function GPSscheduler_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_gpsscheduler;


%---------------------------------------------------------------------------
%   Simulation Definitions.
%---------------------------------------------------------------------------

sysclk_freq_g           = 50 ;

StepsPerClock           = 4 ;

sim_steprate            = sysclk_freq_g * StepsPerClock ;

clocks_per_sec          = uint32 (StepsPerClock * sysclk_freq_g) ;

timemark_period         = uint32 (StepsPerClock * 256) ;
aop_status_period       = uint32 (StepsPerClock * 25) ;
aop_status              = uint32 (0) ;
aop_running             = uint32 (0) ;
aop_running_cnt         = uint32 (13) ;
running_cnt             = uint32 (0) ;

% Simulate for trials (this will be the length of the simulation)

Trial_count   =   1 ;
clocks_needed =   1 ;   % Clock cycles needed per trial.

%---------------------------------------------------------------------------
%   Package and Generic definitions.
%---------------------------------------------------------------------------

sched_count_g         = 8 ;
millisec_week_c       = 7 * 24 * 60 * 60 * 1000 ;

sched_id_bits_c       = fix (log2 (sched_count_g-1)) + 1 ;
sched_delay_bits_c    = fix (log2 (millisec_week_c / 1000 - 1)) + 1 ;


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

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
turnon_in               = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
turnoff_in              = in_count ;

%   GPS power control.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
power_in                = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
power_out               = out_count ;


%   Initialization

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
init_in                 = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
init_out                = out_count ;

%   GPS control

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
timemark_in             = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 14 ;
pollint_out             = out_count ;

%   AOP.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
aop_updated_in          = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
aop_running_in          = in_count ;

%   Scheduler Allocation

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
sched_req_out           = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
sched_rcv_in            = in_count ;

%   Scheduler Control

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

%   Busy processing.

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
busy_out                = out_count ;


%-----------------------------------------------------------------
%   Schedule Memory contents
%-----------------------------------------------------------------

bit_ids       = [turnon_in turnoff_in startup_in shutdown_in] ;

turnon_id_c   = 0 ;
turnoff_id_c  = 1 ;
startup_id_c  = 2 ;
shutdown_id_c = 3 ;

mem           = zeros (1, 2) ;

mem (1, :)    = [startup_id_c       10] ;
mem (2, :)    = [shutdown_id_c    3600] ;

mem_cnt       = 2 ;


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

    timemark                    = uint32 (0) ;
    timemark_skip               = uint32 (1) ;

    clock                       = uint32 (0) ;
    seconds                     = uint32 (0) ;

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
                                  seconds ;

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

                mem (insert, :)   = [sched_id sched_delay] ;
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

          for i = 1 : mem_cnt
            if (mem (i, 2) <= seconds)
              remove_cnt          = remove_cnt + 1 ;

              in_index            = bit_ids (mem (i, 1) + 1) ;

              in_vect {in_index}  = fi (1,                              ...
                                        in_sig (in_index, 3),           ...
                                        in_sig (in_index, 1),           ...
                                        in_sig (in_index, 2)) ;
            end
          end

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

        %   Switch the timemark skip state when power comes back on.

        if (uint32 (in_vect  {power_in})  == 0 &&                       ...
            uint32 (out_vect {power_out}) == 1)
          timemark_skip           = uint32 (1) - timemark_skip ;
        end

        %   Set the power state immediately.

        in_vect {power_in}        = fi (uint32 (out_vect {power_out}),  ...
                                        in_sig (power_in, 3),           ...
                                        in_sig (power_in, 1),           ...
                                        in_sig (power_in, 2)) ;

        %   Set the shutdown state from the shutdown output.

        if (uint32 (out_vect {shutdown_out}) == 1)
          shutdown                = uint32 (1) ;
        end

        busy                      = uint32 (out_vect {busy_out}) ;
      end

      %   Update the second counter.

      if (rem (clock, clocks_per_sec) == 0)
        seconds                   = seconds + uint32 (1) ;
      end

      %   Change GPS signals when the device is powered up.

      if (in_vect {power_in} == 1)

        %   Change the timemark periodically.

        if (rem (clock, timemark_period) == 0 && timemark_skip == 0)
          timemark                  = 1 - timemark ;

          in_vect {timemark_in}     = fi (uint32 (timemark),            ...
                                          in_sig (timemark_in, 3),      ...
                                          in_sig (timemark_in, 1),      ...
                                          in_sig (timemark_in, 2)) ;
        end

        %   Change the aop status and running status periodically.

        running_cnt                 = running_cnt + uint32 (1) ;

        if (running_cnt == aop_running_cnt)
          running_cnt               = uint32 (0) ;

          aop_running               = uint32 (1) - aop_running ;
        end

        if (rem (clock, aop_status_period) == 0)
          aop_status                = uint32 (1) - aop_status ;

          in_vect {aop_updated_in}  = fi (aop_status,                   ...
                                          in_sig (aop_updated_in, 3),   ...
                                          in_sig (aop_updated_in, 1),   ...
                                          in_sig (aop_updated_in, 2)) ;

          in_vect {aop_running_in}  = fi (aop_running,                  ...
                                          in_sig (aop_running_in, 3),   ...
                                          in_sig (aop_running_in, 1),   ...
                                          in_sig (aop_running_in, 2)) ;
        end

      %   When powered down the GPS signals become zero.

      else
        aop_status                = uint32 (0) ;
        aop_running               = uint32 (0) ;
        in_vect {aop_updated_in}  = fi (aop_status,                     ...
                                        in_sig (aop_updated_in, 3),     ...
                                        in_sig (aop_updated_in, 1),     ...
                                        in_sig (aop_updated_in, 2)) ;
        in_vect {aop_running_in}  = fi (aop_running,                    ...
                                        in_sig (aop_running_in, 3),     ...
                                        in_sig (aop_running_in, 1),     ...
                                        in_sig (aop_running_in, 2)) ;
      end
    end

end
