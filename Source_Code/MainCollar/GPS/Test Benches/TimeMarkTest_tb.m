function TimeMarkTest_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_timemarktest;


%-----------------------------------------------------------------
% Timemark environments to test.
%-----------------------------------------------------------------

millis_per_week         = 1000 * 60 * 60 * 24 * 7 ;

try_info  = [0    ...   % position time clock offset in millisecs
             1    ...   % position bank
             0    ...   % timemark bank
             0 ;  ...   % position accuracy in cm
             0 1 0 0 ; 0 0 1 0 ; 0 0 0 5000 ; 0 0 0 15000 ;     ...
             1000000 0 1 8000 ; 2*millis_per_week 0 0 500 ;     ...
             millis_per_week 0 0 500 ; 70 0 0 200] ;

%-----------------------------------------------------------------
% Memory contents
%-----------------------------------------------------------------

meminit = [17 9 9 5 3 2 9 9 9 9 8 8 8 8 5 2 3 8     ...
            8 9 3 3 2 2 9 8 8                       ...
           10 2 3 4 4 5 8 8 9 9 9                   ...
            0 7 1 22 13 31 6 0 96 3 3 5             ...
            0 18 27                                 ...
            1 6 1 96 13 3] ;

msg_rom_base            = 0 ;
msg_ram_base            = 59 ;
msg_ram_blocks          = 2 ;
msg_ram_temp_addr       = 45 * 2 ;
msg_ram_temp_size       = 30 ;

msg_ram_postime_addr    = msg_ram_temp_addr + msg_ram_temp_size * 2 ;
msg_ram_postime_size    = 9 ;

msg_ram_marktime_addr   = msg_ram_postime_addr + msg_ram_postime_size * 2 ;
msg_ram_marktime_size   = 9 ;

msg_ubx_nav_sol_ramaddr = 0 ;
msg_ubx_nav_sol_ramused = 30 ;

munSol_pAcc_offset      = 23 ;
munSol_pAcc_size        = 4 ;

% Simulate for trials (this will be the length of the simulation)
Trial_count   = length (try_info) ;
clocks_needed =  50 ;   % Clock cycles needed per trial.

%-----------------------------------------------------------------
% Define the input signals and other needed signal information.
% The word width of the fixed point data type must match the
% width of the std_logic_vector input.  Signals that are
% std_logic have a width of 1.
%-----------------------------------------------------------------
in1_signal_width        = 66 ;  % curtimebits
in1_signal_signed       = 0 ;   % 0 - unsigned, 1 - signed
in1_signal_fraction     = 0 ;   % bits of width that are fraction bits.

% Start the clock at about four weeks. (1024 * 64 * 64 * 32 * 8 * 4) = 2^32
% (1000ms/s * 60s/m * 60m/h * 24h/d * 7d/w * 4w)

weekno                  = 4 ;
in1_signal_incr         = uint64 (fix((1 / 8) * (2 ^ 20))) ;
in1_signal_value        = uint64 (fix(2 ^ 35)) * in1_signal_incr ;

in2_signal_width        = 1 ; % position bank
in2_signal_signed       = 0 ;
in2_signal_fraction     = 0 ;

in3_signal_width        = 1 ; % time mark bank
in3_signal_signed       = 0 ;
in3_signal_fraction     = 0 ;

in4_signal_width        = 8 ; % memdata
in4_signal_signed       = 0 ;
in4_signal_fraction     = 0 ;

in5_signal_width        = 1 ; % memrcv
in5_signal_signed       = 0 ;
in5_signal_fraction     = 0 ;

out1_signal_width       = 1 ; % memreq
out2_signal_width       = 9 ; % memaddr
out3_signal_width       = 1 ; % memread_en
out4_signal_width       = 1 ; % memwrite_en
out5_signal_width       = 8 ; % memoutput
out6_signal_width       = 1 ; % marker
out7_signal_width       = 1 ; % req_position
out8_signal_width       = 1 ; % req_timemark


%-----------------------------------------------------------------
% Clock through the module.
%-----------------------------------------------------------------

for trialno=1:Trial_count
    mem       = [meminit zeros(1, 512-length(meminit))] ;

    try_data  = try_info (trialno, :) ;

    %-----------------------------------------------------------------
    % Create our input vectors at each trial, which must be a
    % fixed-point data type.
    %-----------------------------------------------------------------
    % Choose a random integer between [0 2^W-1] - Note: can't have a zero input....
    %in1_signal_value = randi([1 2^fixed_word_width-1],1,1) ;

    % Sample from input vector scaled and rounded.
    %in1_signal_value = fix(xx(trialno) * scale + 0.5);

    % Initialize a trial.
    % The current time is incremented each clock cycle.

    in1_signal_value  = in1_signal_value + in1_signal_incr ;
    input_vector1     = fi (in1_signal_value, in1_signal_signed,          ...
                            in1_signal_width, in1_signal_fraction) ;
    in2_signal_value  = try_data (2) ;
    input_vector2     = fi (in2_signal_value, in2_signal_signed,          ...
                            in2_signal_width, in2_signal_fraction) ;
    in3_signal_value  = try_data (3) ;
    input_vector3     = fi (in3_signal_value, in3_signal_signed,          ...
                            in3_signal_width, in3_signal_fraction) ;
    in4_signal_value  = 0 ;
    input_vector4     = fi (in4_signal_value, in4_signal_signed,          ...
                            in4_signal_width, in4_signal_fraction) ;
    in5_signal_value  = 0 ;
    input_vector5     = fi (in5_signal_value, in5_signal_signed,          ...
                            in5_signal_width, in5_signal_fraction) ;

    % Store the last position aquisition time in memory along with an updated
    % value.

    if (weekno * (2 ^ 50) + try_data (1) * (2 ^ 20) <= in1_signal_value)
      pos_offset = fix (try_data (1) * (2 ^ 20)) ;
    else
      pos_offset = fix ((2 ^ 30 - millis_per_week + try_data (1)) * (2 ^ 20)) ;
    end

    addr = msg_ram_base + msg_ram_postime_addr +                          ...
           try_data (2) * msg_ram_postime_size ;
    mem (addr + 1 : addr + msg_ram_postime_size) =                        ...
         byte_store (in1_signal_value - pos_offset, msg_ram_postime_size) ;

    addr = msg_ram_base + msg_ram_postime_addr +                          ...
           (1 - try_data (2)) * msg_ram_postime_size ;
    mem (addr + 1 : addr + msg_ram_postime_size) =                        ...
         byte_store (in1_signal_value, msg_ram_postime_size) ;

    % Store the position accuracy in memory along with an updated value.

    addr = msg_ram_base + msg_ubx_nav_sol_ramaddr +                       ...
           try_data (2) * msg_ubx_nav_sol_ramused + munSol_pAcc_offset ;
    mem (addr + 1 : addr + munSol_pAcc_size) =                            ...
         byte_store (try_data (4), munSol_pAcc_size) ;

    addr = msg_ram_base + msg_ubx_nav_sol_ramaddr +                       ...
           (1 - try_data (2)) * msg_ubx_nav_sol_ramused + munSol_pAcc_offset ;
    mem (addr + 1 : addr + munSol_pAcc_size) =                            ...
         byte_store (1000 , munSol_pAcc_size) ;

    % Execute the trial.

    req_poscnt  = 0 ;
    req_tmcnt   = 0 ;
    done        = 0 ;

    while (done == 0)
      [output_vector1, output_vector2, output_vector3, output_vector4,    ...
                       output_vector5, output_vector6, output_vector7,    ...
                       output_vector8] =                                  ...
          step (sim_hdl, input_vector1, input_vector2, input_vector3,     ...
                         input_vector4, input_vector5) ;

      %   Clock is incremented.
      %   The memory input is set from the address only when read enable is set.
      %   The memory receive signal always immediatly follows the memory request.

      in1_signal_value  = in1_signal_value + in1_signal_incr ;
      input_vector1     = fi (in1_signal_value, in1_signal_signed,        ...
                              in1_signal_width, in1_signal_fraction) ;

      if (output_vector3.bin == '1')
        in4_signal_value  = mem (output_vector2 + 1) ;
        input_vector4     = fi (in4_signal_value, in4_signal_signed,        ...
                                in4_signal_width, in4_signal_fraction) ;
      end

      in5_signal_value  = output_vector1 ;
      input_vector5     = fi (in5_signal_value, in5_signal_signed,          ...
                              in5_signal_width, in5_signal_fraction) ;

      %   Delay changes to the position and time mark banks for a short time
      %   after the requests show up.

      if (output_vector7.bin == '1')
        if (req_poscnt == 10)
          in2_signal_value  = 1 - in2_signal_value ;
          input_vector2     = fi (in2_signal_value, in2_signal_signed,      ...
                                  in2_signal_width, in2_signal_fraction) ;
          req_poscnt        = 0 ;
        else
          req_poscnt        = req_poscnt + 1 ;
        end
      else
        req_poscnt          = 0 ;
      end

      if (output_vector8.bin == '1')
        if (req_tmcnt == 10)
          in3_signal_value  = 1 - in3_signal_value ;
          input_vector3     = fi (in3_signal_value, in3_signal_signed,      ...
                                  in3_signal_width, in3_signal_fraction) ;
          req_tmcnt         = 0 ;
        else
          req_tmcnt         = req_tmcnt + 1 ;
        end
      else
        req_tmcnt           = 0 ;

        if (in3_signal_value == 1 - try_data (3))
          done              = 1 ;
        end
      end

    end

end
