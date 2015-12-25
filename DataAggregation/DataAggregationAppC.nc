#include <Timer.h>
#include "DataAggregation.h"

configuration DataAggregationAppC {

} implementation {
	components MainC;
	components LedsC;
	components DataAggregationC as App;
	components new AMSenderC(AM_DATAAGGREGATION);
	components new AMReceiverC(AM_DATAAGGREGATION);
	components SerialPrintfC;

	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC;
	App.Receive -> AMReceiverC;
}
