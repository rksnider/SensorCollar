function TXreceiver_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation
sim_hdl = hdlcosim_txreceiver;


%---------------------------------------------------------------------------
%   Simulation Definitions.
%---------------------------------------------------------------------------

sysclk_freq_g           = 3.7e6 ;

StepsPerClock           = 8 ;

sim_steprate            = sysclk_freq_g * StepsPerClock ;

%---------------------------------------------------------------------------
%   Package and Generic definitions.
%---------------------------------------------------------------------------

gps_time_nanobits_c     = 20 ;
gps_time_millibits_c    = 30 ;
gps_time_weekbits_c     = 16 ;

gps_time_bits_c         = gps_time_weekbits_c + gps_time_millibits_c +  ...
                          gps_time_nanobits_c ;

gps_time_nanomult_c     = 2 ^ 0 ;
gps_time_millimult_c    = 2 ^ gps_time_nanobits_c ;
gps_time_weekmult_c     = 2 ^ (gps_time_nanobits_c + gps_time_millibits_c) ;

gps_time_nanolimit_c    = 1000000 ;
gps_time_millilimit_c   = 1000 * 60 * 60 * 24 * 7 ;
gps_time_weeklimit_c    = 10000 ;

sys_addr_bits_g         = 32 ;
addr_bits_g             = 10 ;
data_bits_g             =  8 ;
auth_bits_g             = 32 ;

%-----------------------------------------------------------------
%   Messages to process.
%-----------------------------------------------------------------

system_id         = 18 ;
auth_code         = 123456789 ;

gpstm_start       = datenum ('05-jan-1980 17:00:00') ;
gpstm_now         = now - gpstm_start ;
gpstm_day         = floor (gpstm_now) ;
gpstm_subday      = gpstm_now - gpstm_day ;

gpstm_week        = fi (floor (gpstm_day / 7), 0, 72, 0) ;
gpstm_milli       = fi ((gpstm_day - gpstm_week * 7) * 86400 * 1000 +   ...
                        floor (gpstm_subday * 86400 * 1000), 0, 72, 0) ;
gpstm_nano        = fi (rem (gpstm_subday * 86400 * 1.0e9, 1.0e6),      ...
                        0, 72, 0) ;

gpstm             = bitshift (gpstm_week, 50)  +                        ...
                    bitshift (gpstm_milli, 20) +                        ...
                    gpstm_nano ;

%   Valid listen messages.

listen_0          = [23 byte_store(system_id, 4) byte_store(10, 4)      ...
                     byte_store(gpstm+1, 9) byte_store(auth_code, 4)    ...
                     1 0] ;

listen_1          = [23 byte_store(system_id, 4) byte_store(10, 4)      ...
                     byte_store(gpstm+2, 9) byte_store(auth_code, 4)    ...
                     1 1] ;

%   Valid release messages.

release_0         = [23 byte_store(system_id, 4) byte_store(10, 4)      ...
                     byte_store(gpstm+3, 9) byte_store(auth_code, 4)    ...
                     2 0] ;

release_1         = [23 byte_store(system_id, 4) byte_store(10, 4)      ...
                     byte_store(gpstm+4, 9) byte_store(auth_code, 4)    ...
                     2 1] ;

%   Missing listen/release value.

listen_missing    = [22 byte_store(system_id, 4) byte_store(10, 4)      ...
                     byte_store(gpstm+5, 9) byte_store(auth_code, 4)    ...
                     1 0] ;

%   Invalid length.

length_short      = [7 byte_store(system_id, 4) byte_store(10, 4)       ...
                     byte_store(gpstm+6, 9) byte_store(auth_code, 4)    ...
                     1 0] ;

%   Invalid system ID.

system_id_wrong   = [22 byte_store(22, 4) byte_store(10, 4)             ...
                     byte_store(gpstm+7, 9) byte_store(auth_code, 4)    ...
                     1 0] ;

%   Invalid times.

dup_message_1     = [22 byte_store(system_id, 4) byte_store(10, 4)      ...
                     byte_store(gpstm+5, 9) byte_store(auth_code, 4)    ...
                     1 0] ;

dup_message_2     = [22 byte_store(system_id, 4) byte_store(10, 4)      ...
                     byte_store(gpstm+4, 9) byte_store(auth_code, 4)    ...
                     1 0] ;

%   Invalid authentication code.

auth_failure      = [22 byte_store(system_id, 4) byte_store(10, 4)      ...
                     byte_store(gpstm+8, 9) byte_store(98765432, 4)     ...
                     1 0] ;

%   Invalid message type.

msgtype_bad       = [22 byte_store(system_id, 4) byte_store(10, 4)      ...
                     byte_store(gpstm+9, 9) byte_store(auth_code, 4)    ...
                     0 0] ;

message_tbl       = {listen_0 listen_1 release_0 release_1              ...
                     listen_missing length_short system_id_wrong        ...
                     dup_message_1 dup_message_2 auth_failure msgtype_bad} ;

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

%   System Address of this device.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [sys_addr_bits_g 0 0 system_id] ;
sys_address_in          = in_count ;

%   A message has been received and processed.

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
rcv_start_in            = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
rcv_done_out            = out_count ;

%   Request and receive access to the message authenticator.

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
authreq_out             = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
authrcv_in              = in_count ;

%   Authentication signals.

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
authenticate_out        = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
authdone_in             = in_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = data_bits_g ;
authbyte_out            = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
authnext_out            = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
authready_in            = in_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [auth_bits_g 0 0 auth_code] ;
authcode_in             = in_count ;

%   Request and receive access to message memory.

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
memreq_out              = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [1 0 0 0] ;
memrcv_in               = in_count ;

%   Message memory signals.

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
mem_clk                 = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
mem_read_en_out         = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = addr_bits_g ;
mem_address_out         = out_count ;

in_count                = in_count + 1 ;
in_sig (in_count, :)    = [data_bits_g 0 0 0] ;
mem_datafrom_in         = in_count ;

%   Message results.

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
listen_out              = out_count ;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
release_out             = out_count ;

%   Busy Processing

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
busy_out                = out_count ;


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

    clock_count             = uint32 (0) ;
    message_index           = uint32 (1) ;
    rcv_start               = 0 ;
    done                    = 0 ;

    while (done == 0)

      [out_vect{:}] = step (sim_hdl, in_vect {:}) ;

      %   Send a new message when the last one has been processed.

      rcv_done              = out_vect {rcv_done_out} ;

      if (rcv_done == 1 && rcv_start == 1)
        rcv_start           = 0 ;

        if (message_index > length (message_tbl))
          done              = 1 ;
        end

      elseif (rcv_done == 0 && rcv_start == 0)
        message             = message_tbl {message_index} ;
        message_index       = message_index + uint32 (1) ;
        rcv_start           = 1 ;
      end

      in_vect {rcv_start_in}  = fi (rcv_start,                          ...
                                    in_sig (rcv_start_in, 3),           ...
                                    in_sig (rcv_start_in, 1),           ...
                                    in_sig (rcv_start_in, 2)) ;

      %   The authenticator is allocated immediately after a request for it
      %   is received.  Bytes sent to the authenticator are acknowleged
      %   immediately.  Authentication finishes as soon as it is ended.

      in_vect {authrcv_in}    = out_vect {authreq_out} ;

      in_vect {authready_in}  = out_vect {authnext_out} ;

      in_vect {authdone_in}   = bitcmp (out_vect {authenticate_out}) ;

      %   Memory is allocated immediately after a request for it is
      %   received.

      in_vect {memrcv_in}     = out_vect {memreq_out} ;

      %   Messages are read only when that enable signal is high.

      if (out_vect {mem_read_en_out}.bin == '1')
        in_vect {mem_datafrom_in} =                                     ...
                          fi (message (out_vect {mem_address_out} + 1), ...
                              in_sig (mem_datafrom_in, 3),              ...
                              in_sig (mem_datafrom_in, 1),              ...
                              in_sig (mem_datafrom_in, 2)) ;
      end
    end

end
