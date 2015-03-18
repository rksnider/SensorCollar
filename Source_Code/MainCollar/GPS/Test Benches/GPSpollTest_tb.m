function GPSpollTest_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_gpspoll;


%-----------------------------------------------------------------
% Messages to request.
%-----------------------------------------------------------------

reqs = [1 3 2 0 7 2 6 5 1 4] ;

%-----------------------------------------------------------------
% Memory contents
%-----------------------------------------------------------------

meminit = uint8([17 9 9 5 3 2 9 9 9 9 8 8 8 8 5 2 3 8     ...
                  8 9 3 3 2 2 9 8 8                       ...
                 10 2 3 4 4 5 8 8 9 9 9                   ...
                  0 7 1 22 13 31 6 0 96 3 3 5             ...
                  0 18 27                                 ...
                  1 6 1 96 13 3]) ;

mem     = [meminit zeros(1, 512-length(meminit), 'uint8')] ;

% Simulate for trials (this will be the length of the simulation)
Trial_count   = length (reqs) ;
clocks_needed =   1 ;   % Clock cycles needed per trial.

%-----------------------------------------------------------------
% Define the input signals and other needed signal information.
% The word width of the fixed point data type must match the
% width of the std_logic_vector input.  Signals that are
% std_logic have a width of 1.
%-----------------------------------------------------------------
in1_signal_width        = 66 ; % curtime
in1_signal_signed       = 0 ;   % 0 - unsigned, 1 - signed
in1_signal_fraction     = 0 ;   % bits of width that are fraction bits.

in1_signal_incr         = uint64 (fix((1 / 8) * (2 ^ 20))) ;
in1_signal_value        = uint64 (4) * in1_signal_incr ;

in2_signal_width        = 14 ; % pollinterval
in2_signal_signed       = 0 ;
in2_signal_fraction     = 0 ;
in2_signal_value        = 1 ;
input_vector2           = fi (in2_signal_value, in2_signal_signed,    ...
                              in2_signal_width, in2_signal_fraction) ;

in3_signal_width        = 3 ; % pollmessages
in3_signal_signed       = 0 ;
in3_signal_fraction     = 0 ;

in4_signal_width        = 1 ; % sendready
in4_signal_signed       = 0 ;
in4_signal_fraction     = 0 ;

in5_signal_width        = 1 ; % sendrcv
in5_signal_signed       = 0 ;
in5_signal_fraction     = 0 ;

in6_signal_width        = 8 ; % meminput
in6_signal_signed       = 0 ;
in6_signal_fraction     = 0 ;

in7_signal_width        = 1 ; % memrcv
in7_signal_signed       = 0 ;
in7_signal_fraction     = 0 ;

out1_signal_width       = 1 ; % memreq
out2_signal_width       = 9 ; % memaddr
out3_signal_width       = 1 ; % memread_en
out4_signal_width       = 1 ; % sendreq
out5_signal_width       = 8 ; % msgclass
out6_signal_width       = 8 ; % msgid
out7_signal_width       = 1 ; % outsend


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
    % The current time is incremented each clock cycle.

    in1_signal_value  = in1_signal_value + in1_signal_incr ;
    input_vector1     = fi (in1_signal_value, in1_signal_signed,          ...
                            in1_signal_width, in1_signal_fraction) ;
    in3_signal_value  = 0 ;
    input_vector3     = fi (in3_signal_value, in3_signal_signed,          ...
                            in3_signal_width, in3_signal_fraction) ;
    in4_signal_value  = 0 ;
    input_vector4     = fi (in4_signal_value, in4_signal_signed,          ...
                            in4_signal_width, in4_signal_fraction) ;
    in5_signal_value  = 0 ;
    input_vector5     = fi (in5_signal_value, in5_signal_signed,          ...
                            in5_signal_width, in5_signal_fraction) ;
    in6_signal_value  = uint8 (0) ;
    input_vector6     = fi (in6_signal_value, in6_signal_signed,          ...
                            in6_signal_width, in6_signal_fraction) ;
    in7_signal_value  = 0 ;
    input_vector7     = fi (in7_signal_value, in7_signal_signed,          ...
                            in7_signal_width, in7_signal_fraction) ;

    for k = 1:3
      [output_vector1, output_vector2, output_vector3, output_vector4,    ...
                       output_vector5, output_vector6, output_vector7] =  ...
          step (sim_hdl, input_vector1, input_vector2, input_vector3,     ...
                         input_vector4, input_vector5, input_vector6,     ...
                         input_vector7) ;

      in1_signal_value  = in1_signal_value + in1_signal_incr ;
      input_vector1     = fi (in1_signal_value, in1_signal_signed,        ...
                              in1_signal_width, in1_signal_fraction) ;
    end

    %   Start a new request set.
    %   The sender starts as ready.
    %   The send receive signal always follows the send request signal immediately.
    %   The memory input is set from the address only when read enable is set.
    %   The memory receive signal always immediatly follows the memory request.

    message = reqs (trialno) ;

    in3_signal_value  = message ;
    input_vector3     = fi (in3_signal_value, in3_signal_signed,          ...
                            in3_signal_width, in3_signal_fraction) ;
    in4_signal_value  = 1 ;
    input_vector4     = fi (in4_signal_value, in4_signal_signed,          ...
                            in4_signal_width, in4_signal_fraction) ;
    in5_signal_value  = output_vector4 ;
    input_vector5     = fi (in5_signal_value, in5_signal_signed,          ...
                            in5_signal_width, in5_signal_fraction) ;

    if (output_vector3.bin == '1')
      in6_signal_value  = mem (output_vector2 + 1) ;
      input_vector6     = fi (in6_signal_value, in6_signal_signed,        ...
                              in6_signal_width, in6_signal_fraction) ;
    end

    in7_signal_value  = output_vector1 ;
    input_vector7     = fi (in7_signal_value, in7_signal_signed,          ...
                            in7_signal_width, in7_signal_fraction) ;

    %   Send the data as it is generated.

    done              = 0 ;
    req_count         = 0 ;

    while (done == 0)
      [output_vector1, output_vector2, output_vector3, output_vector4,    ...
                       output_vector5, output_vector6, output_vector7] =  ...
          step (sim_hdl, input_vector1, input_vector2, input_vector3,     ...
                         input_vector4, input_vector5, input_vector6,     ...
                         input_vector7) ;

      %   Clock is incremented.
      %   The send receive signal always follows the send request signal immediately.
      %   The memory input is set from the address only when read enable is set.
      %   The memory receive signal always immediatly follows the memory request.

      in1_signal_value  = in1_signal_value + in1_signal_incr ;
      input_vector1     = fi (in1_signal_value, in1_signal_signed,        ...
                              in1_signal_width, in1_signal_fraction) ;

      in5_signal_value  = output_vector4 ;
      input_vector5     = fi (in5_signal_value, in5_signal_signed,          ...
                              in5_signal_width, in5_signal_fraction) ;

      if (output_vector3.bin == '1')
        in6_signal_value  = mem (output_vector2 + 1) ;
        input_vector6     = fi (in6_signal_value, in6_signal_signed,        ...
                                in6_signal_width, in6_signal_fraction) ;
      end

      in7_signal_value  = output_vector1 ;
      input_vector7     = fi (in7_signal_value, in7_signal_signed,          ...
                              in7_signal_width, in7_signal_fraction) ;

      %   Send ready follows output send reversed.

      in4_signal_value  = (output_vector7.bin == '0') ;
      input_vector4     = fi (in4_signal_value, in4_signal_signed,          ...
                              in4_signal_width, in4_signal_fraction) ;

      %   Check to see if the output has finished for a period of time.

      if (output_vector4.bin == '0')
        if (req_count == 10)
          done = 1 ;
        else
          req_count = req_count + 1 ;
        end
      else
        req_count = 0 ;
      end
    end

end
