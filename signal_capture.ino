#define DIGITAL_INPUT_PIN 3
#define DIGITAL_OUTPUT_PIN 4
#define BAUD_RATE 57600
#define MAX_SEND_LENGTH 255

// Receiving
bool captureMode = false;
bool lastValue = LOW;
unsigned long last = -1;
unsigned int divisor = 0;

// Sending
bool sendDataMode = false;
unsigned char sendDataLength = 0;
unsigned char sendDataCount = 0;
unsigned char sendRepeats = 0;
unsigned char sendData[MAX_SEND_LENGTH];

void setup() {
  pinMode(DIGITAL_INPUT_PIN, INPUT);
  pinMode(DIGITAL_OUTPUT_PIN, OUTPUT);
  Serial.setTimeout(2000);
  Serial.begin(BAUD_RATE);
}

void loop() {
  if (captureMode) {
    bool value = digitalRead(DIGITAL_INPUT_PIN);
    if (value != lastValue) {
      lastValue = value;
      unsigned long ts = micros();
      unsigned long diff = 0;
      if (ts < last) {
        diff = 0; // Throw away this one bit every 70 hours.
      } else {
        diff = (ts - last);
      }
      diff = diff / divisor;
      if (diff > 255) {
        diff = 255;
      }
      Serial.write(diff);
      last = ts;
    }
  }
  while (Serial.available() > 0) {
    unsigned char rcv = Serial.read();
    if (sendDataMode) {
      if (sendDataLength == 0) {
        sendDataLength = rcv;
      } else if (sendRepeats == 0) {
        sendRepeats = rcv;
        byte received = Serial.readBytes((char *)sendData, sendDataLength);
        if (received != sendDataLength) {
          sendDataMode = false;
          Serial.write((byte)0xff);
          Serial.write((byte)0x00);
          Serial.write((byte)0x00);
          return;
        }
        bool state;
        for (int j = 0; j < sendRepeats; j++) {
          state = LOW;
          for (int i = 0; i < sendDataLength; i++) {
            digitalWrite(DIGITAL_OUTPUT_PIN, state);
            state = !state;
            delayMicroseconds(sendData[i] * divisor);
            // TODO: Factor in digitalWrite duration
          }
        }
        digitalWrite(DIGITAL_OUTPUT_PIN, LOW);
        sendDataMode = false;
        Serial.flush(); // Throw away any commands sent during the sending of the signal
        Serial.write((byte)0x00);
      }
    } else if (rcv == 'D') { // set divisor to next byte
      Serial.readBytes((char *)&divisor, 1);
    } else if (rcv == 'c') { // start capture
      Serial.write((byte)0x00);
      captureMode = true;
    } else if (rcv == 'C') { // stop capture
      Serial.write((byte)0x00);
      captureMode = false;
    } else if (rcv == 's') { // send some data
      sendDataMode = true;
      sendDataCount = 0;
      sendDataLength = 0;
      sendRepeats = 0;
    } else {
      Serial.println("Unknown data");
    }
  }
}
