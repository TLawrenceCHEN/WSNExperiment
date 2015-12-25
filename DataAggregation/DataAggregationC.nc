#include <Timer.h>
#include <stdio.h>
#include <string.h>
#include "DataAggregation.h"

module DataAggregationC {
	uses interface Boot;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface Leds;
} implementation {
	bool busy = FALSE;
	uint16_t nodeid;
	message_t pkt;

	event void Boot.booted() {
		nodeid = TOS_NODE_ID;
	}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&pkt == msg) {
			busy = FALSE;
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		
		return msg;
	}	
}
