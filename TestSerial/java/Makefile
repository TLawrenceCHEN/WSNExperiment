GEN=OscilloscopeMsg.java Constants.java

all: oscilloscope.jar

oscilloscope.jar: Oscilloscope.class
	jar cf $@ *.class

OscilloscopeMsg.java: ../TestSerial.h
	mig -target=null -java-classname=OscilloscopeMsg java ../TestSerial.h test_serial_msg -o $@

Constants.java: ../TestSerial.h
	ncg -target=null -java-classname=Constants java ../TestSerial.h NREADINGS DEFAULT_INTERVAL -o $@

Oscilloscope.class: $(wildcard *.java) $(GEN)
	javac *.java

clean:
	rm -f *.class $(GEN)

veryclean: clean
	rm oscilloscope.jar
