%Test used to compare results from blocked parse_sd_mex versus non-blocked.


%parse_sd_card_mex_p is the latest working version of the c_pp code.
%Use that one. 


%clear all;

file = 'monkey_collar'
file_mat = [file '.mat']
filename = ['E:\User\Globus\monkey_master\monkey_2_trial_2\dump\' file '.bin']
if exist(filename, 'file')
length_mB = 300;
length_blocks = (length_mB*1024*1024)/ ( 512);

csv = 0;

% [audio_l,audio_r,segments,gyro,xl,mag,status_p,tm_p,nav_p,tp_p,gyro_i,xl_i,mag_i,gyro_timemarks,status_p_timemarks,aud_i] ... 
%     = parse_sdcard_mex_p_mem(filename,length_blocks);

parse_sdcard_mex_p(filename,length_blocks,csv);
% 
% [audio_l,audio_r,segments,gyro,xl,mag,status_p,tm_p,nav_p,tp_p,gyro_i,xl_i,mag_i,gyro_timemarks,status_p_timemarks,aud_i,gyro_i_test] ... 
%     = parse_sdcard_mex_p(filename,length_blocks);


end

% 
% mean_audio = double(audio_r) / abs(max(double(audio_r)));
% mean_audio = mean_audio-mean(mean_audio);
% audiowrite(['Right_Channel.wav'],mean_audio,56250);
% clear mean_audio;
% plot(mean_audio)




%[audio_l,audio_r,segments,gyro,xl,mag,status,tm,nav] = parse_sdcard_mex(filename,length_blocks);
%[audio_l,audio_r,segments,gyro,xl,mag,status_i,tm_i,nav_i] = parse_sdcard_mex_p(filename,length_blocks);
%[audio_l,audio_r,segments,gyro,xl,mag,status,tm,nav,gyro_t,accel_t,mag_t,audio_t] = parse_sdcard_mex(filename,length_blocks);

% [audio_l_n,audio_r_n,segments_n,gyro_n,xl_n,mag_n,status_n,tm_n,nav_n] = parse_sdcard_mex_nonblock(filename,length_blocks);

% isequal(audio_l,audio_l_n)
% isequal(audio_r,audio_r_n)
% isequal(segments,segments_n)
% isequal(gyro,gyro_n)
% isequal(xl,xl_n)
% isequal(mag,mag_n)
% isequal(status,status_n)
% isequal(tm,tm_n)
% isequal(nav,nav_n)

