# -*- coding: utf-8 -*-
"""
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Tyler B. Davis
Electrical and Computer Engineering
Montana State University
610 Cobleigh Hall
Bozeman, MT 59717
tyler.davis5@msu.montana.edu

"""
import numpy as np
from ReadMif import read_mif
from Adafruit_BBIO.SPI import SPI
from GPIOFacade import GPIOFac
import time as time
 
class CC1120(object):

  def __init__(self, gpio_pin = 'P8_10', sclk = 500000, init_byte_count = 2, \
                init_name = 'CC1120_DEFAULT_MODE.mif'):       
 
        self._init_name = init_name
        self._init_byte_count = init_byte_count
        self._SPI = SPI(0,0)
        self._SPI.msh = sclk
        self._GPIO = GPIOFac(gpio_pin,'in')
        
        # Define the command strobes
        self._SRES_STROBE       = 0x30
        self._SFSTXON_STROBE    = 0x31
        self._SXOFF_STROBE      = 0x32
        self._SCAL_STROBE       = 0x33
        self._SRX_STROBE        = 0x34
        self._STX_STROBE        = 0x35
        self._SIDLE_STROBE      = 0x36
        self._SAFC_STROBE       = 0x37
        self._SWOR_STROBE       = 0x38
        self._SPWD_STROBE       = 0x39
        self._SFRX_STROBE       = 0x3A
        self._SFTX_STROBE       = 0x3B
        self._SWORRST_STROBE    = 0x3C
        self._SNOP_STROBE       = 0x3D
        self._BURSTFIFO_WRITE   = 0x7F
        self._BURSTFIFO_READ    = 0xFF
        self._NBURSTFIFO_WRITE  = 0x3F
        self._NBURSTFIFO_READ   = 0xBF
 
  @property 
  def init_name (self,):
    return self._init_name
      
  @property 
  def init_byte_count(self):
    return self._init_byte_count

  def initalize(self,):
    """
    This function reads in the provided file, then sends to addres and 
    data bytes over SPI to the CC1120 chip.
    """
    
    # Get the initialization payload and get rid of the first byte pair
    # since they only contain the number of addresses to change
    payload = read_mif(self._init_name, self._init_byte_count)[2:]
    
    # Assume the chip isn't ready to begin with
    chip_rdy = False
    
    # Wait for the chip to become ready
    while not chip_rdy:
      
      # Wait for the first bit of the byte to change to a 0.  This is the 
      # same as waiting to see a number less than 128
      if self._SPI.readbytes(1) < [128]:
        chip_rdy = True
        
    # Send each command in the payload to the transmitter
    for cmd in payload:
      self._SPI.writebytes([int(i,16) for i in cmd])
      
    print 'Transmitter initialized'
      
  def transmit_data(self,payload,tdelay=0.2):
    """
    This function transmits a payload over SPI to the CC1120 so it can be 
    broadcast to reciever station
    
      Input:
        payload - A hex string of data to be sent out by the transmitter.
                  The recieved payload has the format '0xH......H where H
                  is a hex character
        tdelay -  Adds a maximum time to wait before the transmission is 
                  regarded as a failure.  A maximum delay of 0.2 seconds
                  was found to be more than sufficient for the successful
                  transmission of a 20 byte packet.
    """
    # Create variables to indicate whether the transmission started and 
    # ended
    tx_start    = False
    tx_finish   = False
    
    # Create a list of bytes from the payload
    byte_list = ['0x' + payload[i:i+2].upper() for i in range(2,len(payload), 2)]
    
    # Format the packet to be transmitted with the burst write command and
    # the packet length
    payload = [self._BURSTFIFO_WRITE, len(byte_list)]
    
    # Reformat the byte list to a list of integers
    packet_data = [int(i,16) for i in byte_list]
    
    # Extend the payload array with the packet data
    payload.extend(packet_data)
    
    # Write the payload to the FIFO
    self._SPI.writebytes(payload)
    
    # Send a TX strobe
    self._SPI.writebytes([self._STX_STROBE])
    
    # Crate two variables for a delay timer
    t   = time.time()
    t0  = time.time()
    
    # Wait for a period of time before completing 
    while t - t0 < tdelay:
      t = time.time()
      if self._GPIO.read():
        tx_start = True
        print 'Transmission started'
        break 
    
    # If the transmission started,
    if tx_start:
    
      # reset the timeout variables 
      t   = time.time()
      t0  = time.time()
      
      # Wait for another delay period before the transmission is regarded
      # as a failure
      while t - t0 < tdelay:
        if not self._GPIO.read():
          tx_finish = True
          print 'Data transmitted'
          break
    else:
      print 'Data transmission error: Transmission not started'
    if not tx_finish:
      print 'Data transmission error: Transmission failed'
    
    # Tell the transmitter to return to the idle state
    self._SPI.writebytes([self._SIDLE_STROBE])
    
  def recieve_data(self,Nbytes,duration,timeout=30,):
    """
    This function tells the CC1120 to enter recieve mode until the timer 
    expires or a packet is recieved.
    
      Input:
        Nbytes    - The number of bytes to expect from the packet
        duration  - The time in seconds to wait for a packet to be recieved
        timeout   - The time in seconds to wait for the packet to be read 
                    from the transmitter
        
      Output:
        payload   - The recieved data packet.  If no packet was recieved,
                    the returned data will be all zeros
    """
    # Initialize the timer variables
    t = time.time()
    start_time = time.time()
    
    # Initialize the variables to indicate that a packet was recieved and 
    # that packet is ready to be read out (i.e. loaded in the transmitter'same
    # FIFO)
    packet_recieved = False
    packet_loaded = False
    
    # Send the command to move into recieve mode
    self._SPI.writebytes([self._SRX_STROBE])
    
    # Wait for a specified duration for a packet to be recieved
    while (t-start_time < duration):
      t = time.time()
      
      # If the GPIO3 line goes high, a packet was received
      if self._GPIO.read():
        print 'Packet recieved'
        
        # Indicate a packet is recieved and break out of the first waiting
        # loop
        packet_recieved = True
        break
    
    # If no packet was recieved, return 0
    if packet_recieved == False:
      print 'No packet recieved'
      
      # Tell the transmitter to return to the idle state
      self._SPI.writebytes([self._SIDLE_STROBE])
      return 0
      
    # Start a new timer for reading out the packet
    tout = time.time()-t
    
    # While the packet is not read out from the transmitter and we haven't 
    # timed out
    while not packet_loaded and tout < timeout:
    
      # Update the timer
      tout =  time.time()-t
      
      # Wait for the GPIO3 line to go low again (this indicates the packet
      # is ready to be read out)
      if not self._GPIO.read():
          print 'Packet loaded.  Reading out'
          
          # Set the packet loaded to true to indicate it was ready to be
          # read from the buffer
          packet_loaded = True
          
          # Create an array of bytes to send to the transmitter to get the
          # packet out.  Start with the burst read byte
          read_bytes = [self._BURSTFIFO_READ]
          
          # Add null bytes to the read array.  Include and extra for the 
          # packet length byte
          [read_bytes.append(0) for i in range(0,Nbytes+1)]
          
          # Send the bytes over the MOSI and simultaniously record the MISO
          payload = self._SPI.xfer2(read_bytes)
          
          print 'Recieve complete'
          
          # Tell the transmitter to return to the idle state
          self._SPI.writebytes([self._SIDLE_STROBE])
          
          return payload[2:]
        
    print 'Recieve failed'
    
    # Tell the transmitter to return to the idle state
    self._SPI.writebytes([self._SIDLE_STROBE])
    return 0
    
  def flush_RX(self,):
    """
    This function clears all the data from the RX FIFO.  Based on the 
    CC1120 development kit, it is good practice to flush the FIFO after 
    every packet.
    """
    self._SPI.writebytes([self._SFRX_STROBE])
    print 'RX buffer flushed'
    
  def flush_TX(self,):
    """
    This function clears all the data from the TX FIFO.  Based on the 
    CC1120 development kit, it is good practice to flush the FIFO after 
    every packet.
    """
    self._SPI.writebytes([self._SFTX_STROBE])
    print 'TX buffer flushed'
    
  def txrx_status(self,nrep=1):
    """
    This function polls the transmitter for the status byte and picks out
    the appropriate bits.  By definition, the bits of interest for FIFO 
    errors are 1:3.
      Input:
        nrep -  The number of times to poll the status byte before 
                accepting the returned value.  Only the last value is used
                to determine the transmitter state.
    """
    
    # Read a list of status bytes from the transmitter
    sbyte = [self._SPI.readbytes(1)[0] for i in range(0,nrep)][-1]
    
    # return the three state bits from the status byte
    return bin(sbyte)[2:].zfill(8)[1:4]

    
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      