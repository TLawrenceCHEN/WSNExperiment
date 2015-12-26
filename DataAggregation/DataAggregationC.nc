#include <Timer.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "DataAggregation.h"

module DataAggregationC {
	uses interface Boot;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface Leds;
	uses interface SplitControl;
} implementation {
	uint16_t nodeid;
	message_t dpkt, spkt;
	uint32_t sum = 0;
    uint16_t sequence_number;
    uint16_t master_nodeid = (GROUP_ID - 1) * 3 + 1;
    uint16_t lost_seq[200];
	message_t dpkt_queue[12];
    int qh = 0, qt = 0;
    uint16_t size = 0;
    uint32_t data[1000];
    bool listen_mode = FALSE;

	void queue_in(Data* dp) {
		if((qh + 1) % 12 == qt)
			return;
		memcpy(call Packet.getPayload(&dpkt_queue[qh], sizeof(Data)), dp, sizeof(Data));
		qh = (qh + 1) % 12;
		return;
	}
	
	task void senddp() {
		if(SUCCESS != call AMSend.send(master_nodeid, &dpkt_queue[qt], sizeof(Data)))
			post senddp();
		return;
	}

	event void Boot.booted() {
		nodeid = TOS_NODE_ID;
		memset(data, 0xffffffff, sizeof(uint32_t) * 1000);
		while (SUCCESS != call SplitControl.start());
	}

	event void SplitControl.startDone(error_t err) {
		if (err != SUCCESS) {
			call SplitControl.start();
		}
	}

	event void SplitControl.stopDone(error_t err) {}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		if(msg == &dpkt_queue[qt] && err == SUCCESS)
			qt = (qt + 1) % 12;
		if(qt != qh)
			post senddp();
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        /*if (!listen_mode && call AMPacket.source(msg) == 1000 && len == sizeof(Data)) {
			Data* datapkt = (Data*)payload;
			uint16_t seq_num = datapkt->sequence_number;
			uint32_t rand_int = datapkt->random_integer;
			if (seq_num % 2 == nodeid % 2) {
				if (seq_num < sequence_number) {
					listen_mode = TRUE;
					Sum* sumpkt = (Sum*)(call Packet.getPayload(&spkt, sizeof(Sum)));
					if (sumpkt == NULL) {
						return;
					}
					sumpkt->sum = sum;
					memcpy(sumpkt->lost_seq, lost_seq, sizeof(uint16_t) * 200);
					post sendSum(&spkt);
					return msg;	
				}
				if (seq_num != sequence_number + 2) {
					int i = sequence_number + 2;
					for (; i < seq_num; i += 2)
						lost_seq[size++] = i;
				}
				data[seq_num / 2 - (seq_num + 1) % 2] = rand_int;
				sum += rand_int;
			}
        } else if (listen_mode && call AMPacket.source(msg) == 1000 && len == sizeof(Data)) {
			Data* datapkt = (Data*)payload;
			uint16_t seq_num = datapkt->sequence_number;
			uint32_t rand_int = datapkt->random_integer;
			if (data[seq_num / 2 - (seq_num + 1) % 2] != 0xffffffff) {
				data[seq_num / 2 - (seq_num + 1) % 2] = rand_int;
				Data* mupkt = (Sum*)(call Packet.getPayload(&dpkt, sizeof(Data)));
				if (mupkt == NULL) {
					return;
				}
				mupkt->sequence_number = seq_num;
				mupkt->random_integer = rand_int;
				queue_in(&dpkt);
				post senddp();
				return msg;
			}
		} else if ()*/
		if (call AMPacket.source(msg) == 1000 && len == sizeof(Data)) {
			Data* datapkt = (Data*)payload;
			uint16_t seq_num = datapkt->sequence_number;
			uint32_t rand_int = datapkt->random_integer;
			call Leds.led0Toggle();
			if (seq_num % 2 == nodeid % 2) {
				if (data[seq_num / 2 - (seq_num + 1) % 2] != 0xffffffff)
					data[seq_num / 2 - (seq_num + 1) % 2] = rand_int;
			}
		}

		if (call AMPacket.source(msg) == master_nodeid && call AMPacket.destination(msg) == nodeid && len == sizeof(Query)) {
			Query* querypkt = (Query*)payload;
			uint16_t seq_num = querypkt->sequence_number;
			call Leds.led1Toggle();
			if (data[seq_num / 2 - (seq_num + 1) % 2] != 0xffffffff) {
				Data* lostpkt = (Data*)(call Packet.getPayload(&dpkt, sizeof(Data)));
				call Leds.led2Toggle();
				if (lostpkt == NULL) {
					return;
				}
				lostpkt->sequence_number = seq_num;
				lostpkt->random_integer = data[seq_num / 2 - (seq_num + 1) % 2];
				queue_in(&dpkt);
				post senddp();
				return msg;
			}
		}
		return msg;
	}	
}
