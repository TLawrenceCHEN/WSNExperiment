#ifndef MULTIHOPS_H
#define MULTIHOPS_H

static const float SHT11_C1 = -4.0;
static const float SHT11_C2 = +0.0405;
static const float SHT11_C3 = -0.0000028;
static const float SHT11_Temp1 = +0.01;
static const float SHT11_Temp2 = +0.00008;

enum {
	AM_MULTIHOPSTORADIO = 6,
	TIMER_PERIOD_MILLI = 100
};

typedef nx_struct MultiHopsMsg {
	nx_uint32_t token;
	nx_uint16_t nodeid;
	nx_uint16_t seqnumber;
	nx_uint16_t temperature;
	nx_uint16_t humidity;
	nx_uint16_t light;
	nx_uint32_t curtime;
	nx_uint16_t interval;
	nx_uint16_t version;
} MultiHopsMsg;
/*
typedef nx_struct Value {
	nx_uint8_t group_id;
	nx_uint32_t max;
	nx_uint32_t min;
	nx_uint32_t sum;
	nx_uint32_t average;
	nx_uint32_t median;
} Value;

typedef nx_struct ACK {
	nx_uint8_t group_id;
} ACK;*/

#endif
