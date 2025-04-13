# serial-port-handling
a brief explnation of USB port handling for serial communication while\ using microcontrollers. 
- [move directly to scripts](#scripts )
  
## usb devices identification 
when we connect a USB device to your PC, the OS creates a `virtual serial port` as an Interface for this connection which we usually use to communicate with `microcontrollers`(e.g. arudino compatible MCUs).\
on Ubuntu, you can see this ports using the command ``` ls /dev/tty* ``` and the output will look something like `ttyACM0` or `ttyUSB0`. 
### ttyACM or 
