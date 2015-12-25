#include "Timer.h"
#include "TestSerial.h"

module TestSerialC {
  uses {
    interface SplitControl as N_Control;
    interface SplitControl as S_Control;
    interface Leds;
    interface Boot;
    interface Receive as S_Receive;
    interface Receive as N_Receive;
    interface AMSend as S_AMSend;
    interface AMSend as N_AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface Packet as S_Packet;
    interface Packet as N_Packet;
    interface AMPacket;
  }
}
implementation {

  message_t n_packet;
  message_t s_packet;

  bool n_locked = FALSE, s_locked = FALSE;
  uint16_t counter = 0;
  
  event void Boot.booted() {
    call N_Control.start();
    call S_Control.start();
  }
  
  event void MilliTimer.fired() {
    counter++;
  }

  // receive msg from other node
  event message_t* N_Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    if (len != sizeof(MultiHopsMsg)) {return bufPtr;}
    else if(call AMPacket.destination(bufPtr) == TOS_NODE_ID){
      MultiHopsMsg* rcm = (MultiHopsMsg*)payload;
      if (rcm->token != 0xabcdeffe){return bufPtr;}
      else{
	      MultiHopsMsg* sdm = (MultiHopsMsg*)call S_Packet.getPayload(&s_packet, sizeof(MultiHopsMsg));
	      sdm->token = rcm->token;
	      sdm->seqnumber = rcm->seqnumber;
	      sdm->light = rcm->light;
	      sdm->temperature = rcm->temperature;
	      sdm->humidity = rcm->humidity;
	      sdm->nodeid = rcm->nodeid;
	      sdm->curtime = rcm->curtime;
	      sdm->interval = rcm->interval;
	      sdm->version = rcm ->version;
	      
	      // send msg to serial
	      if (call S_AMSend.send(AM_BROADCAST_ADDR, &s_packet, sizeof(MultiHopsMsg)) == SUCCESS) {
		s_locked = TRUE;
	      }
	      return bufPtr;
      }
    }
    return bufPtr;
  }

  // receive command from serial
  event message_t* S_Receive.receive(message_t* bufPtr, void* payload, uint8_t len){
    if (len != sizeof(MultiHopsMsg)) {return bufPtr;}
    else{
      MultiHopsMsg* rcm = (MultiHopsMsg*)payload;
      MultiHopsMsg* sdm = (MultiHopsMsg*)call N_Packet.getPayload(&n_packet, sizeof(MultiHopsMsg));

      sdm->token = 0xabcdeffe;
      sdm->nodeid = TOS_NODE_ID;
      sdm->interval = rcm->interval;
      
      // send command to other node
      if (call N_AMSend.send(AM_BROADCAST_ADDR, &n_packet, sizeof(MultiHopsMsg)) == SUCCESS) {
	n_locked = TRUE;
      }
      return bufPtr;
    }
  }

  event void S_AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&s_packet == bufPtr) {
      s_locked = FALSE;
    }
  }

  event void N_AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&n_packet == bufPtr) {
      n_locked = FALSE;
    }
  }

  event void N_Control.startDone(error_t err) {
    if (err == SUCCESS) {
      //call MilliTimer.startPeriodic(1000);
    }
  }
  event void N_Control.stopDone(error_t err) {}

  event void S_Control.startDone(error_t err) {
    if (err == SUCCESS) {
    }
  }
  event void S_Control.stopDone(error_t err) {}
}




