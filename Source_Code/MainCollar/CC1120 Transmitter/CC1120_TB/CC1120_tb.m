function CC1120_tb

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_cc1120_top;
release(sim_hdl);

%% Simulation Definitions

sysclk_freq_g	= 50.0e6 ;                      % System clock frequency .
StepsPerClock	= 4 ;                           % Steps per clock ........
sim_steprate	= sysclk_freq_g*StepsPerClock;  % Simulation step rate ...
hold_time       = 8 ;                          % Hold time ..............


%% CC1120 Definitions 

% Various signal lengths in bits (multiplications convert from bytes to
% bits)
data_addr_len           = 8 ;               % Data rw address ............
time_len                = 9*8;              % Time array length ..........
data_in_len             = 8;                % Data in length .............
strobe_len              = 3*8;              % Command strobe length ......
packet_len              = 20  ;             % Packet length (assumed) ....
std_logic_len           = 1;                % Standard logic length ......
in_sig                  = zeros (1, 4) ;    % Input signal array .........
out_sig                 = zeros (1, 1) ;    % Output signal array ........

%% Signal initilization

% Basic definitions and initializations

in_count    = 0;                        % Number of input signals ........
out_count   = 0;                        % Number of ouput signals ........
signed      = 1;                        % fi function signed .............
unsigned    = 0;                        % fi function unsigned ...........

%% Input signal definitions

% startup_in
in_count = in_count + 1;
in_sig(in_count,:) = [1 0 unsigned 0];
startup_in = in_count;

% current_fpga_time_in
in_count = in_count + 1;
in_sig(in_count,:) = [time_len 0 unsigned 0];
current_fpga_time_in = in_count;

% data_addr_in
in_count = in_count + 1;
in_sig(in_count,:) = [data_addr_len 0 unsigned 0];
data_addr_in = in_count;

% data_len_in
in_count = in_count + 1;
in_sig(in_count,:) = [data_in_len 0 unsigned packet_len];
data_len_in = in_count;

% tx_en_in
in_count = in_count + 1;
in_sig(in_count,:) = [std_logic_len 0 unsigned 0];
tx_req_in = in_count;

% rx_en_in
in_count = in_count + 1;
in_sig(in_count,:) = [std_logic_len 0 unsigned 0];
rx_req_in = in_count;

% sleep_req_in
in_count = in_count + 1;
in_sig(in_count,:) = [std_logic_len 0 unsigned 0];
sleep_req_in = in_count;

% miso_in
in_count = in_count + 1;
in_sig(in_count,:) = [std_logic_len 0 unsigned 0];
miso_in = in_count;

% rx_rdy_in
in_count = in_count + 1;
in_sig(in_count,:) = [std_logic_len 0 unsigned 0];
rx_rdy_in = in_count;

%% Output signal definitions

% startup_complete_out
out_count = out_count + 1;
out_sig(out_count,:) = std_logic_len;
startup_complete_out = out_count;

% op_complete_out
out_count = out_count + 1;
out_sig(out_count,:) = std_logic_len;
op_complete_out = out_count;

% op_error_out
out_count = out_count + 1;
out_sig(out_count,:) = std_logic_len;
op_error_out = out_count;

% spi_clk_out
out_count = out_count + 1;
out_sig(out_count,:) = std_logic_len;
spi_clk_out = out_count;

% miso_out
out_count = out_count + 1;
out_sig(out_count,:) = std_logic_len;
miso_out = out_count;

% cs_n_out
out_count = out_count + 1;
out_sig(out_count,:) = std_logic_len;
cs_n_out = out_count;

% rx_time_out
out_count = out_count + 1;
out_sig(out_count,:) = time_len;
rx_time_out = out_count;

%% Run the simulations

% Define the cases to run
tx_case = 0;
rx_case = 1;

% Set the number of iterations
trials = 1;

for t = 1:trials
    
    % Create a cell array of the input signals to account for different
    % variable widths
    in_vect       = cell (1, in_count) ;
    out_vect      = cell (1, out_count) ;
    
    % Set the initial values of the in_vect array
    for i = 1 : in_count
        in_vect {i} = fi (in_sig (i, 4), in_sig (i, 3), in_sig (i, 1),  ...
                    in_sig (i, 2)) ;
    end
    
    % Define the spi clock
    spi_clk = fi(0, 0, 1, 0);
    
    % Define the number of iterations to simulate
    iterations = 5e4;
    
    for i = 1:iterations
        [out_vect{:}] = step (sim_hdl, in_vect {:}) ;

%% Startup
        % Choose an arbitrary startup time after the simulation begins
        if i == 11 
            in_vect{startup_in} = fi (                     1, ...
                                        in_sig(startup_in,3), ...
                                        in_sig(startup_in,1), ...
                                        in_sig(startup_in,2)        );
        elseif (mod(i,4.85e4)  == 0 || ... 
                 mod(i,4.85e4)  == 1 || ... 
                 mod(i,4.85e4)  == 2 || ...
                 mod(i,4.85e4)  == 3 ) && out_vect{startup_complete_out} 
             
             in_vect{startup_in} = fi (                     1, ...
                                        in_sig(startup_in,3), ...
                                        in_sig(startup_in,1), ...
                                        in_sig(startup_in,2)        );
        else
            in_vect{startup_in} = fi (                     0, ...
                                        in_sig(startup_in,3), ...
                                        in_sig(startup_in,1), ...
                                        in_sig(startup_in,2)        );
        end
        
% Transmit Test
        if (mod(i,floor(iterations/6.0)) == 0 || ...
            mod(i,floor(iterations/6.0)) == 1 || ...
            mod(i,floor(iterations/6.0)) == 2 || ...
            mod(i,floor(iterations/6.0)) == 3 ) && out_vect{startup_complete_out}
            disp('Sending TX request...')
            in_vect{tx_req_in}   =    fi (                        1, ...
                                                in_sig(tx_req_in,3), ...
                                                in_sig(tx_req_in,1), ...
                                                in_sig(tx_req_in,2)      );

            in_vect{data_addr_in} =  fi (       uint8(0), ...
                                                in_sig(data_addr_in,3), ...
                                                in_sig(data_addr_in,1), ...
                                                in_sig(data_addr_in,2)    );
        else
            
               in_vect{tx_req_in} =    fi (                   0, ...
                                            in_sig(tx_req_in,3), ...
                                            in_sig(tx_req_in,1), ...
                                            in_sig(tx_req_in,2)        );
        end

%% Recieve Test
        if (mod(i,4.5e4) == 0  || ...
            mod(i,4.5e4) == 1  || ...
            mod(i,4.5e4) == 2  || ...
            mod(i,4.5e4) == 3 )&& out_vect{startup_complete_out}
           
            disp('Sending RX request...')
            in_vect{rx_req_in} =    fi (                   1, ...
                                        in_sig(rx_req_in,3), ...
                                        in_sig(rx_req_in,1), ...
                                        in_sig(rx_req_in,2)        );
        elseif ( mod(i,4.6e4)  == 0 || ... 
                 mod(i,4.6e4)  == 1 || ... 
                 mod(i,4.6e4)  == 2 || ...
                 mod(i,4.6e4)  == 3 ) && out_vect{startup_complete_out}
           disp('Sending RX ready...')
           in_vect{rx_rdy_in} =    fi (                   1, ...
                                        in_sig(rx_rdy_in,3), ...
                                        in_sig(rx_rdy_in,1), ...
                                        in_sig(rx_rdy_in,2)        );                          
        else
            
           in_vect{rx_req_in} =    fi (                   0, ...
                                        in_sig(rx_req_in,3), ...
                                        in_sig(rx_req_in,1), ...
                                        in_sig(rx_req_in,2)        );
            in_vect{rx_rdy_in} =    fi (                   1, ...
                                        in_sig(rx_rdy_in,3), ...
                                        in_sig(rx_rdy_in,1), ...
                                        in_sig(rx_rdy_in,2)        );         
        
        end
    
        if (mod(i,4.8e4)  == 0 || ... 
                 mod(i,4.8e4)  == 1 || ... 
                 mod(i,4.8e4)  == 2 || ...
                 mod(i,4.8e4)  == 3 ) && out_vect{startup_complete_out}
             
            in_vect{sleep_req_in} = fi (                     1, ...
                                        in_sig(sleep_req_in,3), ...
                                        in_sig(sleep_req_in,1), ...
                                        in_sig(sleep_req_in,2)        ); 
        else
            in_vect{sleep_req_in} =    fi (                   0, ...
                                        in_sig(sleep_req_in,3), ...
                                        in_sig(sleep_req_in,1), ...
                                        in_sig(sleep_req_in,2)        );
        end

    
end

























end