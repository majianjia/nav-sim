// A simple Particle class

class Particle {
  PVector position;
  PVector velocity;
  float lifespan;
  color linecolor;

  Particle(PVector l, float speed, float bearing) {
    float x = -sin((bearing) / 180 * PI)*speed;
    float y = cos((bearing) / 180 * PI)*speed;
    velocity = new PVector(x, y);
    position = l.copy();
    lifespan = 500.0;
    linecolor = 255;
  }
  
  Particle(PVector l, float speed, float bearing, color c) {
    float x = -sin((bearing) / 180 * PI)*speed;
    float y = cos((bearing) / 180 * PI)*speed;
    velocity = new PVector(x, y);
    position = l.copy();
    lifespan = 255.0;
    linecolor = c;
  }


  void run() {
    update();
    display();
  }

  // Method to update position
  void update() {
    //velocity.add(acceleration);
    position.add(velocity);
    lifespan -= 1.0;
  }

  // Method to display
  void display() {
    stroke(linecolor, lifespan);
    fill(linecolor, lifespan);
    line(position.x, position.y, position.x+velocity.x*10, position.y+velocity.y*10);
  }

  // Is the particle still useful?
  boolean isDead() {
    if (lifespan < 0.0) {
      return true;
    } else {
      return false;
    }
  }
}
