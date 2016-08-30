function AOPstatusTest_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_aopstatustest;


%-----------------------------------------------------------------
% Messages to request.
%-----------------------------------------------------------------

try_info  = [0    ...   % message number
             0    ...   % temp bank
             0    ...   % AOP status config
             0 ;  ...   % AOP status status
             1 0 0 0 ; 1 0 1 0 ; 1 0 0 1 ; 1 0 1 1 ; 1 1 1 1 ; 0 1 1 1 ; ...
             1 1 1 0 ; 1 1 1 0 ; 1 1 1 0 ; 1 1 1 0 ; 1 1 1 0 ; 1 1 1 0] ;

%-----------------------------------------------------------------
% Memory contents
%-----------------------------------------------------------------

meminit = [17 9 9 5 3 2 9 9 9 9 8 8 8 8 5 2 3 8     ...
            8 9 3 3 2 2 9 8 8                       ...
           10 2 3 4 4 5 8 8 9 9 9                   ...
            0 7 1 22 13 31 6 0 96 3 3 5             ...
            0 18 27                                 ...
            1 6 1 96 13 3] ;

msg_rom_base                  = 0 ;
msg_ram_base                  = 59 ;
msg_ram_blocks                = 2 ;
msg_ram_temp_addr             = 45 * 2 ;
msg_ram_temp_size             = 30 ;

msg_ubx_nav_aopstatus_number  = 1 ;

munAOPstatus_config_offset    = 4 ;
munAOPstatus_config_size      = 1 ;

munAOPstatus_status_offset    = 5 ;
munAOPstatus_status_size      = 1 ;

% Simulate for trials (this will be the length of the simulation)
Trial_count   = length (try_info) ;
clocks_needed =  24 ;   % Clock cycles needed per trial.

%-----------------------------------------------------------------
% Define the input signals and other needed signal information.
% The word width of the fixed point data type must match the
% width of the std_logic_vector input.  Signals that are
% std_logic have a width of 1.
%-----------------------------------------------------------------
in1_signal_width        = 2 ; % msgnumber
in1_signal_signed       = 0 ;   % 0 - unsigned, 1 - signed
in1_signal_fraction     = 0 ;   % bits of width that are fraction bits.

in2_signal_width        = 1 ; % msgreceived
in2_signal_signed       = 0 ;
in2_signal_fraction     = 0 ;

in3_signal_width        = 1 ; % temp bank
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
out4_signal_width       = 1 ; % running
out5_signal_width       = 1 ; % updated
out6_signal_width       = 1 ; % busy


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

    in1_signal_value  = try_data (1) ;
    input_vector1     = fi (in1_signal_value, in1_signal_signed,          ...
                            in1_signal_width, in1_signal_fraction) ;
    in2_signal_value  = 0 ;
    input_vector2     = fi (in2_signal_value, in2_signal_signed,          ...
                            in2_signal_width, in2_signal_fraction) ;
    in3_signal_value  = try_data (2) ;
    input_vector3     = fi (in3_signal_value, in3_signal_signed,          ...
                            in3_signal_width, in3_signal_fraction) ;
    in4_signal_value  = 0 ;
    input_vector4     = fi (in4_signal_value, in4_signal_signed,          ...
                            in4_signal_width, in4_signal_fraction) ;
    in5_signal_value  = 0 ;
    input_vector5     = fi (in5_signal_value, in5_signal_signed,          ...
                            in5_signal_width, in5_signal_fraction) ;

    % Store the AOP status information in memory.

    addr = msg_ram_base + msg_ram_temp_addr +                             ...
           try_data (2) * msg_ram_temp_size + munAOPstatus_config_offset ;
    mem (addr + 1 : addr + munAOPstatus_config_offset) =                  ...
         byte_store (try_data (3), munAOPstatus_config_size) ;

    addr = msg_ram_base + msg_ram_temp_addr +                             ...
           try_data (2) * msg_ram_temp_size + munAOPstatus_status_offset ;
    mem (addr + 1 : addr + munAOPstatus_status_offset) =                  ...
         byte_store (try_data (4), munAOPstatus_status_size) ;

    % Execute the trial.

    received_cnt  = 0 ;

    for k = 1 : clocks_needed
      [output_vector1, output_vector2, output_vector3, output_vector4,    ...
       output_vector5, output_vector6] =                                  ...
          step (sim_hdl, input_vector1, input_vector2, input_vector3,     ...
                         input_vector4, input_vector5) ;

      %   The memory input is set from the address only when read enable is set.
      %   The memory receive signal always immediatly follows the memory request.

      if (output_vector3.bin == '1')
        in4_signal_value  = mem (output_vector2 + 1) ;
        input_vector4     = fi (in4_signal_value, in4_signal_signed,        ...
                                in4_signal_width, in4_signal_fraction) ;
      end

      in5_signal_value  = output_vector1 ;
      input_vector5     = fi (in5_signal_value, in5_signal_signed,          ...
                              in5_signal_width, in5_signal_fraction) ;

      %   Delay changing the message received a short time.

      if ((k == 10) || (k == 20))
          in2_signal_value  = 1 - in2_signal_value ;
          input_vector2     = fi (in2_signal_value, in2_signal_signed,      ...
                                  in2_signal_width, in2_signal_fraction) ;
      end
    end

end
