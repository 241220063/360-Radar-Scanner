#include <Servo.h>

// ------------ Sensor 1 ------------
const int trig1 = 10;
const int echo1 = 11;

// ------------ Sensor 2 ------------
const int trig2 = 9;
const int echo2 = 12;

Servo myServo;

long duration1, duration2;
int dist1, dist2;
int finalDist;

// -----------------------------------------------------
void setup() {
  Serial.begin(9600);

  pinMode(trig1, OUTPUT);
  pinMode(echo1, INPUT);

  pinMode(trig2, OUTPUT);
  pinMode(echo2, INPUT);

  myServo.attach(6);   // use pin 6 for servo
}

// -----------------------------------------------------
int getDistance(int trigPin, int echoPin) {

  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);

  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH, 25000); // timeout 25ms

  int dist = duration * 0.034 / 2;

  if (dist == 0 || dist > 400) dist = 400; // sensor error = max range

  return dist;
}

// -----------------------------------------------------
void loop() {

  // Sweep forward
  for (int angle = 0; angle <= 180; angle++) {
    myServo.write(angle);
    delay(25);

    dist1 = getDistance(trig1, echo1);
    dist2 = getDistance(trig2, echo2);

    finalDist = min(dist1, dist2);  // nearest object wins (kept for compatibility)

    // send both distances to Processing in one message:
    // format: angle,dist1,dist2.
    Serial.print(angle);
    Serial.print(",");
    Serial.print(dist1);
    Serial.print(",");
    Serial.print(dist2);
    Serial.print(".");
  }

  // Sweep backward
  for (int angle = 180; angle >= 0; angle--) {
    myServo.write(angle);
    delay(25);

    dist1 = getDistance(trig1, echo1);
    dist2 = getDistance(trig2, echo2);

    finalDist = min(dist1, dist2);

    Serial.print(angle);
    Serial.print(",");
    Serial.print(dist1);
    Serial.print(",");
    Serial.print(dist2);
    Serial.print(".");
  }
}
