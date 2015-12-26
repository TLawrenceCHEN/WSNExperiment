#include <Timer.h>
#include <stdio.h>
#include <string.h>
#include "DAmaster.h"

module DAmasterC {
	uses interface Boot;
	uses interface Timer<TMilli> as Timer;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface Leds;
	uses interface SplitControl;
} implementation {
	bool busy = FALSE;
	uint16_t nodeid;
	message_t pkt;
	
    uint16_t pre_seq_number = 0; // last pkg seq number
    uint16_t count = 0; //pkg number received now
	uint32_t random_integer[2000] = {0};
	bool lostPkt = FALSE;

	message_t query[12];
	int qh = 0, qt = 0;

	Value result; // store the final result;
	
	//0: listen for data, 1: calculating result
	int state = 0;

	
	void calculate(){
		//insert sort
		uint32_t sum = random_integer[0];
		int i,j,k;
		for (i = 1; i < 2000; i++){
			uint32_t temp = random_integer[i];
			sum += random_integer[i];
			if (temp < random_integer[0]){
				for (k = i; k > 0; k--){
					random_integer[k] = random_integer[k-1];
				}
				random_integer[0] = temp;
				continue;
			}
			for (j = i-1; j>=0; j--){
				if (temp > random_integer[j]){
					for (k = i; k > j+1; k--){
						random_integer[k] = random_integer[k-1]; 
					}
					random_integer[j+1] = temp;
					break;
				}
			}
		}
		result.group_id = GROUP_ID;
		result.max = random_integer[1999];
		result.min = random_integer[0];
		result.median = (random_integer[1000]+random_integer[999])/2;
		result.sum = sum;
		result.average = sum/2000;

		printf("max: %lu\nmin: %lu\nmedian: %lu\nsum: %lu\naverage: %lu\n", result.max, result.min, result.median, result.sum, result.average);
		
		memcpy(call Packet.getPayload(&pkt, sizeof(Value)), &result, sizeof(Value));
		call AMSend.send(0, &pkt, sizeof(Value)); // send result
	}

	task void sendQuery()
	{
		Query* dp = (Query*)call Packet.getPayload(&query[qt], sizeof(Query));
		if(SUCCESS != call AMSend.send(18 - (dp->sequence_number)%2, &query[qt], sizeof(Query)))
			post sendQuery();
		else {
			call Leds.led1Toggle();
			printf("seq: %u\n", dp->sequence_number);
		}
	}

	void query_in(Query* dp)
	{
		if((qh+1)%12 == qt)
			return;
		memcpy(call Packet.getPayload(&query[qh], sizeof(Query)), dp, sizeof(Query));
		qh = (qh+1)%12;
	}
	

	event void Boot.booted() {
		int i;
		nodeid = TOS_NODE_ID;
		for (i = 0; i < 2000; i++){
			random_integer[i] = 0xffffffff;
		}
		while (SUCCESS != call SplitControl.start());
	}

	event void SplitControl.startDone(error_t err) {
		if (err != SUCCESS) {
			call SplitControl.start();
		}
	}

	event void SplitControl.stopDone(error_t err) {}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		if(msg == &query[qt] && err == SUCCESS)
			qt = (qt+1)%12;
		if(qt != qh)
			post sendQuery();
		if(state == 1) {
			call Timer.stop();
			call Timer.startPeriodic(5000);
		}
	}

	event void Timer.fired() {
		if (state == 1){
			memcpy(call Packet.getPayload(&pkt, sizeof(Value)), &result, sizeof(Value));
			call AMSend.send(0, &pkt, sizeof(Value)); // send result
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (call AMPacket.source(msg) == 1000 && len == sizeof(Data)) { // pkg from node 1000
        	Data* datapkt = (Data*)payload;
			uint16_t seq_num = datapkt->sequence_number;
			uint32_t rand_int = datapkt->random_integer;
			call Leds.led0Toggle();
			if (random_integer[seq_num-1] != 0xffffffff){return msg;} //already get this number
			
			random_integer[seq_num-1] = rand_int;
			count++;

			if (count == 2000 && state == 0){
				state = 1;
				calculate();
			}
			
			if (seq_num != pre_seq_number + 1) {
				int i;
				lostPkt = TRUE;
				for (i = pre_seq_number+1; i < seq_num; i++){
					if (random_integer[i - 1] != 0xffffffff){
						continue;
					}else{
						Query dp;
						dp.sequence_number = i;
						query_in(&dp);
						post sendQuery();
					}
				}
			}
			pre_seq_number = seq_num;
        }else if (call AMPacket.source(msg) == 17 || call AMPacket.source(msg) == 18){ // pkg from neighbors
        	if (len == sizeof(Data)){ // query result
        		Data* datapkt = (Data*)payload;
				uint16_t seq_num = datapkt->sequence_number;
				uint32_t rand_int = datapkt->random_integer;
				call Leds.led2Toggle();
				if (random_integer[seq_num-1] != 0xffffffff){return msg;} //already get this number
				
				random_integer[seq_num-1] = rand_int;
				count++;

				if (count == 2000 && state == 0){
					state = 1;
					calculate();
				}
			}
        }else if (call AMPacket.source(msg) == 0 && len == sizeof(ACK)){ // ACK from node 0
			ACK* ack = (ACK*)(call Packet.getPayload(&pkt, sizeof(ACK)));
			uint8_t group_id = ack->group_id;
			if (group_id == GROUP_ID)
        		state = 2;
        }
		return msg;
	}	
}
