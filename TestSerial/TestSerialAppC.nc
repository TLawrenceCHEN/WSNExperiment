#include "TestSerial.h"

configuration TestSerialAppC {}
implementation {
  components TestSerialC as App, LedsC, MainC;
  components SerialActiveMessageC as S_AM;
  components ActiveMessageC as AM;
  components new AMReceiverC(AM_MULTIHOPSTORADIO);
  components new AMSenderC(AM_MULTIHOPSTORADIO);
  components new TimerMilliC();

  App.Boot -> MainC;
  App.N_Control -> AM;
  App.S_Control -> S_AM;
  App.N_Receive -> AMReceiverC;
  App.N_AMSend -> AMSenderC;
  App.S_AMSend -> S_AM.AMSend[AM_TEST_SERIAL_MSG];
  App.S_Receive -> S_AM.Receive[AM_TEST_SERIAL_MSG];
  App.Leds -> LedsC;
  App.MilliTimer -> TimerMilliC;
  App.S_Packet -> S_AM;
  App.N_Packet -> AM;
  App.AMPacket -> AMSenderC;
}


