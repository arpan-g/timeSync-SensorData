# timeSync-SensorData
This project uses FTSP to acquire time synchronized sensor data
Collecting time synchronized sensor data from micaz motes using mts310cb with tinyos
To implement time synchronization we use the FTSP protocol provided by  Miklos Maroti et al. There implementation can be found at http://tinyos.stanford.edu/tinyos-wiki/index.php/FTSP.
To implement Sensor data acquisition we use the SensorMts300C configuration. If you are collecting data from more than one sensor it is advised to use SensorMts300C, especially if you are collecting Temperature and Light sensor data. If you are using mts310cb board as I am and you are using tiny-os version 2.1.1 or lower  in ../tinyos-2.1.0/tos/sensorboards/mts300/PhotoTempDeviceC.nc
change 
TempControl.Power -> MicaBusC.Int2;
to
TempControl.Power -> MicaBusC.PW0;
This bug is fixed in tiny-os 2.1.2 in the makefile the sensor board has to be specified using the PFLAGS as shown below 

SENSORBOARD = mts300
PFLAGS += -DMTS310CB

Program one of the motes with apps/RadioCountToLeds
Program the motes which you want to use to capture sensor data with TestFtsp.
Program a mote with apps/BaseStation and keep it connected to the ground.
Run the FtspDataLogger.py application. To check on which serial port your mote is connected run dmesg | grep tty it will show the ports to which your micaz sensor is connected to. It generally shows 2. On one port you can write and other you can read. Generally the lower port number is to write and higher port number will be a read port.
To run the python program issue the command python FtspDataLogger.py serial@/dev/ttyUSB1:57600, if you are connected on ttyUSB1. The code is available at