/**
 * Copyright 2012 John Moore, Scott Gilroy
 *
 * This file is part of CollaboRhythm.
 *
 * CollaboRhythm is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation, either version 2 of the License, or (at your option) any later
 * version.
 *
 * CollaboRhythm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with CollaboRhythm.  If not, see
 * <http://www.gnu.org/licenses/>.
 */
package collaboRhythm.android.deviceGateway;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Date;

import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;

import android.widget.TextView;
import android.widget.Toast;
import com.google.code.microlog4android.Logger;
import com.google.code.microlog4android.LoggerFactory;


// Annotation that provides the name of the Bluetooth device that this class handles.
@BluetoothSocketThreadAnnotation(bluetoothDeviceNames = {"ADHERETECH2"})
public class AdhereTechBluetoothSocketThread extends Thread implements IBluetoothSocketThread {

	private static final String CLASS = "AdhereTechBluetoothSocketThread";

	private static final byte FRAME_START = 0x51;
	public static final byte FRAME_STOP = (byte) 0xA3;
	public static final byte READ_SYSTEM_CLOCK_COMMAND = 0x23;
	public static final byte READ_STORAGE_DATA_PART_1_COMMAND = 0x25;
	public static final byte READ_STORAGE_DATA_PART_2_COMMAND = 0x26;
	public static final byte READ_STORAGE_NUMBER_OF_DATA_COMMAND = 0x2B;
	public static final byte FORCE_SLAVE_SLEEP_COMMAND = (byte) 0x50;

	private static final String ADHERETECH = "AdhereTech";
	public static final int COMMAND_PROCESSING_SLEEP_DURATION = 0;
	public static final int WAIT_FOR_RESPONSE_INCREMENTAL_SLEEP = 1;
	public static final int WAIT_FOR_RESPONSE_MAX_TOTAL_SLEEP_DURATION = 500;

	private boolean isOpened = false;
 	private boolean detectedOpen=false;
	byte[] readBuffer;
 	int readBufferPosition;
	volatile boolean stopWorker;
	private TextView bottleStatus;
	/**
	 * Number of bytes in a frame (commands and responses)
	 */
	public static final int FRAME_SIZE = 8;

	private BluetoothSocket mmBluetoothSocket;
	public InputStream mmInStream;
	public OutputStream mmOutStream;

	private int mSystolic;
	private int mDiastolic;

	private int mHeartrate;

	private int mBloodGlucose;

	private Handler mServiceMessageHandler;
	private final static Logger log = LoggerFactory.getLogger();

	/**
	 * The current device system time when the measurement was transmitted as reported by the device.
	 */
	private Date mDeviceTransmittedDate;
	/**
	 * Time that the measurement was recorded/measured as reported by the device.
	 */
	private Date mDeviceMeasuredDate;
	/**
	 * Local time when the measurement was transmitted.
	 */
	private Date mLocalTransmittedDate;
	/**
	 * Corrected (best guess) at the local time when the measurement was recorded/measured.
	 */
	private Date mCorrectedMeasuredDate;
	private long mDateOffsetToDevice;
	private int mDataAvailableCount = 0;
	private Context mApplicationContext;
	private boolean mDuplicateDetected = false;
	private int mDataIndex;

	public AdhereTechBluetoothSocketThread() {

	}

	public void init(BluetoothSocket bluetoothSocket, Handler serviceMessageHandler, Context applicationContext) {
		mServiceMessageHandler = serviceMessageHandler;
		mmBluetoothSocket = bluetoothSocket;
		mApplicationContext = applicationContext;

		InputStream tmpIn = null;
		OutputStream tmpOut = null;

		// Get the input and output streams, using temp objects because
		// member streams are final

		log.debug(CLASS + getId() + ": mmInStream and mmOutStream opening...");
		try {
			tmpIn = bluetoothSocket.getInputStream();
			tmpOut = bluetoothSocket.getOutputStream();
			log.debug(CLASS + getId() + ": mmInStream and mmOutStream opening - SUCCEEDED");
		} catch (IOException e) {
			log.debug(CLASS + getId() + ": mmInStream and mmOutStream opening - FAILED");
		}
		mmInStream = tmpIn;
		mmOutStream = tmpOut;

		mApplicationContext.registerReceiver(mMessageReceiver,
				new IntentFilter("CollaboRhythm-health-action-received-v1"));

	}

	private BroadcastReceiver mMessageReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			// Get extra data included in the Intent
			String message = intent.getStringExtra("message");
			String healthActionString = intent.getStringExtra("customData");
			log.debug(CLASS + getId() + "Got message: " + message + " " + healthActionString);

			if (message.equals("duplicate"))
			{
				mDuplicateDetected = true;
			}
		}
	};


	public Boolean isThreadReady() {
		return mmInStream != null && mmOutStream != null;
	}

	public void run() {
		//final Handler handler = new Handler();
		//final byte delimiter = 10; //This is the ASCII code for a newline character

		stopWorker = false;
		readBufferPosition = 0;
		readBuffer = new byte[1024];


			sendBeginToService();
			sendDataToService(DeviceGatewayConstants.BOTTLE_STATE);
			sendEndToService();
			sleep(10000);
		closeBluetoothSocket();

		//closeBluetoothSocket();

		/*while(!Thread.currentThread().isInterrupted() && !stopWorker)
  		{
       		try
       		{
           		int bytesAvailable = mmInStream.available();
           		if(bytesAvailable > 0)
           		{
               		byte[] packetBytes = new byte[bytesAvailable];
					mmInStream.read(packetBytes);
               		for(int i=0;i<bytesAvailable;i++)
               		{
                   		byte b = packetBytes[i];
                   		if(b == delimiter)
                   		{
                       		byte[] encodedBytes = new byte[readBufferPosition];
                       		System.arraycopy(readBuffer, 0, encodedBytes, 0, encodedBytes.length);
                       		final String data = new String(encodedBytes, "US-ASCII");
                       		readBufferPosition = 0;

                       		handler.post(new Runnable()
                       		{
                           		public void run()
                           		{

                           			if (data.equalsIgnoreCase("open"))
                           				isOpened = true;
                           			else
                           				isOpened = false;

                           			if (isOpened && !detectedOpen)
              						{
                           				detectedOpen=true;
										sendBeginToService();
										sendDataToService(DeviceGatewayConstants.BOTTLE_STATE);
										sendEndToService();
              						}
              						else if (!isOpened)
              						{
              							detectedOpen = false;
              						}

                           		}
                       		});
						}
                   		else
                   		{
                       		readBuffer[readBufferPosition++] = b;
                   		}
               		}
           		}
				closeBluetoothSocket();
       		}
       		catch (IOException ex)
       		{
           		stopWorker = true;
				closeBluetoothSocket();
       		}
  		}*/
	}

	private void determineDateOffset() {
		mDateOffsetToDevice = mLocalTransmittedDate.getTime() - mDeviceTransmittedDate.getTime();
		mCorrectedMeasuredDate = new Date(mDeviceMeasuredDate.getTime() + mDateOffsetToDevice);
	}

	private Date parseDateTime(byte[] responseBuffer, byte expectedCommand) {
		if (responseBuffer[1] != expectedCommand)
		{
			log.debug(CLASS + getId() + ": response command is " + responseBuffer[1] + " instead of expected " + expectedCommand + " for reading date 1");
			return null;
		}

		int year = 100 + ((responseBuffer[3] & 0xFF) >> 1); // 7 bits [0 to 6] ; 2000 represented as 0, 2012 as 12
		int month = ((responseBuffer[3] & 0x1) << 3) + ((responseBuffer[2] & 0xFF) >> 5) - 1; // 4 bits 3[7] + 2[0 to 2]
		int day = (responseBuffer[2] & (0xFF >> 3));
		int minute = responseBuffer[4] & (0xFF >> 2); // 6 bits
		int hour = responseBuffer[5] & (0xFF >> 3); // 5 bits

		Date dateTime = new Date(year, month, day, hour, minute);
		log.debug("Date: " + dateTime.toLocaleString());
		return dateTime;
	}

	private boolean readResponse(byte[] responseBuffer, String responseDescription, int expectedBytesAvailable) throws IOException {
		boolean dataRead;
		log.debug(CLASS + getId() + ": mmInStream reading " + responseDescription + "...");
		try {
			boolean responseReady = false;
			int totalSleep = 0;
			int bytesRead = 0;
			while (!responseReady) {
				int bytesAvailable = mmInStream.available();
				bytesRead += mmInStream.read(responseBuffer, bytesRead, Math.max(bytesAvailable, responseBuffer.length - bytesRead));
				if (bytesRead == responseBuffer.length) {
					responseReady = true;
				} else {
					if (totalSleep < WAIT_FOR_RESPONSE_MAX_TOTAL_SLEEP_DURATION) {
						sleep(WAIT_FOR_RESPONSE_INCREMENTAL_SLEEP);
						totalSleep += WAIT_FOR_RESPONSE_INCREMENTAL_SLEEP;
					} else {
						throw new IOException("Expected data not available from input stream for " + responseDescription + " after sleeping for " + totalSleep + " milliseconds");
					}
				}
			}
			log.debug(CLASS + getId() + ": mmInStream reading " + responseDescription + " - SUCCEEDED after sleeping for " + totalSleep + " milliseconds");
		} catch (IOException e) {
			log.debug(CLASS + getId() + ": mmInStream reading " + responseDescription + " - FAILED");
			throw e;
		}

		log.debug(CLASS + getId() + ": validating " + responseDescription + "...");
		if (isValidResponse(responseBuffer)) {
			log.debug(CLASS + getId() + ": validating " + responseDescription + " - SUCCEEDED");
			dataRead = true;
		} else {
			log.debug(CLASS + getId() + ": validating " + responseDescription + " - FAILED");
			throw new IOException("validating " + responseDescription + " failed");
		}
		return dataRead;
	}

	private void writeCommand(byte[] command, String commandDescription) throws IOException {
		log.debug(CLASS + getId() + ": mmOutStream writing " + commandDescription + "...");
		try {
			mmOutStream.write(command);
			log.debug(CLASS + getId() + ": mmOutStream writing " + commandDescription + " - SUCCEEDED");
		} catch (IOException e) {
			log.debug(CLASS + getId() + ": mmOutStream writing " + commandDescription + " - FAILED");
			throw e;
		}
	}

	private String determineMeasurementType(byte[] responseBuffer) {

		if (((responseBuffer[4] & 0xFF) >> 7) == 0) {
			return DeviceGatewayConstants.BLOOD_GLUCOSE;
		} else {
			return DeviceGatewayConstants.BLOOD_PRESSURE;
		}
	}

	private void parseBloodGlucose(byte[] responseBuffer) {
		mBloodGlucose = wordToUnsignedInt(responseBuffer[2], responseBuffer[3]);
	}

	private void parseBloodPressure(byte[] responseBuffer) {
		mSystolic = byteToUnsignedInt(responseBuffer[2]);
		mDiastolic = byteToUnsignedInt(responseBuffer[4]);
		mHeartrate = byteToUnsignedInt(responseBuffer[5]);
	}

	private void sleep(int milliseconds) {
		try {
			Thread.sleep(milliseconds);
		} catch (Exception e3) {
			log.debug(CLASS + getId() + ": failed to sleep.");
		}
	}

	private byte[] createCommand(byte commandByte, int index) {
		byte[] commandBuffer = new byte[FRAME_SIZE];
		commandBuffer[0] = FRAME_START;
		commandBuffer[1] = commandByte;
		commandBuffer[2] = (byte)(index & 0xFF);
		commandBuffer[3] = (byte)((index & 0xFF00) >> 8);
		commandBuffer[4] = 0x0;

		/*
		User=0x00 means current user(could be 1~4)
		User=0x01 means user 1
		User=0x02 means user 2
		User=0x03 means user 3
		User=0x04 means user 4
		 */
		commandBuffer[5] = 0x0;
		commandBuffer[6] = FRAME_STOP;
		commandBuffer[7] = calculateChecksum(commandBuffer);

		return commandBuffer;
	}

	private byte[] createForceSlaveDeviceSleepCommand() {
		byte[] commandBuffer = new byte[FRAME_SIZE];
		commandBuffer[0] = FRAME_START;
		commandBuffer[1] = FORCE_SLAVE_SLEEP_COMMAND;
		commandBuffer[2] = 0x0;
		commandBuffer[3] = 0x0;
		commandBuffer[4] = 0x0;
		commandBuffer[5] = 0x0;
		commandBuffer[6] = FRAME_STOP;
		commandBuffer[7] = calculateChecksum(commandBuffer);

		return commandBuffer;
	}

	private void sendDataToService(String measurementType) {
		Bundle data = createDataBundle(measurementType);
		data.putString(measurementType,"Open");
		Message message = Message.obtain();
		message.what = DeviceGatewayService.ServiceMessage.RETRIEVE_DATA_SUCCEEDED.ordinal();
		message.setData(data);
		mServiceMessageHandler.sendMessage(message);
	}

	private Bundle createDataBundle(String measurementType) {
		Bundle data = new Bundle();
		data.putString(DeviceGatewayConstants.HEALTH_ACTION_TYPE_KEY, DeviceGatewayConstants.EQUIPMENT_HEALTH_ACTION_TYPE);
		data.putString(DeviceGatewayConstants.EQUIPMENT_NAME_KEY, ADHERETECH);
		data.putString(DeviceGatewayConstants.HEALTH_ACTION_NAME_KEY, measurementType);
		return data;
	}

	private void sendBeginToService() {
		sendMessageToService(DeviceGatewayService.ServiceMessage.RETRIEVE_DATA_BEGIN, DeviceGatewayConstants.BOTTLE_STATE);
	}

	private void sendEndToService() {
		sendMessageToService(DeviceGatewayService.ServiceMessage.RETRIEVE_DATA_END, DeviceGatewayConstants.BOTTLE_STATE);
	}

	private void sendMessageToService(DeviceGatewayService.ServiceMessage serviceMessage, String measurementType) {
		Message message = Message.obtain();
		message.what = serviceMessage.ordinal();
		Bundle data = createDataBundle(measurementType);
		message.setData(data);
		mServiceMessageHandler.sendMessage(message);
	}

	private void retrieveBloodPressureFailed() {
		Message message = Message.obtain();
		message.what = DeviceGatewayService.ServiceMessage.RETRIEVE_DATA_FAILED.ordinal();
		mServiceMessageHandler.sendMessage(message);
	}

	private int byteToUnsignedInt(byte value) {
		return value & 0xFF;
	}

	private int wordToUnsignedInt(byte value0, byte value1) {
		return byteToUnsignedInt(value0) + (byteToUnsignedInt(value1) << 8);
	}

	private boolean isValidResponse(byte[] buffer) {
		return (buffer[0] == FRAME_START && calculateChecksum(buffer) == buffer[7]);
	}

	private byte calculateChecksum(byte[] buffer) {
		byte checkSum = 0;
		for (int i = 0; i < 7; i++) {
			checkSum += buffer[i];
		}
		return checkSum;
	}

	/* Call this from the main Activity to send data to the remote device */
	public void write(byte[] bytes) {
		try {
			mmOutStream.write(bytes);
		} catch (IOException e) {
		}
	}

	private void closeBluetoothSocket() {
		log.debug(CLASS + getId() + ": mmBluetoothSocket closing...");
		try {
			mmBluetoothSocket.close();
			log.debug(CLASS + getId() + ": mmBluetoothSocket closing - SUCEEDED");
		} catch (IOException e) {
			log.debug(CLASS + getId() + ": mmBluetoothSocket closing - FAILED");
		}

		// Unregister since the activity is about to be closed.
		mApplicationContext.unregisterReceiver(mMessageReceiver);
	}

	/* Call this from the main Activity to shutdown the connection */
	public void cancel() {
		closeBluetoothSocket();
	}

}