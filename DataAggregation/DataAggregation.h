#ifndef DATAAGGREGATION_H
#define DATAAGGREGATION_H

enum {
	AM_DATAAGGREGATION = 6,
	TIMER_PERIOD_MILLI = 250,
	GROUP_ID = 6
};

struct Data {
	nx_uint16_t sequence_number;
	nx_uint32_t random_integer;
} Data;

struct Value {
	nx_uint8_t group_id;
	nx_uint32_t max;
	nx_uint32_t min;
	nx_uint32_t sum;
	nx_uint32_t average;
	nx_uint32_t median;
} Value;

struct SingleData {
	nx_uint8_t datatype;
	nx_uint32_t value;
} SingleData;

struct ACK {
	uint8_t group_id;
} ACK;

#endif
