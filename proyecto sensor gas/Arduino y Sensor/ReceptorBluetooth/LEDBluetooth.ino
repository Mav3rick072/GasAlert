int led = 5;
char letra;
void setup() {
  pinMode(led,OUTPUT);
  Serial.begin(9600);
}
void loop() {
  if(Serial.available()>0)
  {
    letra = Serial.read();
  }
  switch(letra){
  case 'a':
  digitalWrite(led,HIGH);
  break;
  case 'b':
  digitalWrite(led,LOW);
  break;
 }
}