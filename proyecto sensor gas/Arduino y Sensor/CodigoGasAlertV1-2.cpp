#include <LiquidCrystal.h>
#include <Servo.h>
#include <SoftwareSerial.h>

// ---------- Configuración de Pines ---------- //
// LCD en modo paralelo: RS, E, D4, D5, D6, D7
LiquidCrystal lcd(2, 3, 4, 5, 6, 7);

// Sensor MQ6
const int gasAnalogPin = A0;
const int gasDigitalPin = 11;

// Actuadores
const int ledPin = 13;
const int servoPin = 9;

// ---------- Configuración de Bluetooth ---------- //
#define BT_RX 8
#define BT_TX 10
SoftwareSerial bluetooth(BT_RX, BT_TX);

// ---------- Objetos y variables ---------- //
Servo miServo;
const int umbralGas = 300;
String receivedData = "";

void setup() {
  // Comunicación serial
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
  // Leer valores del sensor MQ6
  int valorAnalogico = analogRead(gasAnalogPin);
  int valorDigital = digitalRead(gasDigitalPin);

  // Mostrar en LCD
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Gas: ");
  lcd.print(valorAnalogico);

  // Variable para enviar por Bluetooth
  String estado = "";

  if (valorAnalogico > umbralGas || valorDigital == LOW) {
    digitalWrite(ledPin, HIGH);
    miServo.write(90);
    lcd.setCursor(0, 1);
    lcd.print("¡Alerta de gas!");
    estado = "ALERTA";
  } else {
    digitalWrite(ledPin, LOW);
    miServo.write(0);
    lcd.setCursor(0, 1);
    lcd.print("Sin gas.");
    estado = "SIN_GAS";
  }

  // ---------- 🔵 Enviar datos por Bluetooth ---------- //
  bluetooth.print("GAS:");
  bluetooth.print(valorAnalogico);
  bluetooth.print(";ESTADO:");
  bluetooth.println(estado);
  // Ejemplo: GAS:350;ESTADO:ALERTA

  // ---------- Monitor Serial ---------- //
  Serial.print("Valor MQ6 (A0): ");
  Serial.print(valorAnalogico);
  Serial.print(" | D0: ");
  Serial.println(valorDigital);

  // ---------- Comandos Bluetooth ---------- //
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

// ---------- Procesar comandos ---------- //
void processBluetoothCommand(String command) {
  Serial.print("Comando recibido: ");
  Serial.println(command);

  if (command == "abrir") {
    miServo.write(90);
    bluetooth.println("Ventana abierta.");
  }

  if (command == "cerrar") {
    miServo.write(0);
    bluetooth.println("Ventana cerrada.");
  }
}
