function ResourceAllocator_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_resourceallocator;

%-----------------------------------------------------------------
% Array of requesters and expected receivers per clock cycle.
%-----------------------------------------------------------------

reqs  = [0 4 5 21 17 17 21 21 5 5 6 6 4 4 0] ;
rcvs  = [0 4 4  4 16 16 16 16 1 1 2 2 4 4 0] ;

% Simulate for trials (this will be the length of the simulation)
Trial_count   = length (reqs) ;
clocks_needed =   1 ;   % Clock cycles needed per trial.

%-----------------------------------------------------------------
% Define the input signals and other needed signal information.
% The word width of the fixed point data type must match the
% width of the std_logic_vector input.  Signals that are
% std_logic have a width of 1.
%-----------------------------------------------------------------
in1_signal_width        = 8 ;
in1_signal_signed       = 0 ;   % 0 - unsigned, 1 - signed
in1_signal_fraction     = 0 ;   % bits of width that are fraction bits.

out1_signal_width       = 8 ;
out1_signal_signed      = 0 ;
out1_signal_fraction    = 0 ;

out2_signal_width       = 3 ;
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
    input_vector1     = fi (in1_signal_value, in1_signal_signed,          ...
                            in1_signal_width, in1_signal_fraction) ;

    input_history{trialno} = input_vector1 ;  % capture the inputs

    %-----------------------------------------------------------------
    % Push the input(s) into the component using the step function on the
    % system object sim_hdl
    % If there are multiple I/O, use
    % [out1, out2, out3] = step(sim_hdl, in1, in2, in3);
    % and understand all I/O data types are fixed-point objects
    % where the inputs can be created by the fi() function.
    %-----------------------------------------------------------------

    for k = 1:clocks_needed
      [output_vector1, output_vector2] = step (sim_hdl, input_vector1) ;
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
    % Save the outputs (as fixed-point objects) they may or may not
    % have been returned as fixed point objects.
    %-----------------------------------------------------------------
    out1 = fi (output_vector1, out1_signal_signed,  ...
               out1_signal_width, out1_signal_fraction) ;
    out2 = fi (output_vector2, out2_signal_signed,  ...
               out2_signal_width, out2_signal_fraction) ;
    output_history{trialno} = [out1, out2] ;

    % input_vector1 = zero ;  % impulse signal is zero except for the first time.

end
%-----------------------------------------------------------------
% Display the captured I/O
%-----------------------------------------------------------------
display_this = 1 ;
if display_this == 1
    for trialno=1:Trial_count
        intbl  = input_history{trialno} ;
        outtbl = output_history{trialno} ;
        in1    = intbl(1) ;
        out1   = outtbl(1) ;
        out2   = outtbl(2) ;

        input_1_bin  = in1.bin   % Display the input for the trial in binary.
        output_1_bin = out1.bin  % Display the output for the trial in binary
        output_1_dec = out1.dec  % and in decimal.
        output_1_len = out1.WordLength
        output_2_bin = out2.bin
        output_2_dec = out2.dec
        output_2_len = out2.WordLength
    end
end
%-----------------------------------------------------------------
% Perform the desired comparison (with the latency between input
% and output appropriately corrected).
%-----------------------------------------------------------------
latency     = 0;      % latency in clock cycles through component
max_error   = 0.001;  % maximum difference to allow before an error is indicated
error_index = 1;
error_case  = [];
for trialno=1:Trial_count-latency
    intbl  = input_history{trialno};
    outtbl = output_history{trialno+latency};
    
    in1    = intbl(1) ;
    out1   = outtbl(1) ;
    out2   = outtbl(2) ;

    % true_value = in1_signal_width - floor(log2(double(in1))) -  1;  % calculate "true" value
    % if isinf(true_value)
        % true_value = in1_signal_width;  % fix "true" value if we took log2(zero)
    % end

    % true_value = fix(yy_true(trialno) * scale + 0.5);

    % if abs(true_value-double(out1)) > max_error

    true_value = rcvs(trialno) ;
    
    if out1.double ~= true_value
        error_case{error_index}.trial_index = trialno;
        error_case{error_index}.input       = in1;
        error_case{error_index}.output      = out1;
        error_case{error_index}.true_value  = true_value;
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
        error_number = k
        %size(error_case)
        %error_case{k}
        trial_number = error_case{k}.trial_index
        input_bin    = error_case{k}.input.bin
        output_dec   = error_case{k}.output.dec
        true_dec     = error_case{k}.true_value
    end
end

end
