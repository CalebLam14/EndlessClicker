/*
 * Caleb Lam
 * Jan. 18, 2019
 * FinalProject.ino
 * The Arduino part of the Endless Clicker game.
 * Receives data from the serial port.
 * A 4-in-1 8x8 LED matrix display is used as a score board.
 * A buzzer is used to emit sounds when scoring, losing a chance or the game is over.
 * LEDs are used to count chances.
 */

// Libraries //
// Include some functions to control some components.
#include <Thread.h> // https://github.com/ivanseidel/ArduinoThread
#include <LedControl.h> // https://github.com/wayoda/LedControl

// Note Frequencies //
// Define the frequencies of each (used) note.
#define NOTE_LOW_B 247
#define NOTE_C 523
#define NOTE_D 587
#define NOTE_E 659
#define NOTE_G 784

// Matrix Pins
#define DIN 12
#define CLK 11
#define CS 10

// Serial Data Variables //
// Stores data received from the serial.
String data = String(""); // Initialize it. (Just "" does not do that.)
int MIN_DATA_LENGTH = 13; // Min langth to run functions based on the data.
bool stringComplete = false; // Whether the string is ready to be processed.

// Pins and Component Variables //
int buzzerPin = 6; // Buzzer.

int numModules = 4; // There are this many modules.
int moduleSize = 8; // The number of LEDs for each row and column.

// LED Pins
int ledPins[] = {4, 3, 2}; // Red LEDs.
int indicatorLed = 5; // Green LED.

// LedControl object to control the matrices.
LedControl lc = LedControl(DIN, CLK, CS, numModules);

// Variables that store data extracted from the serial data.
int scene;
int chances;
String score; // Already padded with zeroes.
String highScore;
int prevChances = 3;
String prevScore = "0";
String prevHighScore = "0";

// All the threads. (Wait... You can't really multithread an Arduino though.)
// The ArduinoThread libraries uses another way to make the Arduino board act as if it were "multithreading."
Thread highScoreSoundThread = Thread();
Thread scoringSoundThread = Thread();
Thread chanceLostSoundThread = Thread();
Thread blinkHighScoreThread = Thread();
Thread updateCircuitThread = Thread();
Thread updateScoreAndChancesThread = Thread();

bool blinkHighScore = false; // Display the high score or numbers?

// All the states of the LEDs for each number on a matrix.
const byte NUMBERS[][8] = {
{ 
  B01111110, // 0
  B01000010,
  B01000010,
  B01000010,
  B01000010,
  B01000010,
  B01000010,
  B01111110
},{ 
  B00001000, // 1
  B00011000,
  B00101000,
  B00001000,
  B00001000,
  B00001000,
  B00001000,
  B00111100
},{
  B01111110, // 2
  B00000010,
  B00000010,
  B01111110,
  B01000000,
  B01000000,
  B01000000,
  B01111110
},{
  B01111110, // 3
  B00000010,
  B00000010,
  B01111110,
  B00000010,
  B00000010,
  B00000010,
  B01111110
},{
  B01000010, // 4
  B01000010,
  B01000010,
  B01111110,
  B00000010,
  B00000010,
  B00000010,
  B00000010
},{
  B01111110, // 5
  B01000000,
  B01000000,
  B01111110,
  B00000010,
  B00000010,
  B00000010,
  B01111110
},{
  B01111110, // 6
  B01000000,
  B01000000,
  B01111110,
  B01000010,
  B01000010,
  B01000010,
  B01111110
},{
  B01111110, // 7
  B00000010,
  B00000010,
  B00000010,
  B00000010,
  B00000010,
  B00000010,
  B00000010
},{
  B01111110, // 8
  B01000010,
  B01000010,
  B01111110,
  B01000010,
  B01000010,
  B01000010,
  B01111110
},{
  B01111110, // 9
  B01000010,
  B01000010,
  B01111110,
  B00000010,
  B00000010,
  B00000010,
  B01111110
}};

// All the letters to display the word "BEST".
const byte LETTERS[][8] = {
{
  B01111100, // B
  B01000010,
  B01000010,
  B01111100,
  B01000010,
  B01000010,
  B01000010,
  B01111100
},{
  B01111110, // E
  B01000000,
  B01000000,
  B01111110,
  B01000000,
  B01000000,
  B01000000,
  B01111110
},{
  B00111100, // S
  B01000010,
  B01000000,
  B00111100,
  B00000010,
  B00000010,
  B00000010,
  B01111100
},{
  B01111110, // T
  B00001000,
  B00001000,
  B00001000,
  B00001000,
  B00001000,
  B00001000,
  B00001000
}};

// Plays a sound when a point is earned.
void emitScoreSound () {
  tone(buzzerPin, NOTE_C, 0.05 * 1000);
}

// Plays a sound when a chance is lost.
void emitChanceLostSound () {
  tone(buzzerPin, NOTE_LOW_B, 0.05 * 1000);
  delay(125);
  tone(buzzerPin, NOTE_LOW_B, 0.1 * 1000);
}

// Plays a sound when a new high score is achieved.
void emitHighScoreSound () {
  unsigned long lastTracked = millis();
  int notes[] = {NOTE_C, NOTE_D, NOTE_E, NOTE_G, NOTE_E, NOTE_G};
  int toneDuration = 0.05 * 1000;
  int delays[] = {125, 125, 125, 250, 125, 0};
  for (int i = 0; i < 6; i++) {
    // noTone(buzzerPin);
    tone(buzzerPin, notes[i], toneDuration);
    delay(delays[i]);
  }
}

// Displays "BEST" on the matrices.
void displayLetters () {
  for (int i = 0; i < 4; i++) {
    int module = numModules - (i + 1);
    for (int row = 0; row < moduleSize; row++) {
      lc.setRow(module, row, LETTERS[i][row]);
    }
  }
}

// Displays the score/high score on the matrices.
void displayScore (String scoreStr) {
  for (int i = 0; i < scoreStr.length() + 1; i++) {
    int module = numModules - (i + 1);
    int number = String(scoreStr.charAt(i)).toInt();
    for (int row = 0; row < moduleSize; row++) {
      lc.setRow(module, row, NUMBERS[number][row]);
    }
  }
}

// Lights up LEDs based on the number of chances.
void displayChances (int chances) {
  for (int i = 0; i < 3; i++) {
    if (i + 1 <= chances) {
      digitalWrite(ledPins[i], HIGH);
    }
    else {
      digitalWrite(ledPins[i], LOW);
    }
  }
}

// Alternates between displaying "BEST" or the high score.
void highScoreSequence() {
  if (blinkHighScore == true) {
    displayScore(prevHighScore);
  }
  else {
    displayLetters();
  }

  blinkHighScore = !blinkHighScore;
}

// Displays the score and the chances.
void updateScoreAndChances () {
  displayScore(score);
  displayChances(chances);
}

// Extracts the integer from a string with padded zeroes.
int getIntFromString (String str) {
  String intStr = "";
  bool startStr = false;
  for (int i = 0; i < str.length() + 1; i++) {
    char c = str.charAt(i);
    if (c != '0' || startStr == true || i >= str.length()) {
      startStr = true;
      intStr += c;
    }
  }
  return intStr.toInt();
}

// Runs first.
void setup () {
  Serial.begin(9600); // Begin serial communication.

  // Hook up functions for each thread.
  highScoreSoundThread.onRun(emitHighScoreSound);
  scoringSoundThread.onRun(emitScoreSound);
  chanceLostSoundThread.onRun(emitChanceLostSound);
  blinkHighScoreThread.onRun(highScoreSequence);
  updateCircuitThread.onRun(updateCircuit);
  updateScoreAndChancesThread.onRun(updateScoreAndChances);

  blinkHighScoreThread.setInterval(2000); // Set the interval to run.

  // Declare outputs.
  for (int i = 0; i < 3; i++) {
    pinMode(ledPins[i], OUTPUT);
  }
  pinMode(indicatorLed, OUTPUT);
  pinMode(buzzerPin, OUTPUT);

  // Turn on the matrices.
  for (int i = 0; i < numModules; i++) {
    lc.shutdown(i, false);
  }
}

// Updates the whole circuit based on the extracted data.
void updateCircuit () {
  // Store the values from the data received.
  scene = data.substring(0, 1).toInt();
  chances = data.substring(2, 3).toInt();
  score = data.substring(4, 8); // Already padded with zeroes.
  highScore = data.substring(9, 13);

  // Based on the scene from the data, update the circuit.
  switch (scene) {
    case 0: // Main menu
      // Blink high score.
      if (blinkHighScoreThread.shouldRun()) {
        prevHighScore = highScore;
        blinkHighScoreThread.run();
      }
      break;
    case 1: // Game screen
      // Update the score and chances.
      if (updateScoreAndChancesThread.shouldRun()) {
        updateScoreAndChancesThread.run();
      }

      // Play a sound when a point is earned.
      if (getIntFromString(score) > getIntFromString(prevScore)) {
        scoringSoundThread.run();
      }

      // Play a sound when a chance is lost.
      if (chances < prevChances && chances > 0) {
        chanceLostSoundThread.run();
      }
      break;
    case 2: // Game over screen
      // Display the score and chances once more.
      updateScoreAndChancesThread.run();
      // Play a tune when a new high score is achieved, then set the new high score as the current score.
      if (getIntFromString(score) > getIntFromString(highScore)) {
        highScore = score;
        highScoreSoundThread.run();
      }

      // Reset this variable to always display "BEST" when returning to the main menu.
      blinkHighScore = false;
      break;
  }

  // Set the previously tracked data and reset the data variable.
  prevChances = chances;
  prevScore = score;
  data = "";
  stringComplete = false;
}

void loop () {
  // When the data is complete and it matches the target size.
  // This is so that the circuit does not update based on wrong/incomplete data.
  // Turns on a green LED when the circuit can update, otherwise turn it off.
  if (stringComplete && data.length() >= MIN_DATA_LENGTH) {
    digitalWrite(indicatorLed, HIGH);
    updateCircuitThread.run();
  }
  else {
    digitalWrite(indicatorLed, LOW); 
  }
}

void serialEvent() {
  while (Serial.available()) {
    // Get the new character.
    char inChar = (char)Serial.read();

    // If the character is '|', reset the string.
    if (inChar == '|') {
      data = "";
    }
    else {
      // Otherwise, add it to the data.
      data += inChar;
    }
    // if the incoming character is a newline, let the main loop do something about it.
    if (inChar == '\n') {
      stringComplete = true;
    }
  }
}
