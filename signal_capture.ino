#define DIGITAL_MODE 1
#define ANALOG_INPUT_PIN A0
#define DIGITAL_INPUT_PIN 2
#define UPDATE_INTERVAL_MICROS 50
#define MODE_2_CONSECUTIVE_READS 2000

unsigned long next_update;
unsigned long reads;
int mode;
int bit;
byte value;

void setup() {
  Serial.begin(250000);
  if (DIGITAL_MODE) {
    pinMode(DIGITAL_INPUT_PIN, INPUT);
  } else {
    analogReference(EXTERNAL);
  }
  mode = 0;
}

inline void mode1() {
  int value = 0;
  if (DIGITAL_MODE) {
    value = digitalRead(DIGITAL_INPUT_PIN);
  } else {
    value = analogRead(ANALOG_INPUT_PIN);
  }
  Serial.println(value);
  delay(100);
}

inline void mode2() {
  unsigned long current_micros = micros();
  if(current_micros < next_update) {
    return;
  }
  next_update = next_update + UPDATE_INTERVAL_MICROS;

  if (DIGITAL_MODE) {
    value |= (digitalRead(DIGITAL_INPUT_PIN) ? 1 : 0) << bit;
    bit ++;
    if (bit == 7) {
      Serial.print(value);
      bit = 0;
      value = 0;
      reads--;
      if(reads == 0) {
        mode = 0;
        Serial.write(0xFF);
      }
    }
  } else {
    /*
    value = analogRead(ANALOG_INPUT_PIN);
    b1 = value&0xFF;
    b2 = ( value >> 8 ) & 0xFF;
    Serial.write(b1);
    Serial.write(b2);
    */
  }
}

void loop() {
  switch(mode) {
    case 1:
      mode1();
      break;
    case 2:
      mode2();
      break;
    default:
      delay(200);
      if(Serial.available() > 0) {
        int rcv;
        rcv = Serial.read();
        if(rcv == '1') {
          mode = 1;
        } else if(rcv == '2') {
          mode = 2;
          reads = MODE_2_CONSECUTIVE_READS;
          next_update = micros();
          bit = 0;
          value = 0;
        } else if(rcv == '0') {
          if(mode == 2) {
            Serial.write(0xFF);
            Serial.write(0xFF);
          }
          mode = 0;
        }
      }
      break;
  }

}
/* vim: set syntax=c ts=2 sw=2 ai: */
