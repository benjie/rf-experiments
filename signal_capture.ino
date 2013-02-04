#define DIGITAL_INPUT_PIN 2
#define DIGITAL_OUTPUT_PIN 4
#define BAUD_RATE 57600
#define MIN_DIFF 20

#define RING_BUFFER_SIZE 100
#define MAX_SEND_LENGTH 256
#define DIVISOR 40

volatile unsigned char ring_buffer[RING_BUFFER_SIZE];
volatile unsigned int pos = 0;
volatile unsigned int writepos = 0;
volatile unsigned long last = 0;
bool started = false;
bool isSetUp = false;
volatile unsigned long remaining = 0;
unsigned char sendDataLength = 0;
unsigned char sendDataCount = 0;
unsigned char sendRepeats = 0;
unsigned char sendData[MAX_SEND_LENGTH];
bool sendDataMode = false;
bool attached = false;

void setup() {
  //Serial.begin(76800);
  pinMode(DIGITAL_INPUT_PIN, INPUT);
  pinMode(DIGITAL_OUTPUT_PIN, OUTPUT);
  pinMode(13, OUTPUT);
  Serial.begin(BAUD_RATE);
}

void loop() {
  if (!isSetUp) {
    isSetUp = true;
    last = micros();
    for (unsigned int i = 0; i < RING_BUFFER_SIZE; i++) {
      ring_buffer[i] = 0;
    }
    for (unsigned int i = 0; i < MAX_SEND_LENGTH; i++) {
      sendData[i] = 0;
    }
    return;
  }
  while (Serial.available() > 0) {
    unsigned char rcv = Serial.read();
    if (sendDataMode) {
      if (sendDataLength == 0) {
        sendDataLength = rcv;
      } else if (sendRepeats == 0) {
        sendRepeats = rcv;
        unsigned char bytes = Serial.readBytes((char *)sendData, sendDataLength);
        if (bytes != sendDataLength) {
          sendDataMode = false;
          Serial.println("Insufficient data?");
          return;
        }
        //Send the data!
        if (attached) detachInterrupt(0);
        bool state = LOW;
        Serial.println("Sending");
        Serial.println(sendRepeats);
        Serial.println(sendDataLength);
        for (int j = 0; j < sendRepeats; j++) {
          state = LOW;
          for (int i = 0; i < sendDataLength; i++) {
            digitalWrite(DIGITAL_OUTPUT_PIN, state);
            //digitalWrite(13, state);
            state = !state;
            delayMicroseconds(sendData[i] * DIVISOR);
          }
        }
        Serial.println("Sent");
        digitalWrite(DIGITAL_OUTPUT_PIN, LOW);
        digitalWrite(13, HIGH);
        delay(100);
        digitalWrite(13, LOW);
        if (attached) attachInterrupt(0, pinChange, CHANGE);
        sendDataMode = false;
      }
    } else if (rcv == 'd') {
      Serial.write(DIVISOR);
    } else if (rcv == 'c') {
      started = true;
      attachInterrupt(0, pinChange, CHANGE);
      attached = true;
      Serial.write(0xFF);
    } else if (rcv == 's') {
      // Send some data!
      sendDataMode = true;
      sendDataCount = 0;
      sendDataLength = 0;
      sendRepeats = 0;
    } else {
      Serial.write("Unknown data");
      digitalWrite(13, HIGH);
      delay(100);
      digitalWrite(13, LOW);
      delay(100);
    }
  }
  if (writepos != pos) {
    writepos++;
    if (writepos >= RING_BUFFER_SIZE) {
      writepos = 0;
    }
    unsigned char v = ring_buffer[writepos];
    Serial.write(v);
  }
}

void pinChange() {
  unsigned long ts = micros();
  unsigned long diff = 0;
  if (ts < last) {
    diff = 0; // Throw away this one bit every 70 hours.
    // TODO: Deal with it better :P
  } else if (ts < last + MIN_DIFF) {
    // Insufficient difference
    diff = 0;
  } else {
    diff = (ts - last);
  }
  diff = diff / DIVISOR;
  if (diff > 255) {
    diff = 255;
  }
  if (ring_buffer[pos] != 0 || diff > 0) {
    pos++;
    if (pos >= RING_BUFFER_SIZE) {
      pos = 0;
    }
    //if (pos == writepos) {
      //Serial.println("Overflow");
    //}
    ring_buffer[pos] = diff;
  }
  last = ts;
}
/* vim: set syntax=c ts=2 sw=2 ai: */
