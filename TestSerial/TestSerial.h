
#ifndef TEST_SERIAL_H
#define TEST_SERIAL_H

typedef nx_struct test_serial_msg {
  nx_uint16_t nodeid;
  nx_uint16_t counter;
  nx_uint16_t light;
  nx_uint16_t temperature;
  nx_uint16_t humidity;
} MultiHopsMsg;

enum {
  AM_TEST_SERIAL_MSG = 0x89,
  AM_MULTIHOPSTORADIO = 6,
};

#endif
