function ParseTextFieldTest_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_parsetextfieldtest;

%-----------------------------------------------------------------
% Messages to try to find.  The 5 at the end of each message should
% never be reached.
%-----------------------------------------------------------------

mlist      = [1 6 5 ; 1 96 5 ; 1 12 5 ; 13 3 5 ; 13 12 5 ; 8 12 5] ;

%-----------------------------------------------------------------
% All UBX messages.
%-----------------------------------------------------------------

ids        = [1 0] ;
msgs       = ones (length (ids), 2) .* 5 ;   % ACK
msgs (:,2) = ids ;
ubxtbl     = [msgs] ;
ids        = [48 50 80 51 16 49 2 10] ;
msgs       = ones (length (ids), 2) .* 11 ;  % AID
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;
ids        = [19 9 6 18 41 14 2 57 1 36 35 23 34 59 50 0 8 52 4 ...
              17 22 61 29 49 7 27] ;
msgs       = ones (length (ids), 2) .* 6 ;   % CFG
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;
ids        = [2 16] ;
msgs       = ones (length (ids), 2) .* 16 ;  % ESF
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;
ids        = [4 0 2 3 1] ;
msgs       = ones (length (ids), 2) .* 4  ;  % INF
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;
ids        = [11 9 2 6 7 33 8 4] ;
msgs       = ones (length (ids), 2) .* 10 ;  % MON
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;
ids        = [96 34 49 4 64 1 2 50 6 3 48 32 33 17 18] ;
msgs       = ones (length (ids), 2) .* 1  ;  % NAV
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;
ids        = [48 49 65 16 17 32] ;
msgs       = ones (length (ids), 2) .* 2  ;  % RXM
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;
ids        = [4 3 1 6] ;
msgs       = ones (length (ids), 2) .* 13 ;  % TIM
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;

strtbl  = cell (1, length (ubxtbl)) ;
for k = 1 : length (ubxtbl)
  strtbl (k) = {char(ubxtbl (k,:))} ;
end

ubxtree = text_tree (strtbl) ;

%-----------------------------------------------------------------
% Memory contents
%-----------------------------------------------------------------

meminit = uint8([17 9 9 5 3 2 9 9 9 9 8 8 8 8 5 2 3 8     ...
                  8 9 3 3 2 2 9 8 8                       ...
                 10 2 3 4 4 5 8 8 9 9 9                   ...
                  0 7 1 22 13 31 6 0 96 3 3 5             ...
                  0 18 27                                 ...
                  1 6 1 96 13 3]) ;

% Replace memory contents with tree.

meminit = zeros (1, length (ubxtree) * 3, 'uint8') ;

for k = 0 : length (ubxtree) - 1
  value           = ubxtree (k+1) ;
  meminit (k*3+1) = uint8 (bitand (value, 255)) ;
  meminit (k*3+2) = uint8 (bitshift (bitand (value, 255*256), -8)) ;
  meminit (k*3+3) = uint8 (bitshift (bitand (value, 255*256*256), -16)) ;
end

mem     = [meminit zeros(1, 512-length(meminit),'uint8')] ;

% Simulate for trials (this will be the length of the simulation)
Trial_count   = length (mlist) ;
clocks_needed =   1 ;   % Clock cycles needed per trial.

%-----------------------------------------------------------------
% Define the input signals and other needed signal information.
% The word width of the fixed point data type must match the
% width of the std_logic_vector input.  Signals that are
% std_logic have a width of 1.
%-----------------------------------------------------------------
in1_signal_width        = 1 ; % run
in1_signal_signed       = 0 ;   % 0 - unsigned, 1 - signed
in1_signal_fraction     = 0 ;   % bits of width that are fraction bits.

in2_signal_width        = 8 ; % inchar
in2_signal_signed       = 0 ;
in2_signal_fraction     = 0 ;

in3_signal_width        = 1 ; % inready
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
out4_signal_width       = 1 ; % valid
out5_signal_width       = 2 ; % result


%-----------------------------------------------------------------
% Clock through the module.
%-----------------------------------------------------------------

for trialno=1:Trial_count
    %-----------------------------------------------------------------
    % Create our input vector at each trial, which must be a
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
    in4_signal_value  = 0 ;
    input_vector4     = fi (in4_signal_value, in4_signal_signed,          ...
                            in4_signal_width, in4_signal_fraction) ;
    in5_signal_value  = 0 ;
    input_vector5     = fi (in5_signal_value, in5_signal_signed,          ...
                            in5_signal_width, in5_signal_fraction) ;

    for k = 1:3
      [output_vector1, output_vector2, output_vector3, output_vector4,    ...
                       output_vector5] =                                  ...
          step (sim_hdl, input_vector1, input_vector2, input_vector3,     ...
                         input_vector4, input_vector5) ;
    end

    %   Start a new message.

    message = mlist (trialno,:) ;

    for ii = 1:length(message)
      in1_signal_value  = 1 ;
      input_vector1     = fi (in1_signal_value, in1_signal_signed,        ...
                              in1_signal_width, in1_signal_fraction) ;
      in2_signal_value  = 0 ;
      input_vector2     = fi (in2_signal_value, in2_signal_signed,        ...
                              in2_signal_width, in2_signal_fraction) ;
      in3_signal_value  = 0 ;
      input_vector3     = fi (in3_signal_value, in3_signal_signed,        ...
                              in3_signal_width, in3_signal_fraction) ;
      in4_signal_value  = 0 ;
      input_vector4     = fi (in4_signal_value, in4_signal_signed,        ...
                              in4_signal_width, in4_signal_fraction) ;
      in5_signal_value  = 0 ;
      input_vector5     = fi (in5_signal_value, in5_signal_signed,        ...
                              in5_signal_width, in5_signal_fraction) ;

      %   Wait for some cycles before providing a byte.

      for k = 1:3
        [output_vector1, output_vector2, output_vector3, output_vector4,  ...
                         output_vector5] =                                ...
            step (sim_hdl, input_vector1, input_vector2, input_vector3,   ...
                           input_vector4, input_vector5) ;

        %   memrcv always follows memreq
        %   memdata is only changed when memread_en is set.

        in5_signal_value  = output_vector1 ;
        input_vector5     = fi (in5_signal_value, in5_signal_signed,      ...
                                in5_signal_width, in5_signal_fraction) ;

        if (output_vector3.bin == '1')
          in4_signal_value  = mem (output_vector2 + 1) ;
          input_vector4     = fi (in4_signal_value, in4_signal_signed,    ...
                                  in4_signal_width, in4_signal_fraction) ;
        end
      end

      in2_signal_value  = message (ii) ;
      input_vector2     = fi (in2_signal_value, in2_signal_signed,        ...
                              in2_signal_width, in2_signal_fraction) ;
      in3_signal_value  = 1 ;
      input_vector3     = fi (in3_signal_value, in3_signal_signed,        ...
                              in3_signal_width, in3_signal_fraction) ;

      %   Wait until the byte has been completed.

      run_cnt = 6 ;

      while (run_cnt > 0)
        [output_vector1, output_vector2, output_vector3, output_vector4,    ...
                         output_vector5] =                                  ...
            step (sim_hdl, input_vector1, input_vector2, input_vector3,     ...
                           input_vector4, input_vector5) ;

        %   memrcv always follows memreq
        %   memdata is only changed when memread_en is set.

        in5_signal_value  = output_vector1 ;
        input_vector5     = fi (in5_signal_value, in5_signal_signed,        ...
                                in5_signal_width, in5_signal_fraction) ;

        if (output_vector3.bin == '1')
          in4_signal_value  = mem (output_vector2 + 1) ;
          input_vector4     = fi (in4_signal_value, in4_signal_signed,      ...
                                  in4_signal_width, in4_signal_fraction) ;
        end

        if (output_vector1.bin == '0')
          run_cnt = run_cnt - 1 ;
        else
          run_cnt = 6 ;
        end
      end

      in3_signal_value  = 0 ;
      input_vector3     = fi (in3_signal_value, in3_signal_signed,          ...
                              in3_signal_width, in3_signal_fraction) ;

      %   Wait for more cycles before providing the next byte.

      for k = 1:4
        [output_vector1, output_vector2, output_vector3, output_vector4,    ...
                         output_vector5] =                                  ...
            step (sim_hdl, input_vector1, input_vector2, input_vector3,     ...
                           input_vector4, input_vector5) ;

        %   memrcv always follows memreq
        %   memdata is only changed when memread_en is set.

        in5_signal_value  = output_vector1 ;
        input_vector5     = fi (in5_signal_value, in5_signal_signed,        ...
                                in5_signal_width, in5_signal_fraction) ;

        if (output_vector3.bin == '1')
          in4_signal_value  = mem (output_vector2 + 1) ;
          input_vector4     = fi (in4_signal_value, in4_signal_signed,      ...
                                  in4_signal_width, in4_signal_fraction) ;
        end
      end
    end

end
