import Adafruit_BBIO.GPIO as GPIO

class GPIOFac(object):

  def __init__(self,pin,mode):
    self._pin = pin
    self._mode = mode
    if mode.strip().lower() == 'in':
      GPIO.setup(pin,GPIO.IN)
    else:
      GPIO.setup(pin,GPIO.OUT)
    
  def read(self):
    if self._mode.strip().lower() == 'in':
      return GPIO.input(self._pin)
    else:
      raise ValueError('Read operations require an input pin')
        
  def write(self,value):
    if self._mode.strip().lower() == 'out':
      if value:
        GPIO.output(self._pin,GPIO.HIGH)
      else: 
        GPIO.output(self._pin,GPIO.LOW)
    else:
      raise ValueError('Write operations require an output pin')
      