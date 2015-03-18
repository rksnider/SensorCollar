function GPSsendTest_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_gpssendtest;


%-----------------------------------------------------------------
% Messages to generate.
%-----------------------------------------------------------------

msgs = [1 6 ; 13 3 ; 1 96] ;

%-----------------------------------------------------------------
% Memory contents
%-----------------------------------------------------------------

meminit = [17 9 9 5 3 2 9 9 9 9 8 8 8 8 5 2 3 8     ...
            8 9 3 3 2 2 9 8 8                       ...
           10 2 3 4 4 5 8 8 9 9 9                   ...
            0 7 1 22 13 31 6 0 96 3 3 5             ...
            0 18 27                                 ...
            1 6 1 96 13 3] ;

mem     = [meminit zeros(1, 512-length(meminit))] ;

% Simulate for trials (this will be the length of the simulation)
Trial_count   = length (msgs) ;
clocks_needed =   1 ;   % Clock cycles needed per trial.

%-----------------------------------------------------------------
% Define the input signals and other needed signal information.
% The word width of the fixed point data type must match the
% width of the std_logic_vector input.  Signals that are
% std_logic have a width of 1.
%-----------------------------------------------------------------
in1_signal_width        = 1 ; % outready
in1_signal_signed       = 0 ;   % 0 - unsigned, 1 - signed
in1_signal_fraction     = 0 ;   % bits of width that are fraction bits.

in2_signal_width        = 8 ; % msgclass
in2_signal_signed       = 0 ;
in2_signal_fraction     = 0 ;

in3_signal_width        = 8 ; % msgid
in3_signal_signed       = 0 ;
in3_signal_fraction     = 0 ;

in4_signal_width        = 9 ; % memstart
in4_signal_signed       = 0 ;
in4_signal_fraction     = 0 ;
in4_signal_value        = 0 ;
input_vector4           = fi (in4_signal_value, in4_signal_signed,    ...
                              in4_signal_width, in4_signal_fraction) ;

in5_signal_width        = 16 ;  % memlength
in5_signal_signed       = 0 ;
in5_signal_fraction     = 0 ;
in5_signal_value        = 0 ;
input_vector5           = fi (in5_signal_value, in5_signal_signed,    ...
                              in5_signal_width, in5_signal_fraction) ;

in6_signal_width        = 8 ; % meminput
in6_signal_signed       = 0 ;
in6_signal_fraction     = 0 ;

in7_signal_width        = 1 ; % memrcv
in7_signal_signed       = 0 ;
in7_signal_fraction     = 0 ;

out1_signal_width       = 1 ; % memreq
out2_signal_width       = 9 ; % memaddr
out3_signal_width       = 1 ; % memread_en
out4_signal_width       = 8 ; % outchar
out5_signal_width       = 1 ; % outsend
out6_signal_width       = 1 ; % outdone


%-----------------------------------------------------------------
% Clock through the module.
%-----------------------------------------------------------------

for trialno=1:Trial_count
    %-----------------------------------------------------------------
    % Create our input vectors at each trial, which must be a
    % fixed-point data type.
    %-----------------------------------------------------------------
    % Choose a random integer between [0 2^W-1] - Note: can't have a zero input....
    %in1_signal_value = randi([1 2^fixed_word_width-1],1,1) ;

    % Sample from input vector scaled and rounded.
    %in1_signal_value = fix(xx(trialno) * scale + 0.5);

    % Initialize a trial.

    in1_signal_value  = 0 ;
    input_vector1     = fi (in1_signal_value, in1_signal_signed,          ...
                            in1_signal_width, in1_signal_fraction) ;
    in2_signal_value  = 0 ;
    input_vector2     = fi (in2_signal_value, in2_signal_signed,          ...
                            in2_signal_width, in2_signal_fraction) ;
    in3_signal_value  = 0 ;
    input_vector3     = fi (in3_signal_value, in3_signal_signed,          ...
                            in3_signal_width, in3_signal_fraction) ;
    in6_signal_value  = 0 ;
    input_vector6     = fi (in6_signal_value, in6_signal_signed,          ...
                            in6_signal_width, in6_signal_fraction) ;
    in7_signal_value  = 0 ;
    input_vector7     = fi (in7_signal_value, in7_signal_signed,          ...
                            in7_signal_width, in7_signal_fraction) ;

    for k = 1:3
      [output_vector1, output_vector2, output_vector3, output_vector4,    ...
                       output_vector5, output_vector6] =                  ...
          step (sim_hdl, input_vector1, input_vector2, input_vector3,     ...
                         input_vector4, input_vector5, input_vector6,     ...
                         input_vector7) ;
    end

    %   Start a new message.

    message = msgs (trialno,:) ;

    in1_signal_value  = 1 ;
    input_vector1     = fi (in1_signal_value, in1_signal_signed,          ...
                            in1_signal_width, in1_signal_fraction) ;
    in2_signal_value  = message (1) ;
    input_vector2     = fi (in2_signal_value, in2_signal_signed,          ...
                            in2_signal_width, in2_signal_fraction) ;
    in3_signal_value  = message (2) ;
    input_vector3     = fi (in3_signal_value, in3_signal_signed,          ...
                            in3_signal_width, in3_signal_fraction) ;
    in6_signal_value  = 0 ;
    input_vector6     = fi (in6_signal_value, in6_signal_signed,          ...
                            in6_signal_width, in6_signal_fraction) ;
    in7_signal_value  = 0 ;
    input_vector7     = fi (in7_signal_value, in7_signal_signed,          ...
                            in7_signal_width, in7_signal_fraction) ;

    %   Send the data as it is generated.

    done              = 0 ;

    while (done == 0)
      [output_vector1, output_vector2, output_vector3, output_vector4,    ...
                       output_vector5, output_vector6] =                  ...
          step (sim_hdl, input_vector1, input_vector2, input_vector3,     ...
                         input_vector4, input_vector5, input_vector6,     ...
                         input_vector7) ;

      %   memrcv always follows memreq
      %   memdata is only changed when memread_en is set.

      in7_signal_value  = output_vector1 ;
      input_vector7     = fi (in7_signal_value, in7_signal_signed,        ...
                              in7_signal_width, in7_signal_fraction) ;

      if (output_vector3.bin == '1')
        in4_signal_value  = mem (output_vector2 + 1) ;
        input_vector4     = fi (in4_signal_value, in4_signal_signed,      ...
                                in4_signal_width, in4_signal_fraction) ;
      end

      %   Output ready follows output send reversed.

      in1_signal_value  = (output_vector5.bin == '0') ;
      input_vector1     = fi (in1_signal_value, in1_signal_signed,        ...
                              in1_signal_width, in1_signal_fraction) ;

      %   Check to see if the output has finished.

      if (output_vector6.bin == '1')
        done = 1 ;
      end
    end

end
