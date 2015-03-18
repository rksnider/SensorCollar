function ResourceMUXtest_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_resourcemux;

%-----------------------------------------------------------------
% Array of requesters and expected receivers per clock cycle.
%-----------------------------------------------------------------

reqs  = [0 4 5 21 17 17 21 21 5 5 6 6 4 4 0] ;
rcvs  = [0 0 4 4  4 16 16 16 16 1 1 2 2 4 4 0] ;

% Simulate for trials (this will be the length of the simulation)
Trial_count   = length (reqs) ;
clocks_needed =   1 ;   % Clock cycles needed per trial.

%-----------------------------------------------------------------
% Define the input signals and other needed signal information.
% The word width of the fixed point data type must match the
% width of the std_logic_vector input.  Signals that are
% std_logic have a width of 1.
%-----------------------------------------------------------------
in1_signal_width        = 5 ;
in1_signal_signed       = 0 ;   % 0 - unsigned, 1 - signed
in1_signal_fraction     = 0 ;   % bits of width that are fraction bits.

in2_signal_width        = 8 ;
in2_signal_signed       = 0 ;
in2_signal_fraction     = 0 ;

in3_signal_width        = 8 ;
in3_signal_signed       = 0 ;
in3_signal_fraction     = 0 ;

in4_signal_width        = 8 ;
in4_signal_signed       = 0 ;
in4_signal_fraction     = 0 ;

in5_signal_width        = 8 ;
in5_signal_signed       = 0 ;
in5_signal_fraction     = 0 ;

in6_signal_width        = 8 ;
in6_signal_signed       = 0 ;
in6_signal_fraction     = 0 ;

out1_signal_width       = 5 ;
out1_signal_signed      = 0 ;
out1_signal_fraction    = 0 ;

out2_signal_width       = 8 ;
out2_signal_signed      = 0 ;
out2_signal_fraction    = 0 ;

%-----------------------------------------------------------------
% Clock throught the module.
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

    in1_signal_value  = reqs (trialno) ;
    input_vector1     = fi (in1_signal_value, in1_signal_signed, ...
                            in1_signal_width, in1_signal_fraction) ;

    % Choose random integers between [0 256-1]
    in2_signal_value  = randi ([0 255], 1, 1) ;
    in3_signal_value  = randi ([0 255], 1, 1) ;
    in4_signal_value  = randi ([0 255], 1, 1) ;
    in5_signal_value  = randi ([0 255], 1, 1) ;
    in6_signal_value  = randi ([0 255], 1, 1) ;

    input_vector2     = fi (in2_signal_value, in2_signal_signed, ...
                            in2_signal_width, in2_signal_fraction) ;
    input_vector3     = fi (in3_signal_value, in3_signal_signed, ...
                            in3_signal_width, in3_signal_fraction) ;
    input_vector4     = fi (in4_signal_value, in4_signal_signed, ...
                            in4_signal_width, in4_signal_fraction) ;
    input_vector5     = fi (in5_signal_value, in5_signal_signed, ...
                            in5_signal_width, in5_signal_fraction) ;
    input_vector6     = fi (in6_signal_value, in6_signal_signed, ...
                            in6_signal_width, in6_signal_fraction) ;

    % Capture the inputs.
    input_history{trialno} = {input_vector1 input_vector2 input_vector3 ...
                              input_vector4 input_vector5 input_vector6} ;

    %-----------------------------------------------------------------
    % Push the input(s) into the component using the step function on the
    % system object sim_hdl
    % If there are multiple I/O, use
    % [out1, out2, out3] = step(sim_hdl, in1, in2, in3);
    % and understand all I/O data types are fixed-point objects
    % where the inputs can be created by the fi() function.
    %-----------------------------------------------------------------

    for k = 1:clocks_needed
      [output_vector1, output_vector2] =                                    ...
          step (sim_hdl, input_vector1, input_vector2, input_vector3,       ...
                         input_vector4, input_vector5, input_vector6) ;
    end

    % data_in_ready = fi(1,0,1,0);    % Start with data ready (std_logic).
    % output_ready  = fi(0,0,1,0);    % Wait until output is ready (std_logic).

    % for k = 1:clocks_needed
       % [output_vector1, output_ready] = step(sim_hdl,input_vector1,data_in_ready);
    % end

    %   Continue until output data is available (rather than for a fixed number of clock cycles.
    %   Input data is only available on the first clock cycle.

    % while (output_ready == 0)
        % [output_vector1, output_ready] = step(sim_hdl,input_vector1,data_in_ready);
        % data_in_ready.bin = '0';
    % end

    %-----------------------------------------------------------------
    % Save the outputs (which may not be fixed-point objects) as fixed
    % point objects.
    %-----------------------------------------------------------------

    output_history{trialno} = {cnv2fi(output_vector1), cnv2fi(output_vector2)} ;

    % input_vector1 = zero ;  % impulse signal is zero except for the first time.

end
%-----------------------------------------------------------------
% Display the captured I/O
%-----------------------------------------------------------------
display_this = 1 ;
if display_this == 1
    for trialno=1:Trial_count
        intbl   = input_history{trialno} ;
        outtbl  = output_history{trialno} ;

        in1     = intbl{1} ;
        in2     = intbl{2} ;
        in3     = intbl{3} ;
        in4     = intbl{4} ;
        in5     = intbl{5} ;
        in6     = intbl{6} ;
        out1    = outtbl{1} ;
        out2    = outtbl{2} ;
        fprintf (1, 'Trial %d: %s %s %s %s %s %s -> %s %s\n', trialno,    ...
                 in1.bin, in2.hex, in3.hex, in4.hex, in5.hex, in6.hex,    ...
                 out1.bin, out2.hex) ;
    end
end
%-----------------------------------------------------------------
% Perform the desired comparison (with the latency between input
% and output appropriately corrected).
%-----------------------------------------------------------------
latency     = 1;      % latency in clock cycles through component
max_error   = 0.001;  % maximum difference to allow before an error is indicated
error_index = 1;
error_case  = [];
for trialno=1:Trial_count-latency
    intbl   = input_history{trialno+latency} ;
    outtbl  = output_history{trialno+latency} ;
    out1    = outtbl{1} ;
    out2    = outtbl{2} ;

    % true_value = in1_signal_width - floor(log2(double(in1))) -  1;  % calculate "true" value
    % if isinf(true_value)
        % true_value = in1_signal_width;  % fix "true" value if we took log2(zero)
    % end

    % true_value = fix(yy_true(trialno) * scale + 0.5);

    % log2 must not be passed values <= 0.5 or it will return negative numbers.

    true_value  = rcvs (trialno+latency) ;
    kk          = fix (log2 (true_value + 0.6)) + 1 ;
    mux_value   = intbl {kk + 1} ;

    if out1.double ~= true_value || out2 ~= mux_value
        error_case{error_index}.trial_index = trialno;
        error_case{error_index}.input       = intbl;
        error_case{error_index}.output      = outtbl;
        error_case{error_index}.true_value  = true_value;
        error_case{error_index}.mux_value   = mux_value;
        error_index = error_index + 1;
    end
end
error_count = error_index - 1;
if error_count == 0
    disp(['No Errors detected'])
else
    disp(['ERROR: There were ' num2str(error_count) ' errors.'])
    disp(['ERROR: The errors occured at the following index locations:'])
    for k=1:error_count
        intbl       = error_case{k}.input ;
        outtbl      = error_case{k}.output ;
        true_value  = error_case{k}.true_value ;
        mux_value   = error_case{k}.mux_value ;
        in1         = intbl{1} ;
        in2         = intbl{2} ;
        in3         = intbl{3} ;
        in4         = intbl{4} ;
        in5         = intbl{5} ;
        in6         = intbl{6} ;
        out1        = outtbl{1} ;
        out2        = outtbl{2} ;

        fprintf (2,   ...
            'Error %d, trial %d: %s %s %s %s %s %s -> %s %s <> %X %s\n',  ...
            k, error_case{k}.trial_index,                                 ...
            in1.bin, in2.hex, in3.hex, in4.hex, in5.hex, in6.hex,         ...
            out1.hex, out2.hex, true_value, mux_value.hex) ;
    end
end

end
