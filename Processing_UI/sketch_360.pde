// 360-degree radar (Processing)
// Expects Arduino serial messages like:
//   angle,dist1,dist2.
// where angle is 0..180 (servo position), dist1 = sensorA cm, dist2 = sensorB cm
// Sensor B is mounted opposite sensor A and will be plotted at (angle+180) % 360.
//
// Minimal UI changes — preserved the original neon green style and text positions,
// but the radar is centered (not cropped) and covers full 360°.

import processing.serial.*;
Serial myPort;

String raw = "";
int iAngle = 0;        // servo angle (0..180)
int distA = 400;       // sensor A distance (cm), 400 = out
int distB = 400;       // sensor B distance (cm)
float pixA, pixB;

float panelH;          // height reserved for info at bottom
float centerX, centerY;
float radius;          // radar radius in pixels
int MAX_DIST_CM = 40;  // max distance shown on radar

void setup() {
  size(1200, 700);            // change to your screen resolution if needed
  smooth();
  frameRate(60);

  // change the COM port string below if your Arduino is on a different port
  println("Available serial ports:");
  println(Serial.list());
  // Example: myPort = new Serial(this, "COM5", 9600);
  // By default pick the first port listed — replace if incorrect
  myPort = new Serial(this, "COM5", 9600);
  myPort.bufferUntil('.');

  // reserve bottom panel (like original)
  panelH = height * 0.12;

  // Radar center should be middle of the usable area (top area above panel)
  centerX = width / 2.0;
  centerY = (height - panelH) / 2.0;

  // radius should fit inside the usable area without cropping
  radius = min(width, height - panelH) * 0.45; // 90% of half the available size
}

void draw() {
  // motion blur / slow fade like original
  noStroke();
  fill(0, 4);                    // translucent black to fade trails
  rect(0, 0, width, height);

  // draw the radar components
  drawRadar();
  drawSweepLine();
  drawObjects();
  drawText();
}

// serial parsing: handle "angle,dist1,dist2." or "angle,dist."
void serialEvent(Serial p) {
  String s = p.readStringUntil('.');
  if (s == null) return;
  s = trim(s);
  if (s.endsWith(".")) s = s.substring(0, s.length()-1);
  if (s.length() == 0) return;

  // split by comma
  String[] parts = split(s, ',');
  if (parts.length == 2) {
    // legacy: angle,dist
    try {
      iAngle = int(trim(parts[0]));
    } catch (Exception e) { iAngle = 0; }
    try {
      distA = parseDist(parts[1]);
    } catch (Exception e) { distA = 400; }
    distB = 400; // no data for B in this message
  } else if (parts.length >= 3) {
    try {
      iAngle = int(trim(parts[0]));
    } catch (Exception e) { iAngle = 0; }
    distA = parseDist(parts[1]);
    distB = parseDist(parts[2]);
  }
}

// helper: parse distance string and treat spurious large values as out
int parseDist(String token) {
  token = trim(token);
  if (token.equalsIgnoreCase("Out")) return 400;
  try {
    int v = int(token);
    if (v >= 250) return 400; // treat 255/256 etc. as Out
    return v;
  } catch (Exception e) {
    return 400;
  }
}

void drawRadar() {
  pushMatrix();
  translate(centerX, centerY);

  // rings and style like original but full circles now
  noFill();
  strokeWeight(2);
  stroke(98, 245, 31);

  // concentric rings (4 rings like original)
  ellipse(0, 0, radius*2, radius*2);
  ellipse(0, 0, radius*1.5, radius*1.5);
  ellipse(0, 0, radius*1.0, radius*1.0);
  ellipse(0, 0, radius*0.5, radius*0.5);

  // radial spokes every 30° (full circle)
  for (int a = 0; a < 360; a += 30) {
    float x = radius * cos(radians(a));
    float y = radius * sin(radians(a));
    line(0, 0, x, -y); // use -y so 90° is upward (match original orientation)
  }

  // angle small tick labels around the outside (preserve original style positions)
  fill(98,245,31);
  noStroke();
  textSize(18);
  textAlign(CENTER, CENTER);
  // labels every 30 degrees around top half and bottom too
  for (int a = 0; a < 360; a += 30) {
    float lx = (radius + 18) * cos(radians(a));
    float ly = (radius + 18) * sin(radians(a));
    pushMatrix();
    translate(lx, -ly); // -ly to keep same rotation
    // rotate text appropriately for readability (optional small rotation)
    text(nf(a,0) + "°", 0, 0);
    popMatrix();
  }

  popMatrix();
}

void drawSweepLine() {
  pushMatrix();
  translate(centerX, centerY);

  // main sweep line from center outward at iAngle (0..360 mapping)
  strokeWeight(9);
  stroke(30, 250, 60, 220);
  float len = radius;
  // convert servo angle (0..180) to two opposite sweep lines simultaneously?
  // We'll draw the current sweep for Sensor A (iAngle) and Sensor B (iAngle+180)
  float ax = len * cos(radians(iAngle));
  float ay = len * sin(radians(iAngle));
  line(0, 0, ax, -ay);

  // draw the opposite sweep marker lightly (for B)
  strokeWeight(6);
  stroke(30, 200, 60, 120);
  float bAngle = (iAngle + 180) % 360;
  float bx = len * cos(radians(bAngle));
  float by = len * sin(radians(bAngle));
  line(0, 0, bx, -by);

  popMatrix();
}

void drawObjects() {
  pushMatrix();
  translate(centerX, centerY);

  // map distance cm -> pixels: map 0..MAX_DIST_CM to 0..radius
  float scale = radius / (float)MAX_DIST_CM;
  if (scale < 0.1) scale = 1;

  // Sensor A at iAngle
  if (distA > 0 && distA < MAX_DIST_CM) {
    pixA = distA * scale;
    strokeWeight(9);
    stroke(255, 10, 10, 220);
    float ax = pixA * cos(radians(iAngle));
    float ay = pixA * sin(radians(iAngle));
    // draw radial small line from object point to outer ring to mimic blade look
    line(ax, -ay, radius * cos(radians(iAngle)), -radius * sin(radians(iAngle)));
  }

  // Sensor B plotted at opposite side: angleB = iAngle + 180
  int angleB = (iAngle + 180) % 360;
  if (distB > 0 && distB < MAX_DIST_CM) {
    pixB = distB * scale;
    strokeWeight(7);
    stroke(255, 120, 30, 200);
    float bx = pixB * cos(radians(angleB));
    float by = pixB * sin(radians(angleB));
    line(bx, -by, radius * cos(radians(angleB)), -radius * sin(radians(angleB)));
  }

  popMatrix();
}

void drawText() {
  // bottom black info band like original
  noStroke();
  fill(0);
  rect(0, height - panelH, width, panelH);

  fill(98,245,31);
  textSize(40);
  textAlign(LEFT, BASELINE);
  // Title left
  text("360° Ultrasonic-OS", 20, height - panelH/2 + 10);

  // angle in middle-ish
  textAlign(CENTER, BASELINE);
  text("Angle: " + iAngle + " °", width/2, height - panelH/2 + 10);

  // Distances right side, stacked
  textAlign(RIGHT, BASELINE);
  textSize(28);
  String d1 = (distA < 400 ? distA + " cm" : "Out");
  String d2 = (distB < 400 ? distB + " cm" : "Out");
  text("Sensor A: " + d1, width - 20, height - panelH/2 - 6);
  text("Sensor B: " + d2, width - 20, height - panelH/2 + 26);

  // small range ticks along bottom like original
  fill(98,245,31);
  textSize(20);
  // place ticks relative to center right half (0..MAX_DIST_CM)
  float tickBaseY = height - panelH/2 + 10;
  for (int cm = 10; cm <= MAX_DIST_CM; cm += 10) {
    float px = centerX + (cm * (radius / MAX_DIST_CM)) * cos(radians(0));
    float py = centerY - (cm * (radius / MAX_DIST_CM)) * sin(radians(0));
    // draw small marker on right-most semicircle baseline
    text(nf(cm,0) + "cm", centerX + cm * (radius / MAX_DIST_CM) - 20, height - 8);
  }
}
