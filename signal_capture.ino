#define DIGITAL_INPUT_PIN 2
#define MIN_DIFF 20

#define RING_BUFFER_SIZE 256

volatile unsigned int ring_buffer[RING_BUFFER_SIZE];
volatile unsigned int pos = 0;
volatile unsigned int writepos = 0;
volatile unsigned long last = 0;
bool started = false;
volatile unsigned long remaining = 0;

void setup() {
  for (unsigned int i = 0; i < RING_BUFFER_SIZE; i++) {
    ring_buffer[i] = 0;
  }
  //memset(ring_buffer, 0, sizeof(ring_buffer));
  //Serial.begin(76800);
  Serial.begin(57600);
  pinMode(DIGITAL_INPUT_PIN, INPUT);
  last = micros();
}

void loop() {
  if (!started && Serial.available() > 0) {
    char rcv = Serial.read();
    if(rcv == '2') {
      started = true;
      remaining = 5000;
      attachInterrupt(0, pinChange, CHANGE);
      Serial.write(0xFF);
      Serial.write(0xFF);
    }
  }
  if (writepos != pos) {
    writepos++;
    if (writepos >= RING_BUFFER_SIZE) {
      writepos = 0;
    }
    unsigned int v = ring_buffer[writepos];
    byte b1 = (v >> 8) & 0xFF;
    byte b2 = (v) & 0xFF;
    Serial.write(b1);
    Serial.write(b2);
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
  if (ring_buffer[pos] != 0 || diff > 0) {
    pos++;
    if (pos >= RING_BUFFER_SIZE) {
      pos = 0;
    }
    //if (pos == writepos) {
      //Serial.println("Overflow");
    //}
    ring_buffer[pos] = diff;
    remaining--;
    if (remaining == 0) {
      started = false;
      detachInterrupt(0);
      byte b1 = 0xFF, b2 = 0xFF;
      Serial.write(b1);
      Serial.write(b2);
    }
  }
  last = ts;
}
/* vim: set syntax=c ts=2 sw=2 ai: */
