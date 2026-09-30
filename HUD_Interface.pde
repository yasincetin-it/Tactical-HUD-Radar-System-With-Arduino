import processing.serial.*;

Serial myPort;
String rawData = "";
int liveDistance = 200;
int smoothDistance = 200; 
float radarAngle = 0;
int sweepDirection = 1;
int[] historyLog = new int[60]; 

void setup() {
  size(1100, 700); 
  frameRate(60);   
  
  for (int i = 0; i < historyLog.length; i++) historyLog[i] = 200;
  
  try {
    String portName = Serial.list()[0]; 
    myPort = new Serial(this, portName, 115200); 
    myPort.bufferUntil('\n');
  } catch (Exception e) {
    println("CRITICAL ERROR: Hardware connection failed!");
  }
}

void draw() {
  fill(3, 8, 5, 22); 
  noStroke();
  rect(0, 0, width, height);
  
  smoothDistance += (liveDistance - smoothDistance) * 0.15;
  
  int rX = 400; 
  int rY = height - 100; 
  int rSize = 550; 
  
  // --- 1. MILITARY GRID NET ---
  stroke(0, 80, 20, 25);
  strokeWeight(1);
  for (int i = 0; i < width; i += 50) line(i, 0, i, height);
  for (int j = 0; j < height; j += 50) line(0, j, width, j);
  
  // --- 2. RADAR CIRCLES & HUD RINGS ---
  noFill();
  stroke(0, 255, 120, 35);
  for (int r = 100; r <= rSize; r += 150) {
    ellipse(rX, rY, r * 2, r * 2);
    fill(0, 255, 120, 70);
    textSize(10);
    text((int)map(r, 0, rSize, 0, 200) + "cm", rX + r + 5, rY + 4);
    noFill();
  }
  
  for (int angle = 15; angle <= 165; angle += 15) {
    float rad = radians(angle);
    stroke(0, 255, 120, 25);
    line(rX, rY, rX + rSize * cos(-rad), rY + rSize * sin(-rad));
  }
  
  // --- 3. SWEEPING RADAR BEAM ---
  radarAngle += 0.035 * sweepDirection;
  if (radarAngle > PI || radarAngle < 0) sweepDirection *= -1;
  
  for (int i = 0; i < 15; i++) {
    stroke(0, 255, 120, 200 - (i * 13));
    strokeWeight(4 - (i * 0.25));
    line(rX, rY, rX + (rSize - 10) * cos(-radarAngle + (i * 0.008 * sweepDirection)), rY + (rSize - 10) * sin(-radarAngle + (i * 0.008 * sweepDirection)));
  }
  
  // --- 4. TARGET ACQUISITION & HUD SYMBOLS ---
  float mappedTarget = map(smoothDistance, 0, 200, 0, rSize - 10);
  
  if (smoothDistance < 190) {
    float tX = rX + mappedTarget * cos(-radarAngle);
    float tY = rY + mappedTarget * sin(-radarAngle);
    
    color hudColor = color(0, 255, 150); 
    if (smoothDistance < 25) hudColor = color(255, 0, 50); 
    else if (smoothDistance < 60) hudColor = color(255, 160, 0); 
    
    fill(hudColor, 180);
    noStroke();
    ellipse(tX, tY, 12, 12);
    
    noFill();
    stroke(hudColor, 220);
    strokeWeight(2);
    rect(tX - 16, tY - 16, 32, 32);
    strokeWeight(1);
    ellipse(tX, tY, 40, 40);
    line(tX - 30, tY, tX + 30, tY);
    line(tX, tY - 30, tX, tY + 30);
    
    fill(hudColor);
    textSize(11);
    text("TRACK_ID: #0972", tX + 25, tY - 15);
    text("RNG: " + smoothDistance + " CM", tX + 25, tY);
  }
  
  // --- 5. TELEMETRY & CONTROL PANEL ---
  int panelX = 750;
  fill(2, 18, 8, 230);
  stroke(0, 255, 120, 90);
  strokeWeight(2);
  rect(panelX, 40, 310, 320, 8); 
  
  fill(0, 255, 120);
  textSize(18);
  text("TACTICAL TELEMETRY", panelX + 20, 75);
  stroke(0, 255, 120, 40);
  line(panelX + 20, 85, panelX + 290, 85);
  
  textSize(13);
  text("RADAR CORE STATUS:", panelX + 20, 115);
  fill(0, 255, 100);
  ellipse(panelX + 260, 111, 10, 10); 
  text("ONLINE", panelX + 195, 115);
  
  fill(0, 255, 120);
  text("SYS TIMING FREQ:", panelX + 20, 145);
  text((int)frameRate + " FPS // 115K BPS", panelX + 160, 145);
  
  text("WAVE VELOCITY:", panelX + 20, 175);
  text("343.2 m/s (20°C)", panelX + 160, 175);
  
  stroke(0, 255, 120, 40);
  line(panelX + 20, 200, panelX + 290, 200);
  
  textSize(14);
  text("THREAT EVALUATION:", panelX + 20, 230);
  
  if (smoothDistance >= 190) {
    fill(0, 255, 150);
    textSize(26);
    text("ZONE CLEAR", panelX + 20, 275);
    textSize(13);
    text("NO WAVE REFLECTION DETECTED", panelX + 20, 305);
  } else {
    if (smoothDistance < 25) {
      fill(255, 0, 50);
      textSize(26);
      text("CRITICAL INTRUSION", panelX + 20, 275);
    } else {
      fill(255, 160, 0);
      textSize(26);
      text("TARGET ACQUIRED", panelX + 20, 275);
    }
    fill(0, 255, 120);
    textSize(16);
    text("EXACT RANGE: " + smoothDistance + " CM", panelX + 20, 305);
  }
  
  // --- 6. REAL-TIME DISTANCE SPECTRUM (HISTOGRAM) ---
  int graphY = height - 100;
  fill(2, 18, 8, 230);
  stroke(0, 255, 120, 90);
  rect(panelX, 390, 310, 210, 8);
  
  fill(0, 255, 120);
  textSize(14);
  text("REAL-TIME DISTANCE SPECTRUM", panelX + 20, 415);
  
  for (int i = 0; i < historyLog.length; i++) {
    float barHeight = map(historyLog[i], 0, 200, 0, 130);
    if (historyLog[i] < 25) stroke(255, 0, 50, 200);
    else if (historyLog[i] < 60) stroke(255, 160, 0, 200);
    else stroke(0, 255, 120, 160);
    
    strokeWeight(3);
    line(panelX + 25 + (i * 4.3), graphY - 10, panelX + 25 + (i * 4.3), graphY - 10 - (130 - barHeight));
  }
  
  stroke(0, 255, 120, 50);
  line(30, height - 40, width - 30, height - 40);
  fill(0, 255, 120, 150);
  textSize(12);
  text("TACTICAL HUD RADAR TERMINAL v3.0 // SECURE LINK", 30, height - 20);
}

void serialEvent(Serial myPort) {
  rawData = myPort.readStringUntil('\n');
  if (rawData != null) {
    rawData = trim(rawData);
    
    if (rawData.startsWith("DAT:")) {
      String cleanNumber = rawData.substring(4);
      
      try {
        if (cleanNumber.length() > 0) {
          liveDistance = Integer.parseInt(cleanNumber);
          
          for (int i = 0; i < historyLog.length - 1; i++) {
            historyLog[i] = historyLog[i + 1];
          }
          historyLog[historyLog.length - 1] = liveDistance;
        }
      } catch (NumberFormatException e) {
        // Drop corrupted packets
      }
    }
  }
}
