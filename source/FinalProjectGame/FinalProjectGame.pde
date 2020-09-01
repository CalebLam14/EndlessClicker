/*
 * Caleb Lam
 * Jan. 18, 2019
 * FinalProjectGame.pde
 * The Processing part of the Endless Clicker game.
 * This program draws visuals and interfaces of the game.
 */

// Libraries //  
import java.util.concurrent.*; // To get access to the CopyOnWriteArrayList object.  
import processing.serial.*; // To get access to the Serial functions.  
  
// Fonts //  
String fontsFolder = "fonts/";  
PFont boldFont; // Bolded font  
PFont thinFont; // Normal text font  
  
// Serial Communication Variables //  
String DATA_STRING = "0"; // The data to send.
int PORT_INDEX = 0; // This should be 1 if on a desktop. Change it to suit your device.
Serial port = null; // To store the connected serial port.  
boolean gameReady = false; // Is true when a serial port is connected.  
boolean GAME_DEBUG = false; // Skip the serial connection. Debugging purposes only.  
  
// Game Control Variables //  
int scene = 0; // To control the scene that is rendered in the game. Different scenes have different functions.  
  
// Keep track of time to spawn circles or increase difficulty when needed.  
int lastSpawnMillis = 0;  
int lastDiffMillis = 0;  
  
int maxCircles = 20; // For each lane, check if the number of circles is smaller or equal to this number.  
CopyOnWriteArrayList<CopyOnWriteArrayList<Circle>> circles = new CopyOnWriteArrayList<CopyOnWriteArrayList<Circle>>(); // Stores the list of circles.  
  
float diffIncreaseTime = 30f; // Increase the difficulty after this many seconds.  
  
float spawnTime = 3f; // Spawn a circle after this many seconds.  
float minSpawnTime = 0.7f; // Caps the minimum time before a circle is spawned.  
float maxSpawnTime = 3f; // Caps the maximum time before a circle is spawned.  
  
float circleShiftRate = 2f; // Move all circles by this many pixels.  
float minShiftRate = 2f; // Caps the minimum shift rate before a circle is spawned.  
float maxShiftRate = 4f; // Caps the maximum shift rate before a circle is spawned.  
  
int points = 0; // The score.  
int chances = 3; // The number of chances left.  
int maxChances = 3; // The number of chances you get at maximum.  
  
int highScore = 0; // The high score.  
  
// Title Screen Variables //  
// Title Text  
String title = "Endless Clicker"; // The title of this game.  
color titleColor = color(125, 25, 125); // Title color in RGB. Google "RGB color picker" to pick the right colors.  
float titleTrans = 10f; // Transparency.  
float titleTransMin = 20f; // Minimum transparency.  
float titleTransMax = 255f; // Maximum transparency.  
float titleTransChangeRate = 255f/120f; // Increase/decrease transparency by this much every frame.  
  
// Play Button Variables  
color playButtonColor = color(130, 255, 70); // Button's background color.  
color playButtonHoverColor = color(0, 125, 0); // Button's background color when the mouse is over it.  
color playButtonTextColor = color(0, 125, 0); // Button's text color.  
color playButtonTextHoverColor = color(130, 255, 70); // Button's text color when the mouse is over it.  
float playButtonWidth = 100f; // Button's width.  
float playButtonHeight = 50f; // Button's height.  
  
// Game Screen Variables //  
// Lanes  
float laneWidth = 600f; // A lane's width.  
float laneHeight = 80f; // A lane's height.  
  
color laneColors[] = { // Colors of each lane.  
  color(255, 40, 45),  
  color(255, 255, 120),  
  color(120, 255, 160)  
};  
  
PVector lanePositions[] = new PVector[3]; // Positions of each lane.  
  
// Game Buttons  
float buttonSize = laneHeight; // Size of each lane button.  
color buttonColors[] = { // Colors of each lane button.  
  color(255, 0, 45),  
  color(255, 255, 0),  
  color(0, 255, 76)  
};  
color buttonHoverColors[] = { // Colors of each lane button when the mouse is over it.  
  color(180, 0, 30),  
  color(180, 180, 0),  
  color(0, 180, 50)  
};  
  
// Circles  
color circleFaceColor = color(200, 200, 200); // Front color of the circle.  
color circleBackColor = color(255, 255, 255); // Color of the circle's edge.  
float circleSize = laneHeight; // The circle's diameter is the same has a lane's height.  
float faceToBackSizeRatio = 0.8f; // 20% of the circle's area is the edge.  
  
// Game Over Screen //  
// Game Over Text  
String gameOverText = "Game Over"; // Text to display when the game is over.  
color gameOverTextColor = color(255, 0, 0); // Color of the game over text.  
  
// Play Again Button  
// Similar to the Play button's variables.  
color playAgainButtonColor = color(130, 255, 70);  
color playAgainButtonHoverColor = color(0, 125, 0);  
color playAgainButtonTextColor = color(0, 125, 0);  
color playAgainButtonTextHoverColor = color(130, 255, 70);  
float playAgainButtonWidth = 200f;  
float playAgainButtonHeight = 50f;  
  
// Main Menu Button  
// Similar to the Play button's variables.  
color mainMenuButtonColor = color(255, 0, 45);  
color mainMenuButtonHoverColor = color(180, 0, 30);  
color mainMenuButtonTextColor = color(255, 255, 0);  
color mainMenuButtonTextHoverColor = color(255, 255, 0);  
float mainMenuButtonWidth = 200f;  
float mainMenuButtonHeight = 50f;  
  
// Menus Buttons //  
Button playButton; // Click on it to play.  
Button laneButtons[] = new Button[3]; // Stores the lane buttons.  
Button playAgainButton; // Click on it to play again.  
Button mainMenuButton; // Click on it to return to the main menu.  
  
// The button class to create buttons.  
class Button {  
  public String label;  
  public PFont font;  
  public float x;    // top left corner x position  
  public float y;    // top left corner y position  
  public float w;    // width of button  
  public float h;    // height of button  
  public float r;    // radius for round corners  
  public color fillColor;  
  public color strokeColor;  
  public color textColor;  
  public color textStrokeColor;  
    
  // Constructor with text.  
  Button(String labelB, PFont fontB, float xpos, float ypos, float widthB, float heightB, float radiusB, color fillColorB, color textColorB) {  
    this.label = labelB;  
    this.font = fontB;  
    this.x = xpos;  
    this.y = ypos;  
    this.w = widthB;  
    this.h = heightB;  
    this.r = radiusB;  
    this.fillColor = fillColorB;  
    this.textColor = textColorB;  
  }  
    
  // Constructor without text.  
  Button(float xpos, float ypos, float widthB, float heightB, float radiusB, color fillColorB) {  
    this.label = "";  
    this.font = thinFont;  
    this.x = xpos;  
    this.y = ypos;  
    this.w = widthB;  
    this.h = heightB;  
    this.r = radiusB;  
    this.fillColor = fillColorB;  
  }  
    
  // Displays the button.  
  void Draw() {  
    fill(this.fillColor);  
    textFont(this.font);  
    // stroke(this.strokeColor);  
    noStroke();  
    rectMode(CENTER);  
    rect(this.x, this.y, this.w, this.h, this.r);  
    textAlign(CENTER, CENTER);  
      
    if (!this.label.equals("")) {  
      fill(this.textColor);  
      stroke(this.textStrokeColor);  
      text(this.label, this.x, this.y);  
    }  
  }  
    
  // Checks if the mouse is over the button.  
  boolean MouseIsOver() {  
    return (mouseX >= (this.x - this.w/2) && mouseX <= (this.x + this.w/2) && mouseY >= (this.y - this.h/2) && mouseY <= (this.y + this.h/2));  
  }  
}  
  
// The circle class to create circles.  
class Circle {  
  public int lane; // Which lane the circle runs on.  
  public float x; // The horizontal position.  
  public color faceColor; // Front color.  
  public color backColor; // Back/edge color.  
    
  private float diameter = (float) laneHeight; // Diameter.  
    
  // Constructor.  
  Circle (int laneB, color faceColorB, color backColorB) {  
    this.lane = laneB;  
    this.faceColor = faceColorB;  
    this.backColor = backColorB;  
      
    diameter = laneHeight;  
    this.x = lanePositions[laneB].x - laneWidth/2 + diameter/2;  
  }  
    
  // Increases x by the shift rate.  
  void ShiftPosition () {  
    this.x += circleShiftRate;  
  }  
    
  // Display the circle.  
  void Draw () {  
    ellipseMode(CENTER);  
    fill(backColor);  
    ellipse(this.x, 120 + (lane * 80), diameter, diameter);  
    fill(faceColor);  
    ellipse(this.x, 120 + (lane * 80), diameter * faceToBackSizeRatio, diameter * faceToBackSizeRatio);  
  }  
}  
  
// Always runs first.  
void setup () {  
  // Set up canvas and initial settings.  
  size(800, 400);  
  rectMode(CENTER);  
  noStroke();  
    
  // Create fonts.  
  boldFont = createFont(fontsFolder + "Roboto-Bold.ttf", 40);  
  thinFont = createFont(fontsFolder + "Roboto-Thin.ttf", 25);  
    
  // Store the lane width and height.  
  laneWidth = width * 0.75f;  
  laneHeight = height * 0.2f;  
    
  // Store the list of circles for each lane and the positions of each lane and its button.  
  for (int i = 0; i < lanePositions.length; i++) {  
    lanePositions[i] = new PVector(width/2 - buttonSize, 120 + i * 80);  
    laneButtons[i] = new Button(lanePositions[i].x + laneWidth/2 + buttonSize/2, lanePositions[i].y, buttonSize, buttonSize, 0f, buttonColors[i]);  
    circles.add(new CopyOnWriteArrayList<Circle>());  
  }  
    
  // Set up menu buttons.  
  playButton = new Button("Play", thinFont, (float) width/2, (float) height/2 + 120, playButtonWidth, playButtonHeight, 0f, playButtonColor, playButtonTextColor);  
  playAgainButton = new Button("Play Again", thinFont, (float) width/2, (float) height/2 + 60, playAgainButtonWidth, playAgainButtonHeight, 0f, playAgainButtonColor, playAgainButtonTextColor);  
  mainMenuButton = new Button("Main Menu", thinFont, (float) width/2, (float) height/2 + 120, mainMenuButtonWidth, mainMenuButtonHeight, 0f, mainMenuButtonColor, mainMenuButtonTextColor);  
    
  // Connect to the serial port and begin drawing the scene.  
  updatePort();  
  updateScreen();  
}  
  
// Runs countless times.  
void draw () {  
  updateScreen(); // Draw the scene.  
    
  // Send data to the serial port. (Character by character)  
  DATA_STRING = "|" + Integer.toString(scene) + "," + Integer.toString(chances) + "," + String.format("%04d", points) + "," + String.format("%04d", highScore) + "\n";  
  if (port != null && !GAME_DEBUG) {  
    println(DATA_STRING);  
    //port.write(DATA_STRING);  
    for (int i = 0; i < DATA_STRING.length(); i++) {  
      port.write(DATA_STRING.charAt(i));  
    }  
  }  
}  
  
// Runs when the mouse is clicked.  
void mouseClicked () {  
  switch (scene) {  
    case 0 :  
      if (playButton.MouseIsOver() && (gameReady || GAME_DEBUG)) {  
        // Start the game.  
        points = 0;  
        scene = 1;  
      }  
      break;  
    case 1 :  
      // Check if a lane button is pressed and a circle overlaps it. Remove the circle if it does.  
      // This will give you a point.  
      for (int i = 0; i < laneButtons.length; i++) {  
        Button laneButton = laneButtons[i];  
        if (laneButton.MouseIsOver()) {  
          CopyOnWriteArrayList<Circle> laneCircles = circles.get(i);  
          for (Circle circle : laneCircles) {  
            if (circle != null) {  
              if (circle.x >= laneButton.x - buttonSize) {  
                circles.get(i).remove(laneCircles.indexOf(circle));  
                // Earn a point!  
                points++;  
                println("Points: " + points);  
                break;  
              }  
                
            }  
          }  
        }  
      }  
      break;  
    case 2:  
      // Play the game again. (Reset and switch back to scene 1.)  
      if (playAgainButton.MouseIsOver()) {  
        resetGame();  
        scene = 1;  
      }  
        
      // Go back to the main menu. (Reset and switch back to scene 0.)  
      if (mainMenuButton.MouseIsOver()) {  
        resetGame();  
        scene = 0;  
      }  
      break;  
  }  
}  
  
// The main function that draws the scenes.  
void updateScreen () {  
  switch (scene) {  
    case 0 : // Title screen/Main menu  
      // Title Background  
      background(125, 125, 125);  
  
      // Title Text  
      fill(titleColor, titleTrans);  
      titleTrans += titleTransChangeRate;  
      if (titleTrans >= titleTransMax) {  
        titleTransChangeRate = -255f/120f;  
      }  
      else if (titleTrans <= titleTransMin) {  
        titleTransChangeRate = 255/120f;  
      }  
      textFont(boldFont);  
      rectMode(CENTER);  
      textAlign(CENTER);  
      // textMode(SHAPE);  
      text(title, width/2, height/3 - 80);  
  
      // Controls Text  
      textFont(thinFont);  
      fill(255, 255, 255);  
      text("Click on a square button when a circle starts to overlap it.", width/2, height/3 - 30);  
      fill(0, 255, 0);  
      text("Each successful click is worth 1 point.", width/2, height/3 + 10);  
      fill(255, 0, 0);  
      text("You can only miss 3 circles.", width/2, height/3 + 50);  
      fill(0, 255, 255);  
      text("Good luck!", width/2, height/3 + 90);  
        
      // Checks for Arduino.  
      if (port == null && !GAME_DEBUG) {  
        fill(255, 0, 0);  
        textFont(thinFont);  
        text("Waiting for Arduino...", playButton.x, playButton.y);  
        updatePort(); // Reconnect if no Arduino is detected.  
      }  
      else {  
        // Make the Play button available.  
        if (playButton.MouseIsOver()) {  
          playButton.fillColor = playButtonHoverColor;  
          playButton.textColor = playButtonTextHoverColor;  
        }  
        else {  
          playButton.fillColor = playButtonColor;  
          playButton.textColor = playButtonTextColor;  
        }  
        playButton.Draw();  
      }  
      break;  
    case 1: // Game screen  
      background(125, 125, 125);  
      rectMode(CENTER);  
        
      drawLanesAndButtons(); // Draw the lanes and buttons.  
      removeOrShiftCircles(); // Remove the missed circles and/or move existing ones.  
        
      // Spawn a circle if the timing is right.  
      int mil = millis();  
      int deltaTimeSpawn = mil - lastSpawnMillis;  
      int deltaTimeDiff = mil - lastDiffMillis;  
      if (deltaTimeSpawn >= spawnTime * 1000  || lastSpawnMillis <= 0) {  
        lastSpawnMillis = mil;  
        spawnCircle();  
      }  
        
      // Increase the difficulty if the timing is right.  
      if (deltaTimeDiff >= diffIncreaseTime * 1000) {  
        lastDiffMillis = mil;  
        increaseDifficulty();  
      }  
      break;  
    case 2: // Game over screen.  
      background(125, 125, 125);  
      fill(gameOverTextColor);  
        
      textFont(boldFont);  
      rectMode(CENTER);  
      textAlign(CENTER);  
        
      // Game over text.  
      text(gameOverText, width/2, height/3);  
        
      // Set a new high score if there is one.  
      if (points > highScore) {  
        highScore = points;  
      }  
        
      // Draw the Play Again button.  
      if (playAgainButton.MouseIsOver()) {  
        playAgainButton.fillColor = playAgainButtonHoverColor;  
        playAgainButton.textColor = playAgainButtonTextHoverColor;  
      }  
      else {  
        playAgainButton.fillColor = playAgainButtonColor;  
        playAgainButton.textColor = playAgainButtonTextColor;  
      }  
      playAgainButton.Draw();  
        
      // Draw the Main Menu button.  
      if (mainMenuButton.MouseIsOver()) {  
        mainMenuButton.fillColor = mainMenuButtonHoverColor;  
        mainMenuButton.textColor = mainMenuButtonTextHoverColor;  
      }  
      else {  
        mainMenuButton.fillColor = mainMenuButtonColor;  
        mainMenuButton.textColor = mainMenuButtonTextColor;  
      }  
      mainMenuButton.Draw();  
        
      break;  
  }  
}  
  
// Connects to a serial port.  
boolean connect(int portNumber, int baudRate, int limit){  
  int tries = 0;  
  while(tries < limit) {  
    try {  
      port = new Serial(this, Serial.list()[portNumber], baudRate);  
      port.clear();  
    }  
    catch (Exception e) {  
      System.err.println("Retrying");  
      tries++;  
      continue;  
    }  
    break;  
  }  
  if (tries < limit) {  
    println("Successful in " + str(tries + 1) + " tries.");  
    return true;  
  }  
  else {  
    System.err.println("Unsucessful. Reached limit.");  
    return false;  
  }  
}  
  
// Updates the port variable.  
void updatePort() {  
  String portList[] = Serial.list();  
  if (portList.length > 0 && port == null) {  
    println("Connecting to serial " + portList[0]);  
    gameReady = connect(PORT_INDEX, 9600, 10); // The first parameter should be 1 if you are using a desktop.  
  }  
  else {  
    port = null;  
  }  
}  
  
// Draws the lanes and their buttons.  
void drawLanesAndButtons () {  
  for (int i = 0; i < lanePositions.length; i++) {  
    float x = lanePositions[i].x;  
    float y = lanePositions[i].y;  
    color laneColor = laneColors[i];  
    Button laneButton = laneButtons[i];  
      
    noStroke();  
    rectMode(CENTER);  
    fill(laneColor);  
    rect(x, y, laneWidth, laneHeight);  
      
    if (laneButton.MouseIsOver()) {  
      laneButton.fillColor = buttonHoverColors[i];  
    }  
    else {  
      laneButton.fillColor = buttonColors[i];  
    }  
    laneButton.Draw();  
      
  }  
}  
  
// Removes missed circle or draw existing ones.  
void removeOrShiftCircles () {  
  for (int i = 0; i < lanePositions.length; i++) {  
    CopyOnWriteArrayList<Circle> laneCircles = circles.get(i);  
    Button laneButton = laneButtons[i];  
    for (Circle circle : laneCircles) {  
      // If a circle passes through its lane's button.  
      if (circle.x > laneButton.x + buttonSize) {  
        circles.get(i).remove(0); // Remove it.  
        // Lose a chance.  
        chances--;  
          
        // If no chances are left, it is a "Game Over!"  
        if (chances == 0) {  
          scene = 2;  
        }  
      }  
      else {  
        // If the circle is still behind the button, shift it.  
        circle.ShiftPosition();  
        circle.Draw();  
      }  
    }  
  }  
}  
  
// Spawns a circle.  
void spawnCircle () {  
  int lane = floor(random(lanePositions.length));  
  if (circles.get(lane).size() < maxCircles) { // Makes sure the lane is not overloaded.  
    Circle circle = new Circle(lane, circleFaceColor, circleBackColor);  
    circles.get(lane).add(circle);  
    circle.Draw();  
  }  
}  
  
// Increases the difficulty. (Circles spawn more and go faster.)  
void increaseDifficulty() {  
  spawnTime = max(spawnTime - 0.5f, minSpawnTime);  
  circleShiftRate = min(circleShiftRate + 0.2f, maxShiftRate);  
}  
  
// Resets the game. Empties the circles list and sets the game variables back to their initial values.  
void resetGame () {  
  circles = new CopyOnWriteArrayList<CopyOnWriteArrayList<Circle>>();  
  for (int i = 0; i < lanePositions.length; i++) {  
    circles.add(new CopyOnWriteArrayList<Circle>());  
  }  
  points = 0;  
  chances = maxChances;  
  circleShiftRate = minShiftRate;  
  spawnTime = maxSpawnTime;  
  lastSpawnMillis = 0;  
  lastDiffMillis = 0;  
}
