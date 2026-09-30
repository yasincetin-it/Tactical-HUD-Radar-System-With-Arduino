#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2); 

const int trigPin = 2; 
const int echoPin = 3; 

long duration;
int distance;

void setup() {
  Serial.begin(115200); 
  
  lcd.init();          
  lcd.backlight();     

  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  
  lcd.setCursor(0, 0);
  lcd.print("HUD RADAR v3.0");
  lcd.setCursor(0, 1);
  lcd.print("SYSTEM: LINKED");
  delay(1000);
}

void loop() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  
  duration = pulseIn(echoPin, HIGH, 20000); 
  distance = duration * 0.0343 / 2; 

  if (distance <= 0 || distance > 200) distance = 200;

  Serial.print("DAT:");
  Serial.println(distance);

  lcd.clear(); 
  lcd.setCursor(0, 0);
  lcd.print("TACTICAL RADAR");
  lcd.setCursor(0, 1);
  if (distance >= 200) {
    lcd.print("RANGE: CLEAR"); 
  } else {
    lcd.print("TARGET: ");
    lcd.print(distance);
    lcd.print(" cm");
  }

  delay(40); 
}
