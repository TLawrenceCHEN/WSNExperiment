#include <Timer.h>
#include <stdio.h>
#include <string.h>
#include "MultiHops.h"

module MultiHopsC {
	uses interface Boot;
	uses interface Timer<TMilli> as Timer0;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface AMSend as AMResend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
	uses interface Leds;
	uses interface Read<uint16_t> as ReadLight;
	uses interface Read<uint16_t> as ReadTemp;
	uses interface Read<uint16_t> as ReadHumidity;
} implementation {
	uint16_t counter = 0, temp = 0, humidity = 0, humidityLinear = 0, light = 0, version = 0;
	message_t pkt, retranspkt;
	bool busy = FALSE, retransbusy = FALSE;
	bool LightReadDone = FALSE, TempReadDone = FALSE, HumidityReadDone = FALSE;
	uint16_t destinationAddr = 0;
	uint16_t it = 0;
	
	event void Boot.booted() {
		if (TOS_NODE_ID != 1)
			destinationAddr = 1;
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
		} else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
	}

	event void Timer0.fired() {
		if (call ReadLight.read() == SUCCESS) {
			call Leds.led0Toggle();
		}
		if (call ReadTemp.read() == SUCCESS) {
			call Leds.led1Toggle();
		}
		if (call ReadHumidity.read() == SUCCESS) {
			call Leds.led2Toggle();
		}
		if (!busy) {
			MultiHopsMsg* mhpkt = (MultiHopsMsg*)(call Packet.getPayload(&pkt, sizeof(MultiHopsMsg)));
			if (mhpkt == NULL) {
				return;
			}
			mhpkt->token = 0xabcdeffe;
			mhpkt->nodeid = TOS_NODE_ID;
			mhpkt->seqnumber = counter;
			mhpkt->temperature = temp;
			mhpkt->humidity = humidity;
			mhpkt->light = light;
			mhpkt->curtime = call Timer0.getNow();
			mhpkt->interval = TIMER_PERIOD_MILLI;
			mhpkt->version = version;
			if (call AMSend.send(destinationAddr, &pkt, sizeof(MultiHopsMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}
	}

	event void ReadLight.readDone(error_t result, uint16_t val) {
		if (result == SUCCESS) {
			light = val;
		}	
	}

	event void ReadTemp.readDone(error_t result, uint16_t val) {
		if (result == SUCCESS) {
			temp = -40 + 0.01 * val;
		}
	}

	event void ReadHumidity.readDone(error_t result, uint16_t val) {
		if (result == SUCCESS) {
			humidityLinear = SHT11_C3 * val * val + SHT11_C2 * val + SHT11_C1;
			humidity = (temp - 25) * (SHT11_Temp1 + SHT11_Temp2 * val) + humidityLinear;
			if (humidity > 100) {
				humidity = 100;	
			} else if (humidity < 0.01) {
				humidity = 0.01;
			}
		}
	}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&pkt == msg) {
			busy = FALSE;
			counter++;
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (call AMPacket.source(msg) != 0 && call AMPacket.destination(msg) == TOS_NODE_ID && len == sizeof(MultiHopsMsg)) {
			MultiHopsMsg* mhpkt = (MultiHopsMsg*)payload;
			if (mhpkt->token == 0xabcdeffe) {
				printf("Received packet from node %u!\n", mhpkt->nodeid);
				printf("Sequence Number: %u\nTemperature: %u\nHumidity: %u\nLight: %u\nTime: %lu\n", mhpkt->seqnumber, mhpkt->temperature, mhpkt->humidity, mhpkt->light, mhpkt->curtime);
				if (!retransbusy) {
					MultiHopsMsg* retransmhpkt = (MultiHopsMsg*)(call Packet.getPayload(&retranspkt, sizeof(MultiHopsMsg)));
					if (retransmhpkt == NULL) {
						return;
					}
					retransmhpkt->token = mhpkt->token;
					retransmhpkt->nodeid = mhpkt->nodeid;
					retransmhpkt->seqnumber = mhpkt->seqnumber;
					retransmhpkt->temperature = mhpkt->temperature;
					retransmhpkt->humidity = mhpkt->humidity;
					retransmhpkt->light = mhpkt->light;
					retransmhpkt->curtime = mhpkt->curtime;
					retransmhpkt->interval = mhpkt->interval;
					retransmhpkt->version = mhpkt->version;
					if (call AMResend.send(destinationAddr, &retranspkt, sizeof(MultiHopsMsg)) == SUCCESS) {
						retransbusy = TRUE;
					}
				}
			}
		} else if(call AMPacket.source(msg) == 0 && len == sizeof(MultiHopsMsg)) {
			MultiHopsMsg* cfpkt = (MultiHopsMsg*)payload;
			if (cfpkt->token == 0xabcdeffe) {
				printf("New Frenquency: %lu\n", cfpkt->interval);
				call Timer0.stop();
				call Timer0.startPeriodic(cfpkt->interval);
				version++;
			}
		}/*
		if (call AMPacket.destination(msg) == 0 && len == sizeof(Value)) {
			Value* valpkt = (Value*)payload;
			ACK* ackpkt = call Packet.getPayload(&pkt, sizeof(ACK));
			call Leds.led2Toggle();
			ackpkt->group_id = valpkt->group_id;
			printf("group_id: %u\nmax: %lu\nmin: %lu\nsum: %lu\naverage: %lu\nmedian: %lu\n", valpkt->group_id, valpkt->max, valpkt->min, valpkt->sum, valpkt->average, valpkt->median);
			call AMSend.send((valpkt->group_id - 1)*3+1, &pkt, sizeof(ACK));
		}*/
		return msg;
	}
	
	event void AMResend.sendDone(message_t* msg, error_t err) {
		if (&retranspkt == msg) {
			retransbusy = FALSE;
		}
	}
}
