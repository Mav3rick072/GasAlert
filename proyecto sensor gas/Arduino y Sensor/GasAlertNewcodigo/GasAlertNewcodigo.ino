#include <LiquidCrystal.h>
#include <Servo.h>
#include <SoftwareSerial.h>

// ---------- Configuración de Pines ---------- //
LiquidCrystal lcd(2, 3, 4, 5, 6, 7);

// Sensor MQ6
const int gasAnalogPin = A0;
const int gasDigitalPin = 11;

// Actuadores
const int ledPin = 13;
const int servoPin = 9;

// ---------- Configuración Bluetooth ---------- //
#define BT_RX 8   // RX del Arduino ← TX del HC-05
#define BT_TX 10  // TX del Arduino → RX del HC-05
SoftwareSerial bluetooth(BT_RX, BT_TX);

// ---------- Objetos y variables ---------- //
Servo miServo;
const int umbralGas = 300;
String receivedData = "";

void setup() {
  Serial.begin(9600);
  bluetooth.begin(9600);

  pinMode(gasDigitalPin, INPUT);
  pinMode(ledPin, OUTPUT);

  miServo.attach(servoPin);
  miServo.write(0);

  lcd.begin(16, 2);
  lcd.setCursor(0, 0);
  lcd.print("Inicializando...");
  delay(2000);
}

void loop() {

  // ----- Lectura del MQ6 -----
  int valorAnalogico = analogRead(gasAnalogPin);
  int valorDigital = digitalRead(gasDigitalPin);

  // ----- Mostrar en LCD -----
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Gas: ");
  lcd.print(valorAnalogico);

  if (valorAnalogico > umbralGas || valorDigital == LOW) {
    digitalWrite(ledPin, HIGH);
    miServo.write(90);
    lcd.setCursor(0, 1);
    lcd.print("¡Alerta de gas!");
  } else {
    digitalWrite(ledPin, LOW);
    miServo.write(0);
    lcd.setCursor(0, 1);
    lcd.print("Sin gas.");
  }

  // ----- Enviar datos por Serial -----
  Serial.print("A0: ");
  Serial.print(valorAnalogico);
  Serial.print(" | D0: ");
  Serial.println(valorDigital);

  // ----- ENVIAR DATOS AL BLUETOOTH (para Flutter) -----
  bluetooth.print("A0:");
  bluetooth.print(valorAnalogico);
  bluetooth.print(",D0:");
  bluetooth.print(valorDigital);
  bluetooth.print(",Estado:");

  if (valorAnalogico > umbralGas || valorDigital == LOW) {
    bluetooth.println("Alerta");
  } else {
    bluetooth.println("OK");
  }
  // Ejemplo de salida:
  // A0:350,D0:0,Estado:Alerta

  // ----- Comandos desde Flutter -----
  if (bluetooth.available()) {
    char c = bluetooth.read();
    if (c == '\n') {
      processBluetoothCommand(receivedData);
      receivedData = "";
    } else {
      receivedData += c;
    }
  }

  delay(1000);
}

void processBluetoothCommand(String command) {
  Serial.print("Cmd: ");
  Serial.println(command);

  if (command == "abrir") {
    miServo.write(90);
    bluetooth.println("Ventana abierta");
  }

  if (command == "cerrar") {
    miServo.write(0);
    bluetooth.println("Ventana cerrada");
  }
}
