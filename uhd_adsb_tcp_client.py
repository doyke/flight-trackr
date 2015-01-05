#!/usr/bin/env python
##################################################
# Gnuradio Python Flow Graph
# Title: Uhd Adsb Tcp Client
# Generated: Thu Nov  6 17:58:45 2014
##################################################

from gnuradio import eng_notation
from gnuradio import gr
from gnuradio import uhd
from gnuradio.eng_option import eng_option
from gnuradio.filter import firdes
from grc_gnuradio import blks2 as grc_blks2
from optparse import OptionParser
import numpy
import time

class uhd_adsb_tcp_client(gr.top_block):

    def __init__(self, freq=1090e6, gain=25, ant="TX/RX", address="type=b100", samp_rate=2e6):
        gr.top_block.__init__(self, "Uhd Adsb Tcp Client")

        ##################################################
        # Parameters
        ##################################################
        self.freq = freq
        self.gain = gain
        self.ant = ant
        self.address = address
        self.samp_rate = samp_rate

        ##################################################
        # Blocks
        ##################################################
        self.uhd_usrp_source_0 = uhd.usrp_source(
        	",".join((address, "")),
        	uhd.stream_args(
        		cpu_format="sc16",
        		channels=range(1),
        	),
        )
        self.uhd_usrp_source_0.set_samp_rate(samp_rate)
        self.uhd_usrp_source_0.set_center_freq(freq, 0)
        self.uhd_usrp_source_0.set_gain(gain, 0)
        self.uhd_usrp_source_0.set_antenna(ant, 0)
        self.uhd_usrp_source_0.set_bandwidth(samp_rate, 0)
        self.blks2_tcp_sink_0 = grc_blks2.tcp_sink(
        	itemsize=gr.sizeof_short*2,
        	addr="127.0.0.1",
        	port=1234,
        	server=False,
        )

        ##################################################
        # Connections
        ##################################################
        self.connect((self.uhd_usrp_source_0, 0), (self.blks2_tcp_sink_0, 0))



    def get_freq(self):
        return self.freq

    def set_freq(self, freq):
        self.freq = freq
        self.uhd_usrp_source_0.set_center_freq(self.freq, 0)

    def get_gain(self):
        return self.gain

    def set_gain(self, gain):
        self.gain = gain
        self.uhd_usrp_source_0.set_gain(self.gain, 0)

    def get_ant(self):
        return self.ant

    def set_ant(self, ant):
        self.ant = ant
        self.uhd_usrp_source_0.set_antenna(self.ant, 0)

    def get_address(self):
        return self.address

    def set_address(self, address):
        self.address = address

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.uhd_usrp_source_0.set_samp_rate(self.samp_rate)
        self.uhd_usrp_source_0.set_bandwidth(self.samp_rate, 0)

if __name__ == '__main__':
    parser = OptionParser(option_class=eng_option, usage="%prog: [options]")
    parser.add_option("-f", "--freq", dest="freq", type="eng_float", default=eng_notation.num_to_str(1090e6),
        help="Set Default Frequency [default=%default]")
    parser.add_option("-g", "--gain", dest="gain", type="eng_float", default=eng_notation.num_to_str(25),
        help="Set Default Gain [default=%default]")
    parser.add_option("-A", "--ant", dest="ant", type="string", default="TX/RX",
        help="Set Antenna [default=%default]")
    parser.add_option("-a", "--address", dest="address", type="string", default="type=b100",
        help="Set IP Address [default=%default]")
    parser.add_option("-s", "--samp-rate", dest="samp_rate", type="eng_float", default=eng_notation.num_to_str(2e6),
        help="Set Sample Rate [default=%default]")
    (options, args) = parser.parse_args()
    tb = uhd_adsb_tcp_client(freq=options.freq, gain=options.gain, ant=options.ant, address=options.address, samp_rate=options.samp_rate)
    tb.start()
    raw_input('Press Enter to quit: ')
    tb.stop()
    tb.wait()
