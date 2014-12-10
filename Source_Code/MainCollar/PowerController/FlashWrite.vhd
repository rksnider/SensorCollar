-- megafunction wizard: %Parallel Flash Loader%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: altparallel_flash_loader 

-- ============================================================
-- File Name: FlashWrite.vhd
-- Megafunction Name(s):
-- 			altparallel_flash_loader
--
-- Simulation Library Files(s):
-- 			altera_mf
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 13.1.0 Build 162 10/23/2013 SJ Full Version
-- ************************************************************


--Copyright (C) 1991-2013 Altera Corporation
--Your use of Altera Corporation's design tools, logic functions 
--and other software and tools, and its AMPP partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Altera Program License 
--Subscription Agreement, Altera MegaCore Function License 
--Agreement, or other applicable license agreement, including, 
--without limitation, that your use is for the sole purpose of 
--programming logic devices manufactured by Altera and sold by 
--Altera or its authorized distributors.  Please refer to the 
--applicable agreement for further details.


LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY FlashWrite IS
	PORT
	(
		pfl_flash_access_granted		: IN STD_LOGIC ;
		pfl_nreset		: IN STD_LOGIC ;
		flash_io0		: INOUT STD_LOGIC_VECTOR (0 DOWNTO 0);
		flash_io1		: INOUT STD_LOGIC_VECTOR (0 DOWNTO 0);
		flash_io2		: INOUT STD_LOGIC_VECTOR (0 DOWNTO 0);
		flash_io3		: INOUT STD_LOGIC_VECTOR (0 DOWNTO 0);
		flash_ncs		: OUT STD_LOGIC_VECTOR (0 DOWNTO 0);
		flash_sck		: OUT STD_LOGIC_VECTOR (0 DOWNTO 0);
		pfl_flash_access_request		: OUT STD_LOGIC 
	);
END FlashWrite;


ARCHITECTURE SYN OF flashwrite IS

	SIGNAL sub_wire0	: STD_LOGIC ;
	SIGNAL sub_wire1	: STD_LOGIC_VECTOR (0 DOWNTO 0);
	SIGNAL sub_wire2	: STD_LOGIC_VECTOR (0 DOWNTO 0);



	COMPONENT altparallel_flash_loader
	GENERIC (
		extra_addr_byte		: NATURAL;
		features_cfg		: NATURAL;
		features_pgm		: NATURAL;
		flash_type		: STRING;
		n_flash		: NATURAL;
		qflash_fast_speed		: NATURAL;
		qflash_mfc		: STRING;
		tristate_checkbox		: NATURAL;
		lpm_type		: STRING
	);
	PORT (
			flash_io3	: INOUT STD_LOGIC_VECTOR (0 DOWNTO 0);
			pfl_flash_access_granted	: IN STD_LOGIC ;
			pfl_flash_access_request	: OUT STD_LOGIC ;
			flash_io0	: INOUT STD_LOGIC_VECTOR (0 DOWNTO 0);
			flash_io2	: INOUT STD_LOGIC_VECTOR (0 DOWNTO 0);
			flash_ncs	: OUT STD_LOGIC_VECTOR (0 DOWNTO 0);
			flash_io1	: INOUT STD_LOGIC_VECTOR (0 DOWNTO 0);
			flash_sck	: OUT STD_LOGIC_VECTOR (0 DOWNTO 0);
			pfl_nreset	: IN STD_LOGIC 
	);
	END COMPONENT;

BEGIN
	pfl_flash_access_request    <= sub_wire0;
	flash_ncs    <= sub_wire1(0 DOWNTO 0);
	flash_sck    <= sub_wire2(0 DOWNTO 0);

	altparallel_flash_loader_component : altparallel_flash_loader
	GENERIC MAP (
		extra_addr_byte => 0,
		features_cfg => 0,
		features_pgm => 1,
		flash_type => "QUAD_SPI_FLASH",
		n_flash => 1,
		qflash_fast_speed => 0,
		qflash_mfc => "NUMONYX",
		tristate_checkbox => 0,
		lpm_type => "altparallel_flash_loader"
	)
	PORT MAP (
		pfl_flash_access_granted => pfl_flash_access_granted,
		pfl_nreset => pfl_nreset,
		pfl_flash_access_request => sub_wire0,
		flash_ncs => sub_wire1,
		flash_sck => sub_wire2,
		flash_io3 => flash_io3,
		flash_io0 => flash_io0,
		flash_io2 => flash_io2,
		flash_io1 => flash_io1
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: IDC_FLASH_TYPE_COMBO STRING "Quad SPI Flash"
-- Retrieval info: PRIVATE: IDC_NUM_QFLASH_COMBO STRING "1"
-- Retrieval info: PRIVATE: IDC_OPERATING_MODES_COMBO STRING "Flash Programming"
-- Retrieval info: PRIVATE: IDC_QFLASH_FAST_SPEED_CHECKBOX STRING "0"
-- Retrieval info: PRIVATE: IDC_QFLASH_MFC_COMBO STRING "Micron"
-- Retrieval info: PRIVATE: IDC_QFLASH_SIZE_COMBO STRING "QSPI 128 Mbit"
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "MAX V"
-- Retrieval info: PRIVATE: TRISTATE_CHECKBOX STRING "0"
-- Retrieval info: CONSTANT: EXTRA_ADDR_BYTE NUMERIC "0"
-- Retrieval info: CONSTANT: FEATURES_CFG NUMERIC "0"
-- Retrieval info: CONSTANT: FEATURES_PGM NUMERIC "1"
-- Retrieval info: CONSTANT: FLASH_TYPE STRING "QUAD_SPI_FLASH"
-- Retrieval info: CONSTANT: N_FLASH NUMERIC "1"
-- Retrieval info: CONSTANT: QFLASH_FAST_SPEED NUMERIC "0"
-- Retrieval info: CONSTANT: QFLASH_MFC STRING "NUMONYX"
-- Retrieval info: CONSTANT: TRISTATE_CHECKBOX NUMERIC "0"
-- Retrieval info: USED_PORT: flash_io0 0 0 1 0 BIDIR NODEFVAL "flash_io0[0..0]"
-- Retrieval info: USED_PORT: flash_io1 0 0 1 0 BIDIR NODEFVAL "flash_io1[0..0]"
-- Retrieval info: USED_PORT: flash_io2 0 0 1 0 BIDIR NODEFVAL "flash_io2[0..0]"
-- Retrieval info: USED_PORT: flash_io3 0 0 1 0 BIDIR NODEFVAL "flash_io3[0..0]"
-- Retrieval info: USED_PORT: flash_ncs 0 0 1 0 OUTPUT NODEFVAL "flash_ncs[0..0]"
-- Retrieval info: USED_PORT: flash_sck 0 0 1 0 OUTPUT NODEFVAL "flash_sck[0..0]"
-- Retrieval info: USED_PORT: pfl_flash_access_granted 0 0 0 0 INPUT NODEFVAL "pfl_flash_access_granted"
-- Retrieval info: USED_PORT: pfl_flash_access_request 0 0 0 0 OUTPUT NODEFVAL "pfl_flash_access_request"
-- Retrieval info: USED_PORT: pfl_nreset 0 0 0 0 INPUT NODEFVAL "pfl_nreset"
-- Retrieval info: CONNECT: @pfl_flash_access_granted 0 0 0 0 pfl_flash_access_granted 0 0 0 0
-- Retrieval info: CONNECT: @pfl_nreset 0 0 0 0 pfl_nreset 0 0 0 0
-- Retrieval info: CONNECT: flash_io0 0 0 1 0 @flash_io0 0 0 1 0
-- Retrieval info: CONNECT: flash_io1 0 0 1 0 @flash_io1 0 0 1 0
-- Retrieval info: CONNECT: flash_io2 0 0 1 0 @flash_io2 0 0 1 0
-- Retrieval info: CONNECT: flash_io3 0 0 1 0 @flash_io3 0 0 1 0
-- Retrieval info: CONNECT: flash_ncs 0 0 1 0 @flash_ncs 0 0 1 0
-- Retrieval info: CONNECT: flash_sck 0 0 1 0 @flash_sck 0 0 1 0
-- Retrieval info: CONNECT: pfl_flash_access_request 0 0 0 0 @pfl_flash_access_request 0 0 0 0
-- Retrieval info: GEN_FILE: TYPE_NORMAL FlashWrite.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL FlashWrite.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL FlashWrite.cmp FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL FlashWrite.bsf FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL FlashWrite_inst.vhd FALSE
-- Retrieval info: LIB_FILE: altera_mf
