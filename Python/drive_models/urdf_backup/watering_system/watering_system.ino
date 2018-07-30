/*
  Blink
  The basic Energia example.
  Turns on an LED on for one second, then off for one second, repeatedly.
  Change the LED define to blink other LEDs.
  
  Hardware Required:
  * LaunchPad with an LED
  
  This example code is in the public domain.
*/

// most launchpads have a red LED
#define LED RED_LED

//see pins_energia.h for more LED definitions
//#define LED GREEN_LED
unsigned long previousMillis1 = 0;
unsigned long previousMillis2 = 0;
unsigned long interval_hours = 0.05;
unsigned long interval_blink = 1000;
unsigned long init_counter = 0;
// the setup routine runs once when you press reset:
void setup() {                
  // initialize the digital pin as an output.
  pinMode(RED_LED, OUTPUT);   
  pinMode(GREEN_LED, OUTPUT);   
  pinMode(GREEN_LED, OUTPUT); 
  pinMode(PB_5, OUTPUT);  

  previousMillis1 = millis(); 
  previousMillis2 = millis();  
}

// the loop routine runs over and over again forever:
void loop() {

  if ((unsigned long)(millis() - previousMillis1) >= 3600000*24 || init_counter == 0){
    digitalWrite(GREEN_LED, HIGH);   // turn the LED on (HIGH is the voltage level)
    digitalWrite(PB_5, HIGH);
    sleep(6000*24);               // wait for a minute
    digitalWrite(GREEN_LED, LOW);    // turn the LED off by making the voltage LOW
    digitalWrite(PB_5, LOW);
    previousMillis1 = millis();
    init_counter++;
  }
  
  if ((unsigned long)(millis() - previousMillis2)/1000 >= interval_blink){
    digitalWrite(RED_LED, HIGH);   // turn the LED on (HIGH is the voltage level)
    sleep(500);               // wait for a second
    digitalWrite(RED_LED, LOW);    // turn the LED off by making the voltage LOW   
    previousMillis2 = millis();
  }
  sleep(interval_blink); 

}
