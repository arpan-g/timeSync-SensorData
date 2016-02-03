#!/usr/bin/env python

import sys, time
import tos

AM_TEST_FTSP_MSG = 137

class FtspMsg(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self,
                            [('src_addr',            'int', 2),
                             ('counter',             'int', 2),
                             ('local_rx_timestamp',  'int', 4),
                             ('global_rx_timestamp', 'int', 4),
                             ('skew_times_1000000',  'int', 4),
                             ('is_synced',           'int', 1),
                             ('ftsp_root_addr',      'int', 2),
                             ('ftsp_seq',            'int', 1),
                             ('ftsp_table_entries',  'int', 2),
			     ('light_sensor',        'int', 2),
			     ('temp_sensor',         'int', 2),
			     ('mic_sensor',          'int', 2)],
                            packet)

if '-h' in sys.argv:
    print "Usage:", sys.argv[0], "serial@/dev/ttyUSB1:57600"
    sys.exit()
f = open(str(time.time())+".report", 'w')
am = tos.AM()

while True:
    p = am.read()
    if p and p.type == AM_TEST_FTSP_MSG:
        msg = FtspMsg(p.data)
        print int(time.time()), msg.src_addr, msg.counter, msg.global_rx_timestamp, msg.light_sensor,msg.temp_sensor,msg.mic_sensor,msg.is_synced 
	data = str(time.time())+" "+str(msg.src_addr)+" "+str(msg.counter)+" "+str(msg.global_rx_timestamp)+" "+str(msg.is_synced)+"\n"
	f.write(data)
        #print msg
f.close()
