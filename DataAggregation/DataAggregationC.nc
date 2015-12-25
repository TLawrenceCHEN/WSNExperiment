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
	uint32_t min = 0xffffffff, max = 0, sum = 0, average = 0, median = 0;
    uint16_t sequence_number;
	uint32_t random_integer[2000] = {0};
	bool lostPkt = FALSE;
	
	event void Boot.booted() {
		nodeid = TOS_NODE_ID;
	}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&pkt == msg) {
			busy = FALSE;
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        if (call AMPacket.source(msg) == 1000 && len == sizeof(Data)) {
			Data* datapkt = (Data*)payload;
			uint16_t seq_num = datapkt->sequence_number;
			uint32_t rand_int = datapkt->random_integer;
			if (seq_num != sequence_number + 1) {
				lostPkt = TRUE;
				if (!busy) {
					SingleData* query = (SingleData*)call Packet.getPayload(&pkt, sizeof(SingleData));
					
				}
			}
        }
		return msg;
	}	
}
