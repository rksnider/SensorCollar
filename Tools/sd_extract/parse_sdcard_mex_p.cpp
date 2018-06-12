// ----------------------------------------------------------------------------
// --
// --!@file       parse_sdcard_mex.cpp
// --!@brief      Parse SD card binary image from the recording collar project
// --!@details
// --!@author     Chris Casebeer
// --!@date       7_5_2016
// --!@copyright
// --
// --This program is free software : you can redistribute it and / or modify
// --it under the terms of the GNU General Public License as published by
// --the Free Software Foundation, either version 3 of the License, or
// --(at your option) any later version.
// --
// --This program is distributed in the hope that it will be useful,
// --but WITHOUT ANY WARRANTY; without even the implied warranty of
// --MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
// --GNU General Public License for more details.
// --
// --You should have received a copy of the GNU General Public License
// --along with this program.If not, see <http://www.gnu.org/licenses/>.
// --
// --Chris Casebeer
//--Electrical and Computer Engineering
// --Montana State University
// --  610 Cobleigh Hall
// --Bozeman, MT 59717
// --christopher.casebee1@msu.montana.edu
// --
// ----------------------------------------------------------------------------


//This C++ file attempts to parse the sdcard at a faster rate. 
//C++ is used for convenience of some of its built in data handling/structures.
//Input is filename from the matlab workspace.
//MEX will pass back arrays for l/r audio and IMU streams (MAG/XL/GYRO) and GPS packets and time stamps (corrected) for all samples



//[audio_l, audio_r, segments, gyro, xl, mag, status_p, tm_p, nav_p, tp_p, gyro_i, accel_i, mag_i, gyro_timemarks, status_p_timemarks, aud_i] ...
//= parse_sdcard_mex_p(filename, length_blocks);
//A filename must be supplied. 
//_i variables are the times associated with the respective samples.Reset time and UTC time.
//Blocks to process is optional. If not supplied the entire file is processed. 


//TODO:
//CHECK YOUR CALLOCS!
//Add saving to mat file. 
//Add checking for the mat file (exist) and stopping processing. 
//Change from import to workspace to possibly import from mat file
//after processing to the mat file. 
//Or I could just save the mat file now.......that I've processed into workspace. 

//I now read the binary into memory a chunk at a time. 
//However I still keep the full C working set till then end to transfer to Matlab. 
//This is still too large. 

//Which stuff in the C space is destroyed after ending? Does Matlab keep any of this around?
//All C++ vector types used should go be destroyed upon program ending. 
//But does MATLAB end the program?


//However, 1gB now takes < 10 seconds. 
//With Debug on it takes < 60 seconds. 


//Notes on MEX
//Anything which will end of in matlab must be copied after using a mxcalloc. 
//In the end, all data is recopied to matlab aware memory from the C allocations. 


//Todo
//Add sensing shutdown events and jumps in logical block number indicating system restart
//and new data set. 
//Create template function for mex handoff of 


//Parser is hardcode (mostly) to parse two audio channels)
//This should be changed to be automatic
//Seek to status segment.....find number of mics active....seek back....parse accordingly. :|

//Fixed:
//Matlab crash related to pointer handling in the mex handoff of structures.

//6_21_2017
//Loading the entirety of 3GB of processed data into the Matlab workspace directly is error prone. 
//For now I am going to quickly! create csv files for the data.
//Users can then import what they want. 
//Still trying to figure out how to append to create MAT files using the mex api. 
//CSV didn't work. Too slow and big. 
//Changed to binary files now. 



#include <cstdlib>
#include <fstream>
#include <string>
#include <cerrno>
#include <vector>
#include <iostream>
#include <algorithm>
#include <iomanip>
#include <chrono>
#include <iterator>
#include <intrin.h>

#include "matrix.h"
#include "mex.h"
#include "mat.h"

#include <iostream>
#include <fstream>

using std::vector;
using std::cout;

 //Bitwise into this structure to keep track of time. 
  struct gps_time
  {
  uint32_t    week_num;
  uint32_t    milli_num;
  uint32_t    nano_num;
  uint32_t    gps_week_num;
  uint32_t    gps_milli_num;
  uint32_t    gps_nano_num;
  };


  struct tim_tp_packet {
    uint32_t reset_time_week;
    uint32_t reset_time_ms;
    uint32_t reset_time_ns;
    uint32_t gps_time_week;
    uint32_t gps_time_ms;
    uint32_t gps_time_ns;
  };



//Masks as defined in the vhdl code. 
  uint64_t week_mask = 0xfffc000000000000;
  uint64_t milli_mask = 0x0003fffffff00000;
  uint64_t nano_mask = 0x00000000000fffff;

//Take uint64 and process to week/ms/ns.
gps_time populate_gps_time(uint64_t);
//Back annotate every sample in stream to ms/ns.
//Fill in adjusted absolute gps times. 
int back_annotate(vector<gps_time>&, vector<tim_tp_packet>&, vector<int>&, int, int);
int copy_out_uint32(int, int, int, gps_time*, mxArray**);
int write_int_vector_csv(const std::string&, vector<int>&,int);
int write_uint32_vector_csv(const std::string&, gps_time*);
int write_out_struct_csv(const std::string&, int32_t*, std::vector<const std::string>&, int, int,int);
int write_out_struct_csv(const std::string&, uint64_t*, std::vector<const std::string>&, int, int, int);
int write_out_struct_csv(const std::string&, uint32_t*, std::vector<const std::string>&, int, int, int);
int write_int_vector_binary(const std::string&, vector<int>&);
int write_out_struct_binary(const std::string&, uint64_t*, std::vector<const std::string>&, int, int, int);
int write_out_struct_binary(const std::string&, uint32_t*, std::vector<const std::string>&, int, int, int);
int write_out_struct_binary(const std::string&, int32_t*, std::vector<const std::string>&, int, int, int);

// *  the gateway routine.  */
 void mexFunction( int nlhs, mxArray *plhs[],
                   int nrhs, const mxArray *prhs[] )
                  

//int main()
{
  
  int read_full_file = 0;
  int csv = 0;
  uint64_t num_blocks_to_read;
  uint64_t num_bytes_to_read;
  const uint64_t max_read_size = 128 * 1024 * 1024;
  uint64_t read_size = max_read_size;


  switch (nrhs){

    case 0:
    {
      mexPrintf("Please Supply Filename and Rerun\n");
      return;
    }
    case 1:
    {
      read_full_file = 1;
      break;
    }
    case 3:
    {
      num_blocks_to_read = mxGetScalar(prhs[1]);
      csv = mxGetScalar(prhs[2]);
      num_bytes_to_read = num_blocks_to_read * 512;
      mexPrintf("Reading %d blocks\n",num_blocks_to_read);
      break;
    }
    default:{
    mexPrintf("Please Supply Filename and/or Num Blocks\n");
    return;
    }
    }


  //Names to store variables in mat
  const std::string seq_matvar_name = "sequence_number";
  const std::string audiol_matvar_name = "audio_segment_stream_l";
  const std::string audior_matvar_name = "audio_segment_stream_r";
  const std::string gyro_matvar_name = "gyro_segment_stream";
  const std::string accel_matvar_name = "accel_segment_stream";
  const std::string mag_matvar_name = "mag_segment_stream";
  const std::string status_segment_matvar_name = "status_segments";
  const std::string tm_matvar_name = "tm_packets";
  const std::string navsol_matvar_name = "nav_sol_packets";
  const std::string tp_matvar_name = "tp_packets";
  
  //Time the operation using a newer C++ library.
  std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();
  //Get the filename from the matlab call.
  std::string filename (mxArrayToString(prhs[0])); 

  //Change these based on how IMU and audio filters are set up.
  //These are the collar defaults. 
  const int accel_sample_rate = 952;
	const int mag_sample_rate = 80;
	const int gyro_sample_rate = 952;
	const int audio_sample_rate = 56250;

  //Count in ms/ns
  int accel_ms = int((1.0 / double(accel_sample_rate)) * 1E9) / int(1E6);
  int accel_ns = int((1.0 / double(accel_sample_rate)) * 1E9) % int(1E6);
  int mag_ms = int((1.0 / double(mag_sample_rate))* 1E9) / int(1E6);
  int mag_ns = int((1.0 / double(mag_sample_rate)) * 1E9) % int(1E6);
  int gyro_ms = int((1.0 / double(gyro_sample_rate)) * 1E9) / int(1E6);
  int gyro_ns = int((1.0 / double(gyro_sample_rate)) * 1E9) % int(1E6);
  int audio_ms = int((1.0 / double(audio_sample_rate)) * 1E9) / int(1E6);
  int audio_ns = int((1.0 / double(audio_sample_rate)) * 1E9) % int(1E6);
  
  //  --  GPS Clock Format. This is how the GPS Time is defined in 
  // the FPGA. 
  // constant gps_time_weekbits_c  : natural := 16 ;
  // constant gps_time_millibits_c : natural := 30 ;
  // constant gps_time_nanobits_c  : natural := 20 ;

  // constant gps_time_bits_c      : natural := gps_time_weekbits_c +
                                             // gps_time_millibits_c +
                                             // gps_time_nanobits_c ;
                                             

  
  int gps_time_field_count = 6;
  std::vector<const std::string> gps_time_field_names{ "week_num",
    "milli_num",
    "nano_num" ,
    "gps_week_num" ,
    "gps_milli_num",
    "gps_nano_num"
  };

  //mxCreateStructMatrix needs a **char. This is how I make that. 
  //StackExchange help here. 
  std::vector<const char*> gps_time_names_pointers;
  for (size_t i = 0; i < gps_time_field_names.size(); ++i){
    gps_time_names_pointers.push_back(const_cast<char*>(gps_time_field_names[i].c_str()));
  }
  

  
  

  // constant gps_time_bytes_c     : natural :=
                // natural ((gps_time_bits_c - 1) / 8) + 1 ;

  int BLOCK_SEQNO_BYTES = 4;
  int BLOCK_SIZE = 512;
  int SEG_TRAILER_SIZE = 2;
  int AUDIO_WORD_BYTES = 2;


  int IMU_AXIS_WORD_LENGTH_BYTES = 2;
  int IMU_GYRO_SEG_BYTES = 3 * IMU_AXIS_WORD_LENGTH_BYTES;
  int IMU_ACCEL_SEG_BYTES = 3 * IMU_AXIS_WORD_LENGTH_BYTES;
  int IMU_MAG_SEG_BYTES = 3 * IMU_AXIS_WORD_LENGTH_BYTES;


  //Status Segment Constants Pullsed from flashblock.vhd
  int status_compile_length = 4;
  int status_commit_length = 4;
  int gps_time_length = 9;
  int rtc_time_legnth = 4;
  int num_mics_length = 1;
  int status_type_length = 1;

  int status_compile_offset = 0;
  int status_commit_offset = status_compile_offset + status_compile_length;
  int status_packet_time_offset = status_commit_offset + status_commit_length;
  int status_accel_time_offset = status_packet_time_offset + gps_time_length;
  int status_mag_time_offset = status_accel_time_offset + gps_time_length;
  int status_gyro_time_offset = status_mag_time_offset + gps_time_length;
  int status_temp_time_offset = status_gyro_time_offset + gps_time_length;
  int status_audio_time_offset = status_temp_time_offset + gps_time_length;
  int status_rtc_time_offset = status_audio_time_offset + gps_time_length;
  int status_num_mics_offset = status_rtc_time_offset + rtc_time_legnth;
  int status_type_offset = status_num_mics_offset + status_type_length;

  int num_mics_active = 2;

  //All the defined segment identifiers. 
  //Taken from flashblock.vhd.

  char PADDING_BYTE = 0x00;


  char BLOCK_SEG_UNUSED = 0x01;
  char BLOCK_SEG_STATUS = 0x02;
  char BLOCK_SEG_GPS_TIME_MARK = 0x03;
  char BLOCK_SEG_GPS_POSITION = 0x04;
  char BLOCK_SEG_IMU_GYRO = 0x05;
  char BLOCK_SEG_IMU_ACCEL = 0x06;
  char BLOCK_SEG_IMU_MAG = 0x07;
  char BLOCK_SEG_IMU_TEMP = 0x0A;
  char BLOCK_SEG_EVENT = 0x0B;
  char BLOCK_SEG_AUDIO = 0x08;
  char BLOCK_SEG_GPS_TIME_PULSE = 0x0D;

  //Refer to msg_ubx_nav_sol_pkg.vhd
  //and u-blox 7
  //Receiver Description
  //Including Protocol Specification V14
  int itow_length = 4;  //U4
  int ftow_length = 4;  //I4
  int munsol_week_length = 2; //I2
  int gps_fix_type_length = 1;  //U1
  int ecefx_length = 4;  //I4
  int ecefy_length = 4;  //I4
  int ecefz_length = 4;  //I4
  int pAcc_length = 4;  //U4
  int positiondop_length = 2;  //U2
  int numsv_length = 1;  //U1
  int posttime_length = gps_time_length;  //9 Bytes GPS -- Still working on this. 

  int itow_offset = 0;
  int ftow_offset = itow_offset + itow_length;
  int munsol_week_offset = ftow_offset + ftow_length;
  int gps_fix_type_offset = munsol_week_offset + munsol_week_length;
  int ecefx_offset = gps_fix_type_offset + gps_fix_type_length;
  int ecefy_offset = ecefx_offset + ecefx_length;
  int ecefz_offset = ecefy_offset + ecefy_length;
  int pAcc_offset = ecefz_offset + ecefz_length;
  int positiondop_offset = pAcc_offset + pAcc_length;
  int numsv_offset = positiondop_offset + positiondop_length;
  int posttime_offset = numsv_offset + numsv_length;

  int nav_sol_total_length = 39;


  //Refer to msg_ubx_tim_tm2_pkg.vhd
  // and u-blox 7
  // Receiver Description
  //Including Protocol Specification V14
  int tm2_flags_length = 1;      //X1 -- Interpreted as U1
  int tm2_wnF_length = 2;        //U2
  int tm2_towmsF_length = 4;      //U4
  int tm2_towsubmsF_length = 4;      //U4
  int tm2_accest_length = 4;        //U4
  int tm2_marktime_length = gps_time_length;      //GPS 9 Bytes.

  int tm2_flags_offset = 0;
  int tm2_wnF_offset = tm2_flags_offset + tm2_flags_length;
  int tm2_towmsF_offset = tm2_wnF_offset + tm2_wnF_length;
  int tm2_towsubmsF_offset = tm2_towmsF_offset + tm2_towmsF_length;
  int tm2_accest_offset = tm2_towsubmsF_offset + tm2_towsubmsF_length;
  int tm2_marktime_offset = tm2_accest_offset + tm2_accest_length;


  int tim_tm2_total_length = 24;
  
  //The timepulse packet defined by GPS developer is two GPS times back to 
  //back. The tim_tp packet is not retained. 
  //See gps_message_ctl_pkg.vhd for the location of the two GPS times in 
  //GPS memory. 

  //I only process bottom 8 bytes. Since the time is stored little endian
  //I can index 0-8 and leave off the top bytes. 
  int tp_fpga_time_length = gps_time_length;    //GPS 9 Bytes.
  int tp_timepulse_length = gps_time_length;  //GPS 9 Bytes.

  

  int tp_fpga_offset = 0;
  int tp_timepulse_offset = tp_fpga_offset + tp_timepulse_length;

  int tim_tp_total_length = 18;
  
  
  


  int nav_sol_packet_cnt = 1;
  int tm_tm2_packet_cnt = 1;
  int status_packet_cnt = 1;



  //Structs are defined all one data size.
  //I can iterate over members easily with a pointer.
  struct status_packet {
    uint64_t commit;
    uint64_t compile;
    uint64_t status_t;
    uint64_t accel_t;
    uint64_t gyro_t;
    uint64_t mag_t;
    uint64_t temp_t;
    uint64_t audio_t;
    uint64_t rtc_t;
    uint64_t mics_active;
    uint64_t status_type;
  };

  vector<status_packet> status_packets;
  status_packet cur_status_packet;
  int status_packet_field_count = 11;
  std::vector<const std::string> status_field_names{ "commit",
    "compile",
    "status_t",
    "accel_t",
    "gyro_t",
    "mag_t",
    "temp_t",
    "audio_t",
    "rtc_t",
    "mics_active",
    "status_type"
  };

  //mxCreateStructMatrix needs a **char. This is how I make that. 
  //StackExchange help here. 
  std::vector<const char*> status_names_pointers;
  for (size_t i = 0; i < status_field_names.size(); ++i){
    status_names_pointers.push_back(const_cast<char*>(status_field_names[i].c_str()));
  }



  struct tm_packet {
    int flags;
    int wnF;
    int towmsF;
    int towsubmsF;
    int accestns;
    int reset_time_week;
    int reset_time_ms;
    int reset_time_ns;
  };

  vector<tm_packet> tm_packets;
  tm_packet cur_tm_packet;
  int tm_packet_field_count = 8;
  std::vector<const std::string> tm_field_names{ "flags",
    "wnF",
    "towmsF",
    "towsubmsF",
    "accestns",
    "reset_time_week",
    "reset_time_ms",
    "reset_time_ns"
  };

  //mxCreateStructMatrix needs a **char. This is how I make that. 
  //StackExchange help here. 
  std::vector<const char*> tm_names_pointers;
  for (size_t i = 0; i < tm_field_names.size(); ++i){
    tm_names_pointers.push_back(const_cast<char*>(tm_field_names[i].c_str()));
  }


  struct nav_sol_packet {

    int itow;
    int ftow;
    int weekepoch;
    int fixtype;
    int ecefx;
    int ecefy;
    int ecefz;
    int pacc;
    int posdop;
    int numsv;
    int reset_time_week;
    int reset_time_ms;
    int reset_time_ns;
  };

  vector<nav_sol_packet> navsol_packets;
  nav_sol_packet cur_navsol_packet;
  int navsol_packet_field_count = 13;

  std::vector<const std::string> navsol_field_names{ "itow",
    "ftow",
    "weekepoch",
    "fixtype",
    "ecefx",
    "ecefy",
    "ecefz",
    "pacc",
    "posdop",
    "numsv",
    "reset_time_week",
    "reset_time_ms",
    "reset_time_ns"
  };

  std::vector<const char*> navsol_names_pointers;
  for (size_t i = 0; i < navsol_field_names.size(); ++i){
    navsol_names_pointers.push_back(const_cast<char*>(navsol_field_names[i].c_str()));
  }
  
  
  vector<tim_tp_packet> tim_tp_packets;
  tim_tp_packet cur_tim_tp_packet;
  int tim_tp_field_count = 6;

  std::vector<const std::string> tim_tp_field_names{  "reset_time_week",
    "reset_time_ms",
    "reset_time_ns",
    "gps_week",
    "gps_ms",
    "gps_submsns",
  };

  std::vector<const char*> tim_tp_names_pointers;
  for (size_t i = 0; i < tim_tp_field_names.size(); ++i){
    tim_tp_names_pointers.push_back(const_cast<char*>(tim_tp_field_names[i].c_str()));
  }
  
  
  

  vector<int> audio_l;
  vector<int> audio_r;
  vector<int> sequence_number;

  vector<int> current_block_l;
  vector<int> current_blcok_r;


  vector<int> gyro_segment_stream;
  vector<int> accel_segment_stream;
  vector<int> mag_segment_stream;


  vector<gps_time> gyro_time;
	vector<gps_time> accel_time;
	vector<gps_time> mag_time;
	vector<gps_time> audio_time;
  vector<gps_time> audio_cell_time;
  vector<gps_time> audio_segment_time;
  

  vector<gps_time> status_p_time_mark;
  vector<gps_time> gyro_time_mark;
  vector<gps_time> accel_time_mark;
  vector<gps_time> mag_time_mark;
  vector<gps_time> audio_time_mark;

  gps_time tm2_gps_time;
  gps_time nav_gps_time;
  gps_time tp_fpga_time;
  gps_time tp_timepulse_time;
  
	uint64_t recent_gyro_time = 0;
	uint64_t recent_accel_time = 0;
	uint64_t recent_mag_time = 0;
	uint64_t recent_audio_time = 0;

  uint64_t tm2_time = 0;
  uint64_t nav_time = 0;
  uint64_t tp_time = 0;
  uint64_t fpga_time = 0;
 

  //Debug Stuff
  //Count the number of imu segments between status packets
  //Trying to 
  int xl_packets = -1;
  vector<int> xl_packets_num {  };
  int mag_packets = -1;
  vector<int> mag_packets_num {  };
  int g_packets = -1;
  vector<int> g_packets_num {  };
  int aud_packets = -1;
  int aud_packets_loc;
  int new_status_segment;
  vector<int> aud_packets_num {  };


  //Track the dicontinuity versus samples between status segments
  int packet_number;
  vector<int> packet_debug;


  int block_start;
  int block_success;
  int segment_length;

  int k = 0;

  int end_sample;
  int begin_sample;

  uint64_t file_length = 0;

  vector<int> packet_start_locations;
  vector<int> packet_end_locations;
  vector<int> packet_lengths;
  vector<int> packet_types;


  std::ifstream in(filename.c_str(), std::ios::in | std::ios::binary);
  std::vector<unsigned char> contents;



  
  //Read. Process. Clear from Memory. Repeat.

  in.seekg(0, std::ios::end);
 
  mexPrintf("The file is %d blocks long\n", in.tellg() / 512);


  if (read_full_file){
   file_length = in.tellg();
  }
  else
  {

    if (num_bytes_to_read > in.tellg()){
      mexPrintf("User attempting to read past EOF\n");
      file_length = in.tellg();
    }
    else

    {
      file_length = num_bytes_to_read;
    }
  }


  int start_of_parse = 1;

  for (uint64_t file_loc = 0; file_loc < file_length; file_loc = file_loc + max_read_size){
  
  
    if (file_loc + max_read_size > file_length){
      //read_size = file_length - file_loc;
      read_size = file_length - file_loc;
    }
    else
    {
      read_size = max_read_size;
    }

  mexPrintf("Seek Location is : %d\n", file_loc);
  cout << "%%%%%%%%%%%%\n" << std::endl;
  cout << "    " << (file_loc / float(num_bytes_to_read) * 100) << " % Complete\n" << std::setprecision(3) << std::endl;
  cout << "%%%%%%%%%%%%\n"  << std::endl;
    
  in.seekg(file_loc);
  contents.resize(read_size);
  in.read(reinterpret_cast<char*>(&contents[0]), read_size);

  //Reset File Byte Pointer.
  k = 0;
    

  cout << "Block Length is " << contents.size()/512 << std::endl;
  mexPrintf("Block Length to read is : %d\n",contents.size()/512);

  

  mexPrintf("Contents Size is : %d\n", contents.size());

  //Push data out of memory onto disk. 






  while (k < contents.size()) {

    

    if ((k % BLOCK_SIZE) == 0) {
      block_success = 1;

      uint32_t segment = *reinterpret_cast<const uint32_t*>(&contents[k]);

      sequence_number.push_back(int(segment));

      if ((segment % 500) == 0) {

        // //cout <<  k   << "    "  << contents.size() <<  std::endl;
        // cout << segment << "    " << (k / float(contents.size()) * 100) << " % Complete" << std::setprecision(3) << std::endl;
        // //mexPrintf("%d/t%f/t%Complete/n",segment,(k / float(contents.size()) * 100 ));
        // mexPrintf("%d\n", segment);
        // //mexCallMATLAB(drawnow);
        // //mexEvalString("drawnow");
      }
      if (segment == 0)
      {
        //Bad sequence number. Skip empty block.
        k = k + 512;
        continue;
      }

      else
      {
        //Jump to end of block. Process in reverse.
        block_start = k;
        k = k + 511;
      }
    }



      //Process all the nonpadding packet_start locations and lengths. 

    while (k != block_start + BLOCK_SEQNO_BYTES - 1) {

      segment_length = contents[k];

      if (contents[k - 1] == BLOCK_SEG_UNUSED) {
        //Jump padding
        k = k - segment_length - SEG_TRAILER_SIZE;
      }

      else
      {
        if (contents[k - 1] == BLOCK_SEG_IMU_GYRO) {
          packet_lengths.push_back(segment_length);
          begin_sample = k - SEG_TRAILER_SIZE - segment_length + 1;
          packet_end_locations.push_back(k - SEG_TRAILER_SIZE);
          packet_start_locations.push_back(k - SEG_TRAILER_SIZE - segment_length + 1);
          packet_types.push_back(BLOCK_SEG_IMU_GYRO);
          k = begin_sample - 1;
        }

        else if (contents[k - 1] == BLOCK_SEG_STATUS) {
          packet_lengths.push_back(segment_length);
          begin_sample = k - SEG_TRAILER_SIZE - segment_length + 1;
          packet_end_locations.push_back(k - SEG_TRAILER_SIZE);
          packet_start_locations.push_back(k - SEG_TRAILER_SIZE - segment_length + 1);
          packet_types.push_back(BLOCK_SEG_STATUS);

          k = begin_sample - 1;


        }
        else if (contents[k - 1] == BLOCK_SEG_GPS_POSITION)
        {
          packet_lengths.push_back(segment_length);
          begin_sample = k - SEG_TRAILER_SIZE - segment_length + 1;
          packet_end_locations.push_back(k - SEG_TRAILER_SIZE);
          packet_start_locations.push_back(k - SEG_TRAILER_SIZE - segment_length + 1);
          packet_types.push_back(BLOCK_SEG_GPS_POSITION);

          k = begin_sample - 1;

        }

        else if (contents[k - 1] == BLOCK_SEG_GPS_TIME_MARK) {
          packet_lengths.push_back(segment_length);
          begin_sample = k - SEG_TRAILER_SIZE - segment_length + 1;
          packet_end_locations.push_back(k - SEG_TRAILER_SIZE);
          packet_start_locations.push_back(k - SEG_TRAILER_SIZE - segment_length + 1);
          packet_types.push_back(BLOCK_SEG_GPS_TIME_MARK);
          k = begin_sample - 1;
        }
        else if (contents[k - 1] == BLOCK_SEG_GPS_TIME_PULSE) {
          packet_lengths.push_back(segment_length);
          begin_sample = k - SEG_TRAILER_SIZE - segment_length + 1;
          packet_end_locations.push_back(k - SEG_TRAILER_SIZE);
          packet_start_locations.push_back(k - SEG_TRAILER_SIZE - segment_length + 1);
          packet_types.push_back(BLOCK_SEG_GPS_TIME_PULSE);
          k = begin_sample - 1;
        }

        else if (contents[k - 1] == BLOCK_SEG_IMU_ACCEL) {
          packet_lengths.push_back(segment_length);
          begin_sample = k - SEG_TRAILER_SIZE - segment_length + 1;
          packet_end_locations.push_back(k - SEG_TRAILER_SIZE);
          packet_start_locations.push_back(k - SEG_TRAILER_SIZE - segment_length + 1);
          packet_types.push_back(BLOCK_SEG_IMU_ACCEL);

          k = begin_sample - 1;

        }
        else if (contents[k - 1] == BLOCK_SEG_IMU_MAG)
        {
          packet_lengths.push_back(segment_length);
          begin_sample = k - SEG_TRAILER_SIZE - segment_length + 1;
          packet_end_locations.push_back(k - SEG_TRAILER_SIZE);
          packet_start_locations.push_back(k - SEG_TRAILER_SIZE - segment_length + 1);
          packet_types.push_back(BLOCK_SEG_IMU_MAG);

          k = begin_sample - 1;

        }
        else if (contents[k - 1] == BLOCK_SEG_AUDIO) {
          packet_lengths.push_back(segment_length);
          begin_sample = k - SEG_TRAILER_SIZE - segment_length + 1;

          packet_end_locations.push_back(k - SEG_TRAILER_SIZE);
          packet_start_locations.push_back(k - SEG_TRAILER_SIZE - segment_length + 1);
          packet_types.push_back(BLOCK_SEG_AUDIO);

          k = begin_sample - 1;

        }

      }

    }

    //Process the block in the foward direction. 
    for (int i = packet_types.size()-1; i >= 0; i--) {

          //Reminder that IMU is stored ZYX on the SD Card. 
          //Two bytes (I2) little endian for each axis.
        if (packet_types[i] == BLOCK_SEG_IMU_GYRO) {


           end_sample = packet_end_locations[i];
            begin_sample = packet_start_locations[i];
            segment_length = packet_lengths[i];

            for (int i_imu = 0; i_imu < segment_length; i_imu = i_imu + IMU_AXIS_WORD_LENGTH_BYTES)
            {
              int16_t gyro = *reinterpret_cast<const int16_t*>(&contents[begin_sample + i_imu]);

              gyro_segment_stream.push_back(gyro);
            }

            gyro_time.push_back(populate_gps_time(recent_gyro_time));
            g_packets = g_packets + 1;

          }



        else if (packet_types[i] == BLOCK_SEG_STATUS) {

          end_sample = packet_end_locations[i];
            begin_sample = packet_start_locations[i];
            segment_length = packet_lengths[i];

            //Okay to cast the 9 byte length to 64 bits, top bits are not used. 

            cur_status_packet.compile = *reinterpret_cast<const uint32_t*>(&contents[begin_sample + status_compile_offset]);
            cur_status_packet.commit = *reinterpret_cast<const uint32_t*>(&contents[begin_sample + status_commit_offset]);

            cur_status_packet.status_t = *reinterpret_cast<const uint64_t*>(&contents[begin_sample + status_packet_time_offset]);

            cur_status_packet.accel_t = *reinterpret_cast<const uint64_t*>(&contents[begin_sample + status_accel_time_offset]);

            cur_status_packet.gyro_t = *reinterpret_cast<const uint64_t*>(&contents[begin_sample + status_gyro_time_offset]);

            cur_status_packet.mag_t = *reinterpret_cast<const uint64_t*>(&contents[begin_sample + status_mag_time_offset]);

            cur_status_packet.temp_t = *reinterpret_cast<const uint64_t*>(&contents[begin_sample + status_temp_time_offset]);

            cur_status_packet.audio_t = *reinterpret_cast<const uint64_t*>(&contents[begin_sample + status_audio_time_offset]);

            cur_status_packet.rtc_t = *reinterpret_cast<const uint32_t*>(&contents[begin_sample + status_rtc_time_offset]);

            cur_status_packet.mics_active = *reinterpret_cast<const uint8_t*>(&contents[begin_sample + status_num_mics_offset]);

            cur_status_packet.status_type = *reinterpret_cast<const uint8_t*>(&contents[begin_sample + status_type_offset]);


            status_packets.push_back(cur_status_packet);

            //Update the recent sample times. 
            recent_gyro_time = cur_status_packet.gyro_t;
            recent_accel_time = cur_status_packet.accel_t;
            recent_mag_time = cur_status_packet.mag_t;
            recent_audio_time = cur_status_packet.audio_t;


            status_p_time_mark.push_back(populate_gps_time(cur_status_packet.status_t));
            gyro_time_mark.push_back(populate_gps_time(cur_status_packet.gyro_t));
            accel_time_mark.push_back(populate_gps_time(cur_status_packet.accel_t));
            mag_time_mark.push_back(populate_gps_time(cur_status_packet.mag_t));
            audio_time_mark.push_back(populate_gps_time(cur_status_packet.audio_t));

            //Mark where the status packet occured.
            xl_packets_num.push_back(xl_packets);
            mag_packets_num.push_back(mag_packets);
            g_packets_num.push_back(g_packets);
            aud_packets_num.push_back(aud_packets);

            

          }
        else if (packet_types[i] == BLOCK_SEG_GPS_POSITION)
          {
            end_sample = packet_end_locations[i];
              begin_sample = packet_start_locations[i];
              segment_length = packet_lengths[i];


            cur_navsol_packet.itow = *reinterpret_cast<const uint32_t*>(&contents[begin_sample + itow_offset]);
            cur_navsol_packet.ftow = *reinterpret_cast<const int32_t*>(&contents[begin_sample + ftow_offset]);
            cur_navsol_packet.weekepoch = *reinterpret_cast<const int16_t*>(&contents[begin_sample + munsol_week_offset]);

            cur_navsol_packet.fixtype = *reinterpret_cast<const uint8_t*>(&contents[begin_sample + gps_fix_type_offset]);
            cur_navsol_packet.ecefx = *reinterpret_cast<const int32_t*>(&contents[begin_sample + ecefx_offset]);
            cur_navsol_packet.ecefy = *reinterpret_cast<const int32_t*>(&contents[begin_sample + ecefy_offset]);
            cur_navsol_packet.ecefz = *reinterpret_cast<const int32_t*>(&contents[begin_sample + ecefz_offset]);

            cur_navsol_packet.pacc = *reinterpret_cast<const uint32_t*>(&contents[begin_sample + pAcc_offset]);
            cur_navsol_packet.posdop = *reinterpret_cast<const uint16_t*>(&contents[begin_sample + positiondop_offset]);
            cur_navsol_packet.numsv = *reinterpret_cast<const uint8_t*>(&contents[begin_sample + numsv_offset]);



            nav_time = *reinterpret_cast<const uint64_t*>(&contents[begin_sample + posttime_offset]);

            //Parse the larger time into week/ms/ns.
            nav_gps_time = populate_gps_time(nav_time);
            //Insert it into the tm2 structure and add to array. 
            cur_navsol_packet.reset_time_week = nav_gps_time.week_num;
            cur_navsol_packet.reset_time_ms = nav_gps_time.milli_num;
            cur_navsol_packet.reset_time_ns = nav_gps_time.nano_num;

            navsol_packets.push_back(cur_navsol_packet);

          }

        else if (packet_types[i] == BLOCK_SEG_GPS_TIME_MARK) {


          end_sample = packet_end_locations[i];
            begin_sample = packet_start_locations[i];
            segment_length = packet_lengths[i];


            cur_tm_packet.flags = *reinterpret_cast<const uint8_t*>(&contents[begin_sample + tm2_flags_offset]);
            cur_tm_packet.wnF = *reinterpret_cast<const uint16_t*>(&contents[begin_sample + tm2_wnF_offset]);
            cur_tm_packet.towmsF = *reinterpret_cast<const uint32_t*>(&contents[begin_sample + tm2_towmsF_offset]);
            cur_tm_packet.towsubmsF = *reinterpret_cast<const uint32_t*>(&contents[begin_sample + tm2_towsubmsF_offset]);
            cur_tm_packet.accestns = *reinterpret_cast<const uint32_t*>(&contents[begin_sample + tm2_accest_offset]);

            tm2_time = *reinterpret_cast<const uint64_t*>(&contents[begin_sample + tm2_marktime_offset]);
            //Parse the larger time into week/ms/ns.
            tm2_gps_time = populate_gps_time(tm2_time);
            //Insert it into the tm2 structure and add to array. 
            cur_tm_packet.reset_time_week = tm2_gps_time.week_num;
            cur_tm_packet.reset_time_ms = tm2_gps_time.milli_num;
            cur_tm_packet.reset_time_ns= tm2_gps_time.nano_num;


            tm_packets.push_back(cur_tm_packet);
            
          }
        else if (packet_types[i] == BLOCK_SEG_GPS_TIME_PULSE) {


          end_sample = packet_end_locations[i];
            begin_sample = packet_start_locations[i];
            segment_length = packet_lengths[i];

            fpga_time = *reinterpret_cast<const uint64_t*>(&contents[begin_sample + tp_fpga_offset]);

            
            tp_fpga_time =  populate_gps_time(fpga_time);
            cur_tim_tp_packet.reset_time_week = tp_fpga_time.week_num;
            cur_tim_tp_packet.reset_time_ms = tp_fpga_time.milli_num;
            cur_tim_tp_packet.reset_time_ns= tp_fpga_time.nano_num;
            
            tp_time = *reinterpret_cast<const uint64_t*>(&contents[begin_sample + tp_timepulse_offset]);

            //Parse the larger time into week/ms/ns.
            tp_timepulse_time = populate_gps_time(tp_time);
            //Insert it into the tp2 structure and add to array. 
            cur_tim_tp_packet.gps_time_week = tp_timepulse_time.week_num;
            cur_tim_tp_packet.gps_time_ms = tp_timepulse_time.milli_num;
            cur_tim_tp_packet.gps_time_ns = tp_timepulse_time.nano_num;


            tim_tp_packets.push_back(cur_tim_tp_packet);
            

          }
          

          //Reminder that IMU is stored ZYX on the SD Card. 
          //Two bytes (I2) little endian for each axis.
        else if (packet_types[i] == BLOCK_SEG_IMU_ACCEL) {


          end_sample = packet_end_locations[i];
            begin_sample = packet_start_locations[i];
            segment_length = packet_lengths[i];

            
            for (int i_imu = 0; i_imu < segment_length; i_imu = i_imu + IMU_AXIS_WORD_LENGTH_BYTES)
            {
              int16_t accel = *reinterpret_cast<const int16_t*>(&contents[begin_sample + i_imu]);
              accel_segment_stream.push_back(accel);
            }
            accel_time.push_back(populate_gps_time(recent_accel_time));


            xl_packets = xl_packets + 1;


          }
          //Reminder that IMU is stored ZYX on the SD Card. 
          //Two bytes (I2) little endian for each axis.
        else if (packet_types[i] == BLOCK_SEG_IMU_MAG)
          {



            end_sample = packet_end_locations[i];
            begin_sample = packet_start_locations[i];
            segment_length = packet_lengths[i];


            for (int i_imu = 0; i_imu < segment_length; i_imu = i_imu + IMU_AXIS_WORD_LENGTH_BYTES)
            {
              int16_t mag = *reinterpret_cast<const int16_t*>(&contents[begin_sample + i_imu]);
              mag_segment_stream.push_back(mag);
            }
            mag_time.push_back(populate_gps_time(recent_mag_time));
            mag_packets = mag_packets + 1;





          }
        else if (packet_types[i] == BLOCK_SEG_AUDIO) {
          end_sample = packet_end_locations[i];
            begin_sample = packet_start_locations[i];
            segment_length = packet_lengths[i];


            for (int a_i = 0; a_i < segment_length; a_i = a_i + (AUDIO_WORD_BYTES*num_mics_active))
            {
              audio_r.push_back(*reinterpret_cast<const int16_t*>(&contents[begin_sample + a_i]));
              aud_packets = aud_packets + 1;
              audio_time.push_back(populate_gps_time(recent_audio_time));
            }




            for (int a_i = AUDIO_WORD_BYTES; a_i < segment_length; a_i = a_i + (AUDIO_WORD_BYTES*num_mics_active))
            {
              audio_l.push_back(*reinterpret_cast<const int16_t*>(&contents[begin_sample + a_i]));
            }



          }
          //         else
          //            //A block error has occured. 
          //            k
          //            error_loc = [error_loc k];
          //            k = block_start + 512;
          //            block_success = 0;
          //            break;
        }




      //Jump to start of next block.
      k = k + 509;


      packet_end_locations.clear();
      packet_start_locations.clear();
      packet_types.clear();
      packet_lengths.clear();


    }

    
  std::chrono::steady_clock::time_point start_matlab_copy = std::chrono::steady_clock::now();



     
     //Reading File Brace. 



       //Fill in sensor time series information.
       back_annotate(gyro_time, tim_tp_packets, g_packets_num, gyro_ms, gyro_ns);
       back_annotate(accel_time, tim_tp_packets, xl_packets_num, accel_ms, accel_ns);
       back_annotate(mag_time, tim_tp_packets, mag_packets_num, mag_ms, mag_ns);
       back_annotate(audio_time, tim_tp_packets, aud_packets_num, audio_ms, audio_ns);
         //Populate the XL/G/Mag with proper sample times. 
         //Iterate through the vectors and back annotate on time changes
         //given the sample rate.s 



       
       
      write_int_vector_binary("audio_l.bin", audio_l);
      write_int_vector_binary("audio_r.bin", audio_r);
      write_int_vector_binary("segment_number.bin", sequence_number);
      write_int_vector_binary("gyro_stream.bin", gyro_segment_stream);
      write_int_vector_binary("accel_stream.bin", accel_segment_stream);
      write_int_vector_binary("mag_stream.bin", mag_segment_stream);

	   write_out_struct_binary("status_packets.bin", (uint64_t*)&(status_packets[0]), status_field_names, (int)status_packets.size(), status_packet_field_count, start_of_parse);
	   write_out_struct_binary("navsol_packets.bin", (int32_t*)&(navsol_packets[0]), navsol_field_names, (int)navsol_packets.size(), navsol_packet_field_count, start_of_parse);
	   write_out_struct_binary("tm_packets.bin", (int32_t*)&(tm_packets[0]), tm_field_names, (int)tm_packets.size(), tm_packet_field_count, start_of_parse);
     write_out_struct_binary("tim_tp_packets.bin", (int32_t*)&(tim_tp_packets[0]), tim_tp_field_names, (int)tim_tp_packets.size(), tim_tp_field_count, start_of_parse);
     
     
     write_out_struct_binary("gyro_times.bin", (uint32_t*)&(gyro_time[0]), gps_time_field_names, gyro_time.size(), gps_time_field_count, start_of_parse);
	   write_out_struct_binary("xl_times.bin", (uint32_t*)&(accel_time[0]), gps_time_field_names, accel_time.size(), gps_time_field_count, start_of_parse);
	   write_out_struct_binary("mag_times.bin", (uint32_t*)&(mag_time[0]), gps_time_field_names, mag_time.size(), gps_time_field_count, start_of_parse);
	   write_out_struct_binary("status_p_time_mark.bin", (uint32_t*)&(status_p_time_mark[0]), gps_time_field_names, status_p_time_mark.size(), gps_time_field_count, start_of_parse);
     write_out_struct_binary("audio_times.bin", (uint32_t*)&(audio_time[0]), gps_time_field_names, audio_time.size(), gps_time_field_count, start_of_parse);
     
     if(csv)
     {
    write_int_vector_csv("audio_l.csv", audio_l,start_of_parse);
    write_int_vector_csv("audio_r.csv", audio_r,start_of_parse);
    write_int_vector_csv("segment_number.csv", sequence_number,start_of_parse);
    write_int_vector_csv("gyro_stream.csv", gyro_segment_stream,start_of_parse);
    write_int_vector_csv("accel_stream.csv", accel_segment_stream,start_of_parse);
    write_int_vector_csv("mag_stream.csv", mag_segment_stream,start_of_parse);
     
     
	   write_out_struct_csv("tim_tp_packets.csv", (int32_t*)&(tim_tp_packets[0]), tim_tp_field_names, (int)tim_tp_packets.size(), tim_tp_field_count, start_of_parse);
	   write_out_struct_csv("navsol_packets.csv", (int32_t*)&(navsol_packets[0]), navsol_field_names, (int)navsol_packets.size(), navsol_packet_field_count, start_of_parse);
	   write_out_struct_csv("tm_packets.csv", (int32_t*)&(tm_packets[0]), tm_field_names, (int)tm_packets.size(), tm_packet_field_count, start_of_parse);
	   write_out_struct_csv("status_packets.csv", (uint64_t*)&(status_packets[0]), status_field_names, (int)status_packets.size(), status_packet_field_count, start_of_parse);

	   write_out_struct_csv("gyro_times.csv", (uint32_t*)&(gyro_time[0]), gps_time_field_names, gyro_time.size(), gps_time_field_count, start_of_parse);
	   write_out_struct_csv("xl_times.csv", (uint32_t*)&(accel_time[0]), gps_time_field_names, accel_time.size(), gps_time_field_count, start_of_parse);
	   write_out_struct_csv("mag_times.csv", (uint32_t*)&(mag_time[0]), gps_time_field_names, mag_time.size(), gps_time_field_count, start_of_parse);
	   write_out_struct_csv("gyro_times.csv", (uint32_t*)&(gyro_time_mark[0]), gps_time_field_names, gyro_time_mark.size(), gps_time_field_count, start_of_parse);
	   write_out_struct_csv("status_p_time_mark.csv", (uint32_t*)&(status_p_time_mark[0]), gps_time_field_names, status_p_time_mark.size(), gps_time_field_count, start_of_parse);
    //write_out_struct_csv("audio_times.csv", (uint32_t*)&(audio_time[0]), gps_time_field_names, audio_time.size(), gps_time_field_count, start_of_parse);
    }
     


	   start_of_parse = 0;

	   audio_l.clear();
	   audio_r.clear();
	   sequence_number.clear();
	   gyro_segment_stream.clear();
	   accel_segment_stream.clear();
	   mag_segment_stream.clear();
	   tim_tp_packets.clear();
	   navsol_packets.clear();
	   tm_packets.clear();
	   status_packets.clear();
	   gyro_time.clear();
	   accel_time.clear();
	   mag_time.clear();
	   gyro_time_mark.clear(); 
	   status_p_time_mark.clear();
	   audio_time.clear();


	   g_packets_num.clear();
	   xl_packets_num.clear();
	   mag_packets_num.clear();
	   aud_packets_num.clear();



	    xl_packets = -1;
	    mag_packets = -1;
	    g_packets = -1;
	    aud_packets = -1;


		}
		in.close();




    //  // //Copy data into matlab memory
    //  // //Copy AudioL,AudioR,Segment,IMU Data

    //   int*  al_copy = (int*)mxCalloc(audio_l.size(), sizeof(int));
    //   std::copy(audio_l.begin(), audio_l.end(), al_copy);
    //   plhs[0] = mxCreateNumericMatrix(1, audio_l.size(), mxINT32_CLASS, mxREAL);
    //   mxSetData(plhs[0], al_copy);
	   //
    //   int*  ar_copy = (int*)mxCalloc(audio_r.size(), sizeof(int));
    //   std::copy(audio_r.begin(), audio_r.end(), ar_copy);
    //   plhs[1] = mxCreateNumericMatrix(1, audio_r.size(), mxINT32_CLASS, mxREAL);
    //   mxSetData(plhs[1], ar_copy);
    //   int*  seg_copy = (int*)mxCalloc(sequence_number.size(), sizeof(int));
    //   std::copy(sequence_number.begin(), sequence_number.end(), seg_copy);
    //   plhs[2] = mxCreateNumericMatrix(1, sequence_number.size(), mxINT32_CLASS, mxREAL);
    //   mxSetData(plhs[2], seg_copy);


    //   int*  gyro_copy = (int*)mxCalloc(gyro_segment_stream.size(), sizeof(int));
    //   std::copy(gyro_segment_stream.begin(), gyro_segment_stream.end(), gyro_copy);
    //   plhs[3] = mxCreateNumericMatrix(1, gyro_segment_stream.size(), mxINT32_CLASS, mxREAL);
    //   mxSetData(plhs[3], gyro_copy);

    //   int*  xl_copy = (int*)mxCalloc(accel_segment_stream.size(), sizeof(int));
    //   std::copy(accel_segment_stream.begin(), accel_segment_stream.end(), xl_copy);
    //   plhs[4] = mxCreateNumericMatrix(1, accel_segment_stream.size(), mxINT32_CLASS, mxREAL);
    //   mxSetData(plhs[4], xl_copy);

    //   int*  mag_copy = (int*)mxCalloc(mag_segment_stream.size(), sizeof(int));
    //   std::copy(mag_segment_stream.begin(), mag_segment_stream.end(), mag_copy);
    //   plhs[5] = mxCreateNumericMatrix(1, mag_segment_stream.size(), mxINT32_CLASS, mxREAL);
    //   mxSetData(plhs[5], mag_copy);


    //   //Copy Status, TM_TIM2, and NAV_SOL structures.

    //   plhs[6] = mxCreateStructMatrix(1, status_packets.size(), status_packet_field_count, &status_names_pointers[0]);
    //   for (int i = 0; i<status_packets.size(); i++) {
    //     uint64_t* offset = (uint64_t*)&(status_packets[i]);
    //     for (int j = 0; j < status_packet_field_count; j++){
    //       mxArray *field_value;
    //       field_value = mxCreateNumericMatrix(1, 1, mxUINT64_CLASS, mxREAL);
    //       uint64_t*  copy = (uint64_t*)mxCalloc(1, sizeof(uint64_t));
    //       //More explicit casting and calculation of pointer works.
    //       //This is versus status_segments[i] + j*sizeof(uint64_t) which didn't work. 
    //       std::memcpy(copy, offset, sizeof(uint64_t));
    //       offset++;
    //       mxSetData(field_value, copy);
    //       mxSetFieldByNumber(plhs[6], i, j, field_value);
    //     }
    //   }


    //   plhs[7] = mxCreateStructMatrix(1, tm_packets.size(), tm_packet_field_count, &tm_names_pointers[0]);
    //   for (int i = 0; i<tm_packets.size(); i++) {
    //     int32_t* offset = (int32_t*)&(tm_packets[i]);
    //     for (int j = 0; j < tm_packet_field_count; j++){
    //       mxArray *field_value;
    //       field_value = mxCreateNumericMatrix(1, 1, mxINT32_CLASS, mxREAL);
    //       int32_t*  copy = (int32_t*)mxCalloc(1, sizeof(int32_t));
    //       std::memcpy(copy, offset, sizeof(int32_t));
    //       offset++;
    //       mxSetData(field_value, copy);
    //       mxSetFieldByNumber(plhs[7], i, j, field_value);
    //     }
    //   }

    //   plhs[8] = mxCreateStructMatrix(1, navsol_packets.size(), navsol_packet_field_count, &navsol_names_pointers[0]);
    //   for (int i = 0; i<navsol_packets.size(); i++) {
    //     int32_t* offset = (int32_t*)&(navsol_packets[i]);
    //     for (int j = 0; j < navsol_packet_field_count; j++){
    //       mxArray *field_value;
    //       field_value = mxCreateNumericMatrix(1, 1, mxINT32_CLASS, mxREAL);
    //       int32_t*  copy = (int32_t*)mxCalloc(1, sizeof(int32_t));
    //       std::memcpy(copy, offset, sizeof(int32_t));
    //       offset++;
    //       mxSetData(field_value, copy);
    //       mxSetFieldByNumber(plhs[8], i, j, field_value);
    //     }
    //   }
    //   
    //   
    //   
    //  plhs[9] = mxCreateStructMatrix(1, tim_tp_packets.size(), tim_tp_field_count, &tim_tp_names_pointers[0]);
    //   for (int i = 0; i<tim_tp_packets.size(); i++) {
    //     int32_t* offset = (int32_t*)&(tim_tp_packets[i]);
    //     for (int j = 0; j < tim_tp_field_count; j++){
    //       mxArray *field_value;
    //       field_value = mxCreateNumericMatrix(1, 1, mxINT32_CLASS, mxREAL);
    //       int32_t*  copy = (int32_t*)mxCalloc(1, sizeof(int32_t));
    //       std::memcpy(copy, offset, sizeof(int32_t));
    //       offset++;
    //       mxSetData(field_value, copy);
    //       mxSetFieldByNumber(plhs[9], i, j, field_value);
    //     }
    //   }


	   //copy_out_uint32(gyro_time.size(), gps_time_field_count, 10, &(gyro_time[0]), plhs);
	   //copy_out_uint32(accel_time.size(), gps_time_field_count, 11, &(accel_time[0]), plhs);
	   //copy_out_uint32(mag_time.size(), gps_time_field_count, 12, &(mag_time[0]), plhs);
	   ////These are the actual status packet time marks. 
	   //copy_out_uint32(gyro_time_mark.size(), gps_time_field_count, 13, &(gyro_time_mark[0]), plhs);
	   //copy_out_uint32(status_p_time_mark.size(), gps_time_field_count, 14, &(status_p_time_mark[0]), plhs);
	   //copy_out_uint32(audio_time.size(), gps_time_field_count, 15, &(audio_time[0]), plhs);


       
  ////////////////////////////////////////     
       
      //plhs[10] = mxCreateStructMatrix(1, gyro_time.size(), gps_time_field_count, &gps_time_names_pointers[0]);
      // for (int i = 0; i < gyro_time.size(); i++) {
      //   uint32_t* offset = (uint32_t*)&(gyro_time[i]);
      //   for (int j = 0; j < gps_time_field_count; j++){
      //     mxArray *field_value;
      //     field_value = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
      //     uint32_t*  copy = (uint32_t*)mxCalloc(1, sizeof(uint32_t));
      //     std::memcpy(copy, offset, sizeof(uint32_t));
      //     offset++;
      //     mxSetData(field_value, copy);
      //     mxSetFieldByNumber(plhs[10], i, j, field_value);
      //   }
      // }
      // 
      //plhs[11] = mxCreateStructMatrix(1, accel_time.size(), gps_time_field_count, &gps_time_names_pointers[0]);
      // for (int i = 0; i < accel_time.size(); i++) {
      //   uint32_t* offset = (uint32_t*)&(accel_time[i]);
      //   for (int j = 0; j < gps_time_field_count; j++){
      //     mxArray *field_value;
      //     field_value = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
      //     uint32_t*  copy = (uint32_t*)mxCalloc(1, sizeof(uint32_t));
      //     std::memcpy(copy, offset, sizeof(uint32_t));
      //     offset++;
      //     mxSetData(field_value, copy);
      //     mxSetFieldByNumber(plhs[11], i, j, field_value);
      //   }
      // }
      // 
      //plhs[12] = mxCreateStructMatrix(1, mag_time.size(), gps_time_field_count, &gps_time_names_pointers[0]);
      // for (int i = 0; i < mag_time.size(); i++) {
      //   uint32_t* offset = (uint32_t*)&(mag_time[i]);
      //   for (int j = 0; j < gps_time_field_count; j++){
      //     mxArray *field_value;
      //     field_value = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
      //     uint32_t*  copy = (uint32_t*)mxCalloc(1, sizeof(int32_t));
      //     std::memcpy(copy, offset, sizeof(uint32_t));
      //     offset++;
      //     mxSetData(field_value, copy);
      //     mxSetFieldByNumber(plhs[12], i, j, field_value);
      //   }
      // }

      // plhs[13] = mxCreateStructMatrix(1, gyro_time_mark.size(), gps_time_field_count, &gps_time_names_pointers[0]);
      // for (int i = 0; i < gyro_time_mark.size(); i++) {
      //   uint32_t* offset = (uint32_t*)&(gyro_time_mark[i]);
      //  for (int j = 0; j < gps_time_field_count; j++){
      //    mxArray *field_value;
      //    field_value = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
      //    uint32_t*  copy = (uint32_t*)mxCalloc(1, sizeof(uint32_t));
      //    std::memcpy(copy, offset, sizeof(int32_t));
      //    offset++;
      //    mxSetData(field_value, copy);
      //    mxSetFieldByNumber(plhs[13], i, j, field_value);
      //  }
      // }
      // 
      //plhs[14] = mxCreateStructMatrix(1, status_p_time_mark.size(), gps_time_field_count, &gps_time_names_pointers[0]);
      // for (int i = 0; i < status_p_time_mark.size(); i++) {
      //   uint32_t* offset = (uint32_t*)&(status_p_time_mark[i]);
      //  for (int j = 0; j < gps_time_field_count; j++){
      //    mxArray *field_value;
      //    field_value = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
      //    uint32_t*  copy = (uint32_t*)mxCalloc(1, sizeof(uint32_t));
      //    std::memcpy(copy, offset, sizeof(int32_t));
      //    offset++;
      //    mxSetData(field_value, copy);
      //    mxSetFieldByNumber(plhs[14], i, j, field_value);
      //  }
      // }




   //    plhs[15] = mxCreateNumericMatrix(audio_time.size(), gps_time_field_count, mxUINT32_CLASS, mxREAL);
   //    uint32_t* output = (uint32_t *)mxGetData(plhs[15]);
   //    uint32_t* start = (uint32_t *)mxGetData(plhs[15]);

   //    for (int i = 0; i < audio_time.size(); i++) {
		 //uint32_t* offset = (uint32_t*)&(audio_time[i]);
		 //output = start + i;
   //      for (int j = 0; j < gps_time_field_count; j++){
   //        //uint32_t*  copy = (uint32_t*)mxCalloc(1, sizeof(uint32_t));
   //        std::memcpy(output, offset, sizeof(uint32_t));
   //        offset++;
		 //  output = output + (audio_time.size());
   //      }
   //    }






       //plhs[16] = mxCreateStructMatrix(1, gyro_time.size(), gps_time_field_count, &gps_time_names_pointers[0]);
       // for (int i = 0; i < gyro_time.size(); i++) {
       //   uint32_t* offset = (uint32_t*)&(gyro_time[i]);
       //   for (int j = 0; j < gps_time_field_count; j++){
       //     mxArray *field_value;
       //     field_value = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
       //     uint32_t*  copy = (uint32_t*)mxCalloc(1, sizeof(uint32_t));
       //     std::memcpy(copy, offset, sizeof(uint32_t));
       //     offset++;
       //     mxSetData(field_value, copy);
       //     mxSetFieldByNumber(plhs[16], i, j, field_value);
       //   }
       // }




	   


       printf("audio_l is %d MB\n", (audio_l.size() * sizeof(int)) / (1024 * 1024));
       printf("audio_r is %d MB\n", (audio_r.size() * sizeof(int)) / (1024 * 1024));
       printf("Audio_Time is %d MB\n", (audio_time.size() * sizeof(uint32_t) * 6) / (1024 * 1024));

    cout << "Finished Processing File" << std::endl;


    std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();

    std::cout << "Time difference = " << std::chrono::duration_cast<std::chrono::seconds> (end - begin).count() << std::endl;
    mexPrintf("Total Time difference = %d\n",std::chrono::duration_cast<std::chrono::seconds> (end - begin).count());
    //mexPrintf("Matlab Copy difference = %d\n",std::chrono::duration_cast<std::chrono::seconds> (end - start_matlab_copy).count());




  //std::string  = //Change filename .bin to filename.mat.
  //printf("Creating file %s...\n\n", file);
  //pmat = matOpen(file, "w");

  ////Put the variables into a mat file.
  //memcpy((void *)(mxGetPr(pa1)), (void *)data, sizeof(data));
  //status = matPutVariable(pmat, "LocalDouble", pa1);
  //if (status != 0) {
  //  printf("%s :  Error using matPutVariable on line %d\n", __FILE__, __LINE__);
  //  return(EXIT_FAILURE);
  //}


    //return 0;
  }
  
  //Function to mask away certain parts of larger GPS time.
  gps_time populate_gps_time (uint64_t time)
  
  {

    //Amount to shift result down. 
    int shift_week = 50;
    int shift_ms = 20;
    int shift_nano = 0;
    
    //NOTE
    //The masks are defined big endian, yet I read the card
    //as little endian. I need a byte swap so the week number
    //is at the top of the bits. 
    //time = _byteswap_uint64(time);

    uint64_t week = 0;
    uint64_t ms = 0;
    uint64_t nano = 0;
    
    gps_time cur_gps_time;
    
    
    week = (time & week_mask);
    week = week >> shift_week;
    cur_gps_time.week_num = uint32_t(week);

    ms = (time & milli_mask);
    ms = ms >> shift_ms;
    cur_gps_time.milli_num = uint32_t(ms);
   
    
    nano = (time & nano_mask) >> shift_nano;
    nano = nano >> shift_nano;
    cur_gps_time.nano_num = uint32_t(nano);
    
    return cur_gps_time;
       
  }
  
  //Function I had though of using to store all times as double.
  //Suggested by team member this wouldn't work.
    double gps_to_seconds (uint64_t time)
  {

    //Amount to shift result down. 
    int shift_week = 50;
    int shift_ms = 20;
    int shift_nano = 0;
    

    uint64_t week = 0;
    uint64_t ms = 0;
    uint64_t nano = 0;
    
    double cur_time_seconds;
    
    
week = (time & week_mask);
week = week >> shift_week;

ms = (time & milli_mask);
ms = ms >> shift_ms;

nano = (time & nano_mask) >> shift_nano;
nano = nano >> shift_nano;

cur_time_seconds = (week * 604800) + (ms / (1e3)) + (nano / (1e9));


return cur_time_seconds;

  }


  //Bback annotate all samples with ms and ns they occured at
  //using the status packets latest time marks. 



  //Search through the time mark segments and calculate a time offset for
  //a given chunk of samples. 





  int back_annotate(vector<gps_time>& reset_time, vector<tim_tp_packet>& tim_tp_packets, vector<int>& update_marks, int sample_rate_ms, int sample_rate_ns)
  {
    int begin = 0;
    int end = 0;
    int resume = 0;
    int64_t ms_count = 0;
    int64_t ns_count = 0;

    int offset_ms;
    int offset_week;
    int offset_ns;
    int gps_reset_time;
    int result;

    vector<int> packet_number;
    vector<int> packet_offset;

    int debug;

    for (int i = 0; i < (update_marks.size() - 1); i++)
    {

      //Begin update. 
      begin = (update_marks)[i];
      //if (begin == 0)
      //{}
      //else
      //{ begin = begin + 1; }
      end = (update_marks)[i + 1];

      ms_count = (reset_time)[end + 1].milli_num;
      ns_count = (reset_time)[end + 1].nano_num;
      for (int j = end; j > begin; j--)
      {
        //Subtract nanoseconds and check for rollover of millisecond.

        (reset_time)[j].milli_num = ms_count;
        (reset_time)[j].nano_num = ns_count;


        ms_count = ms_count - sample_rate_ms;
        ns_count = ns_count - sample_rate_ns;

        if (ns_count < 0)
        {
          ms_count = ms_count - 1;
          ns_count = int(1E6) - abs(ns_count);
        }

                ////Adjust the ns count depending on ms rollover.

                //result = ns_count - offset_ns;

                //  if (result >= 0 ){

                //    (reset_time)[j].gps_nano_num = result;
                //  }
                //  else{
                //    (reset_time)[j].gps_milli_num = (reset_time)[j].gps_milli_num - 1;

                //   (reset_time)[j].gps_nano_num = int(1E6) - abs(result);


                //  }

              }

            packet_number.push_back(end-begin);
            packet_offset.push_back((reset_time)[begin+1].milli_num - (reset_time)[begin].milli_num);

            debug = (reset_time)[begin + 1].milli_num - (reset_time)[begin].milli_num;


          }


    if (tim_tp_packets.size() != 0)
    { 
    //Now update all absolute//gps times.
    int k = 0;
    offset_ms = (tim_tp_packets)[k].gps_time_ms - (tim_tp_packets)[k].reset_time_ms;
    offset_week = (tim_tp_packets)[k].gps_time_week - (tim_tp_packets)[k].reset_time_week;
    offset_ns = 0;


    for (int j = 0; j < reset_time.size(); j++)
    {

      int test = (tim_tp_packets)[k + 1].reset_time_ms;
      int test_2 = (reset_time)[j].milli_num;

      if (test < test_2)
      {
        if (k < tim_tp_packets.size()-1)
        {
          k = k + 1;
        }
        offset_ms = (tim_tp_packets)[k].gps_time_ms - (tim_tp_packets)[k].reset_time_ms;
        offset_week = (tim_tp_packets)[k].gps_time_week - (tim_tp_packets)[k].reset_time_week;

      }


      (reset_time)[j].gps_week_num = (reset_time)[j].week_num + offset_week;
      (reset_time)[j].gps_milli_num = (reset_time)[j].milli_num + offset_ms;
      (reset_time)[j].gps_nano_num = (reset_time)[j].nano_num + offset_ns;


    }
    }



    return 1;
    }



	int copy_out_uint32(int m, int n, int lfs_num, gps_time* time_ptr, mxArray** plhs)

	{
		plhs[lfs_num] = mxCreateNumericMatrix(m, n, mxUINT32_CLASS, mxREAL);
		uint32_t* output = (uint32_t *)mxGetData(plhs[lfs_num]);
		uint32_t* start = (uint32_t *)mxGetData(plhs[lfs_num]);
    //Change from row major (C) to column major (Matlab)
		for (int i = 0; i < m; i++) {
      uint32_t* offset = (uint32_t*)&(time_ptr[i]);
			output = start + i;
			for (int j = 0; j < n; j++){
				std::memcpy(output, offset, sizeof(uint32_t));
				offset++;
				output = output + m;
			}
		}

		return 0;
	}


  int write_int_vector_csv(const std::string& input, vector<int>& vector_in, int start_of_parse)

  {
    std::ofstream myfile;
	myfile.open(input, std::ios::out | std::ios::app);
  if (start_of_parse){

			  myfile << input << '\n';
		  }
    
    for (int k = 0; k < vector_in.size(); k++)
    {
      myfile << std::to_string(vector_in[k]) << "\n";
    }
    myfile.close();


    return 0;
  }
  
    int write_int_vector_binary(const std::string& input, vector<int>& vector_in)

  {
    std::ofstream myfile;
	myfile.open(input, std::ios::out | std::ios::binary | std::ios::app );
  const char* pointer = 0;
    for (int k = 0; k < vector_in.size(); k++)
    {
      pointer = reinterpret_cast<const char*>(&vector_in[k]);
      myfile.write(pointer, sizeof(int));
    }
    myfile.close();


    return 0;
  }
  
  

  int write_out_struct_csv(const std::string& input, int32_t* input_vector_of_structures, std::vector<const std::string>&field_names, int length, int field_count, int start_of_parse)

  {
	  std::ofstream myfile;
	  myfile.open(input, std::ios::out | std::ios::app);
	  if (start_of_parse){
		  for (int k = 0; k < field_count; k++)
		  {
			  myfile << field_names[k] << ',';
		  }
	  myfile << '\n';
	}

	int32_t* offset = input_vector_of_structures;
	for (int i = 0; i<length; i++) {
		for (int j = 0; j < field_count; j++){

			myfile << std::to_string(*(offset)) << ',';
			offset++;
		}
		myfile << '\n';
	}
    myfile.close();
    return 0;
  }

  int write_out_struct_csv(const std::string& input, uint64_t* input_vector_of_structures, std::vector<const std::string>&field_names, int length, int field_count, int start_of_parse)

  {
    std::ofstream myfile;
	myfile.open(input, std::ios::out | std::ios::app);
	if (start_of_parse){
		for (int k = 0; k < field_count; k++)
		{
			myfile << field_names[k] << ',';
		}
		myfile << '\n';
	}

	uint64_t* offset = input_vector_of_structures;
	for (int i = 0; i<length; i++) {
		for (int j = 0; j < field_count; j++){

			myfile << std::to_string(*(offset)) << ',';
			offset++;
		}
		myfile << '\n';
	}
    myfile.close();
    return 0;
  }

  int write_out_struct_csv(const std::string& input, uint32_t* input_vector_of_structures, std::vector<const std::string>&field_names, int length, int field_count, int start_of_parse)

  {
	  std::ofstream myfile;
	  myfile.open(input, std::ios::out | std::ios::app);
	  if (start_of_parse){
		  for (int k = 0; k < field_count; k++)
		  {
			  myfile << field_names[k] << ',';
		  }
		  myfile << '\n';
	  }

	  uint32_t* offset = input_vector_of_structures;
	  for (int i = 0; i<length; i++) {
		  for (int j = 0; j < field_count; j++){

			  myfile << std::to_string(*(offset)) << ',';
			  offset++;
		  }
		  myfile << '\n';
	  }
	  myfile.close();
	  return 0;
  }
  
  int write_out_struct_binary(const std::string& input, uint64_t* input_vector_of_structures, std::vector<const std::string>&field_names, int length, int field_count, int start_of_parse)

  {
    std::ofstream myfile;
	myfile.open(input, std::ios::out | std::ios::binary | std::ios::app);
  
	uint64_t* offset = input_vector_of_structures;
  const char* pointer = 0;
  pointer = reinterpret_cast<const char*>(offset);
	for (int i = 0; i<length; i++) {
		for (int j = 0; j < field_count; j++){

      myfile.write(pointer, sizeof(uint64_t));
			offset++;
      pointer = reinterpret_cast<const char*>(offset);
      
		}
	}
    myfile.close();
    return 0;
  }
  
  int write_out_struct_binary(const std::string& input, uint32_t* input_vector_of_structures, std::vector<const std::string>&field_names, int length, int field_count, int start_of_parse)

  {
    std::ofstream myfile;
	myfile.open(input, std::ios::out | std::ios::binary | std::ios::app);
  
	uint32_t* offset = input_vector_of_structures;
  const char* pointer = 0;
  pointer = reinterpret_cast<const char*>(offset);
	for (int i = 0; i<length; i++) {
		for (int j = 0; j < field_count; j++){

      myfile.write(pointer, sizeof(uint32_t));
			offset++;
      pointer = reinterpret_cast<const char*>(offset);
      
		}
	}
    myfile.close();
    return 0;
  }
  
    int write_out_struct_binary(const std::string& input, int32_t* input_vector_of_structures, std::vector<const std::string>&field_names, int length, int field_count, int start_of_parse)

  {
    std::ofstream myfile;
	myfile.open(input, std::ios::out | std::ios::binary | std::ios::app);
  
	int32_t* offset = input_vector_of_structures;
  const char* pointer = 0;
  pointer = reinterpret_cast<const char*>(offset);
	for (int i = 0; i<length; i++) {
		for (int j = 0; j < field_count; j++){

      myfile.write(pointer, sizeof(int32_t));
			offset++;
      pointer = reinterpret_cast<const char*>(offset);
      
		}
	}
    myfile.close();
    return 0;
  }
  

  
  

  //plhs[9] = mxCreateStructMatrix(1, tim_tp_packets.size(), tim_tp_field_count, &tim_tp_names_pointers[0]);
  //for (int i = 0; i<tim_tp_packets.size(); i++) {
	 // int32_t* offset = (int32_t*)&(tim_tp_packets[i]);
	 // for (int j = 0; j < tim_tp_field_count; j++){
		//  mxArray *field_value;
		//  field_value = mxCreateNumericMatrix(1, 1, mxINT32_CLASS, mxREAL);
		//  int32_t*  copy = (int32_t*)mxCalloc(1, sizeof(int32_t));
		//  std::memcpy(copy, offset, sizeof(int32_t));
		//  offset++;
		//  mxSetData(field_value, copy);
		//  mxSetFieldByNumber(plhs[9], i, j, field_value);
	 // }
  //}

  

