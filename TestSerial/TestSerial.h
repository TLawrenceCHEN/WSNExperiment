
#ifndef TEST_SERIAL_H
#define TEST_SERIAL_H

typedef nx_struct test_serial_msg {
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

enum {
  AM_TEST_SERIAL_MSG = 0x93,
  AM_MULTIHOPSTORADIO = 6,
  
  NREADINGS = 1,
  /* Default sampling period. */
  DEFAULT_INTERVAL = 100,
};

#endif
