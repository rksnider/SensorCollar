"""
This is just a test script for the CC1120Class code.
"""

#import the library
from Adafruit_BBIO.SPI import SPI
import Adafruit_BBIO.GPIO as GPIO
from GPIOFacade import GPIOFac
from CC1120Class import CC1120

cc = CC1120()
cc.initalize()
for i in range(0,100):
  cc.transmit_data('0x0123456789abcdef')
  cc.flush_TX()
data_recieved = cc.recieve_data(20,10,timeout=2)
cc.flush_RX()
txrx_status = cc.txrx_status()

if txrx_status == '111':
  print 'A TX error has occurred.  Flushing the FIFO'
  cc.flush_TX()
if txrx_status == '110':
  print 'An RX error has occurred.  Flushing the FIFO'
  cc.flush_RX()
