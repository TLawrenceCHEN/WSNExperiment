#include <Timer.h>
#include "MultiHops.h"

configuration MultiHopsAppC {

} implementation {
	components MainC;
	components LedsC;
	components MultiHopsC as App;
	components new TimerMilliC() as Timer0;
	components ActiveMessageC as AM;
	components new AMSenderC(AM_MULTIHOPSTORADIO);
	components new AMSenderC(AM_MULTIHOPSTORADIO) as AMResenderC;
	components new AMReceiverC(AM_MULTIHOPSTORADIO);
	components new HamamatsuS1087ParC() as LightSensor;
	components new SensirionSht11C() as TempAndHumiditySensor;
	components SerialPrintfC;

	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Timer0 -> Timer0;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMControl -> AM;
	App.AMSend -> AMSenderC;
	App.AMResend -> AMResenderC;
	App.Receive -> AMReceiverC;App.ReadLight -> LightSensor;
	App.ReadTemp -> TempAndHumiditySensor.Temperature;
	App.ReadHumidity -> TempAndHumiditySensor.Humidity;
}
