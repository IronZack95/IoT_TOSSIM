
#ifndef RADIO_TOSS_H
#define RADIO_TOSS_H

typedef nx_struct radio_toss0_msg {
  nx_uint8_t type;
  nx_uint16_t counter;
} request_msg;

typedef nx_struct radio_toss1_msg {
  nx_uint8_t type;
  nx_uint16_t counter;
  nx_uint16_t data;
} response_msg;

#define REQ 1
#define RESP 2 

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif
