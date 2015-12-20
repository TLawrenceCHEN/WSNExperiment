/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

import net.tinyos.message.*;
import net.tinyos.util.*;
import java.io.*;
import java.io.File;
import java.io.FileOutputStream;

/* The "Oscilloscope" demo app. Displays graphs showing data received from
   the Oscilloscope mote application, and allows the user to:
   - zoom in or out on the X axis
   - set the scale on the Y axis
   - change the sampling period
   - change the color of each mote's graph
   - clear all data

   This application is in three parts:
   - the Node and Data objects store data received from the motes and support
     simple queries
   - the Window and Graph and miscellaneous support objects implement the
     GUI and graph drawing
   - the Oscilloscope object talks to the motes and coordinates the other
     objects

   Synchronization is handled through the Oscilloscope object. Any operation
   that reads or writes the mote data must be synchronized on Oscilloscope.
   Note that the messageReceived method below is synchronized, so no further
   synchronization is needed when updating state based on received messages.
*/
public class Oscilloscope implements MessageListener
{
    MoteIF mote;
    int datasize = 3;
    Data[] data = new Data[datasize];
    boolean [] flag = new boolean[256];
    protected static FileWriter fw = null;
    Window window;

    boolean[] firstpkg = new boolean[256];
    int [] firstseq = new int[256];
    int [] lastseq = new int[256];
    int [] lostnumber = new int[256];
    float [] lossratio = new float[256];

    /* The current sampling period. If we receive a message from a mote
       with a newer version, we update our interval. If we receive a message
       with an older version, we broadcast a message with the current interval
       and version. If the user changes the interval, we increment the
       version and broadcast the new interval and version. */
    int interval = Constants.DEFAULT_INTERVAL;
    int version = 0;

    /* Main entry point */
    void run() {
	    try{
    		fw = new FileWriter("../result.txt");
    	}catch (IOException exception) {
		    System.err.println("Exception thrown when opening file. Exiting.");
		    System.err.println(exception);
		}
		for (int i = 0; i < datasize; i++){
			data[i] = new Data(this);
		}
		for (int i = 0; i < 256; i++){
			flag[i] = false;
			firstpkg[i] = false;
			lastseq[i] = -1;
			firstseq[i] = 0;
			lostnumber[i] = 0;
			lossratio[i] = 0;
		}
		window = new Window(this);
		window.setup();
		mote = new MoteIF(PrintStreamMessenger.err);
	    mote.registerListener(new OscilloscopeMsg(), this);
    }

    /* The data object has informed us that nodeId is a previously unknown
       mote. Update the GUI. */
    void newNode(int nodeId) {
    	window.newNode(nodeId);
    }

    public synchronized void messageReceived(int dest_addr, 
            Message msg) {
		if (msg instanceof OscilloscopeMsg) {
		    OscilloscopeMsg omsg = (OscilloscopeMsg)msg;

			int nodeid = omsg.get_nodeid();
			int seqnumber = omsg.get_seqnumber();
		    /* Update interval and mote data */
		    periodUpdate(omsg.get_version(), omsg.get_interval());
		    data[0].update(nodeid, seqnumber, omsg.get_temperature());//, omsg.get_temperature(), omsg.get_humidity(), omsg.get_light());
			data[1].update(nodeid, seqnumber, omsg.get_humidity());//, omsg.get_temperature(), omsg.get_humidity(), omsg.get_light());
			data[2].update(nodeid, seqnumber, omsg.get_light());//, omsg.get_temperature(), omsg.get_humidity(), omsg.get_light());
			
		    /* Inform the GUI that new data showed up */
		    window.newData();

		    /*write data to file*/
		    try{
			  fw.write(nodeid + " " + seqnumber + " " + omsg.get_temperature() + " " + omsg.get_humidity() + " " + omsg.get_light() + " " + omsg.get_curtime() + "\n");
			}catch (IOException exception) {
			  System.err.println("Exception thrown when writing file. Exiting.");
			  System.err.println(exception);
			}

			if(firstpkg[nodeid] == false){
				firstpkg[nodeid] = true;
				firstseq[nodeid] = seqnumber;
			}else{
				if (lastseq[nodeid] != seqnumber - 1){
					System.out.println("lost pkg @ node: " + nodeid + " between " + lastseq[nodeid] + " and " + seqnumber);
					lostnumber[nodeid] += seqnumber - lastseq[nodeid] - 1;
					lossratio[nodeid] = (float)lostnumber[nodeid]/(seqnumber - firstseq[nodeid] + 1);
					System.out.println("loss pkg ratio: " + lossratio[nodeid]);
				}
			}
			lastseq[nodeid] = seqnumber;
		}
    }

    /* A potentially new version and interval has been received from the
       mote */
    void periodUpdate(int moteVersion, int moteInterval) {
		if (moteVersion > version) {
		    /* It's new. Update our vision of the interval. */
		    version = moteVersion;
		    interval = moteInterval;
		    window.updateSamplePeriod();
		}
		else if (moteVersion < version) {
		    /* It's old. Update the mote's vision of the interval. */
		    sendInterval();
		}
    }

    /* The user wants to set the interval to newPeriod. Refuse bogus values
       and return false, or accept the change, broadcast it, and return
       true */
    synchronized boolean setInterval(int newPeriod) {
		if (newPeriod < 1 || newPeriod > 65535) {
		    return false;
		}
		interval = newPeriod;
		version++;
		sendInterval();
		return true;
    }

    /* Broadcast a version+interval message. */
    void sendInterval() {
		OscilloscopeMsg omsg = new OscilloscopeMsg();

		omsg.set_version(version);
		omsg.set_interval(interval);
		try {
		    mote.send(MoteIF.TOS_BCAST_ADDR, omsg);
		}
		catch (IOException e) {
		    window.error("Cannot send message to mote");
		}
    }

    /* User wants to clear all data. */
    void clear() {
		for (int i = 0; i < datasize; i++){
			data[i] = new Data(this);
		}
    }

    public static void main(String[] args) {
	    Oscilloscope me = new Oscilloscope();
	    me.run();
    }
}
