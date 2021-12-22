
// earth radius. 
float R = 6371000.0;

class Coor {
  double lon;
  double lat;
  Coor(double latitude, double longitude){
    this.lon = longitude;
    this.lat = latitude;
  }
}


class World {
  double timestamp = 0;
  double timestamp_updated = 0;
  
  Coor coor_centre = new Coor(0, 0);
  float world_width = 200; // the size of the world in metre = windows width
  
  Coor coor_min = new Coor(-1, -1);
  Coor coor_max = new Coor(1, 1);
  
  float wind_speed = 5;  // wind speed in m/s
  float wind_speed_init = 5; 
  float wind_guest = 0;  // wind guest in m/s
  float wind_dir = 135;    // wind direction from 0-360
  float wind_dir_random = 0; // rate of randomized wind direction drifting. 
  
  float current_speed = 0;  // current speed in m/s
  float current_speed_init = 0;
  float current_guest = 0;  // current guest in m/s
  float current_dir = 0;    // current direction from 0-360
  float current_dir_random = 0; // rate of randomized wind direction drifting. 
  
  ParticleSystem ps = new ParticleSystem(new PVector(width/2, 50));
  
  World(){
    // use windows size and the ranges to 
    coor_min.lon = coor_centre.lon - (world_width/2.0/R) *180/PI *((float)height/width);
    coor_max.lon = coor_centre.lon + (world_width/2.0/R) *180/PI *((float)height/width);
    coor_min.lat = coor_centre.lat - (world_width/2.0/R) *180/PI;
    coor_max.lat = coor_centre.lat + (world_width/2.0/R) *180/PI;
  }
  
  // no offset version 
  double m2pix(double m){
    return m * width / world_width;
  }
  double deg2pix(double deg){
    return deg /180*PI * R * width / world_width;
  }
  
  // offset versions
  double m2pix_x(double m){
    return m * width / world_width + width/2;
  }
  double m2pix_y(double m){
    return -m * width / world_width + height/2; // (width/world_width) is the scale factor. screen y is inverted. 
  }
  double deg2pix_x(double deg){
    return deg2pix(deg) + width/2;
  }
  double deg2pix_y(double deg){
    return -deg2pix(deg) + height/2;// (width/world_width) is the scale factor. 
  }
  
  double pix2deg(int pix){
    return pix * 180/PI / R / width * world_width;
  }
  double pix2deg_x(int pix){
    return pix2deg(pix - width/2);
  }
  double pix2deg_y(int pix){
    return -pix2deg(pix - height/2);
  }
  
 

  void update(float step){
    // only update every second. 
    timestamp += step;
    if(timestamp <= timestamp_updated +1)
       return;
    timestamp_updated = timestamp;
    
    wind_speed = wind_speed_init + random(-wind_guest, wind_guest);
    wind_dir += random(-wind_dir_random, wind_dir_random);
    current_speed = current_speed_init + random(-current_guest, current_guest);
    current_dir += random(-current_dir_random, current_dir_random);
  }
  
  void draw_grid(){
    float step = world_width/20;// 10 m
    float space = step / world_width*width; // 10m/box. 
    int tick;
    
    textSize(12);
    stroke(32);
    tick = 0;
    for (float x = 0; x < width; x += space){
        line(x, 0, x, height);
        float mark = -world_width/2 + tick * step;
        if(x>0 && x < width - 3*space)  {
          textAlign(CENTER, TOP);
          text(round(mark) + "m", x, height/2);
        }
        tick++;
    }
    tick = 0;
    for (float y = 0; y < height; y += space) {
        line(0, y, width, y);
        float mark = -world_width/2 * ((float)height/width) + tick * step;
        
        if(y>0 && y < height){
          textAlign(LEFT, CENTER);
          text(round(-mark) + "m", width/2, y);
        }
        tick++;
    }
  }
  
  void draw_current()
  {
    pushMatrix();
    translate(width-50, 50);
    rotate((wind_dir+180) / 180 * PI);
    fill(255, 255, 255);
    beginShape();
    vertex(-10.0, -10.0);
    vertex(0, 20);
    vertex(10, -10);
    vertex(0, 0);
    endShape(CLOSE);
    popMatrix();
    textAlign(CENTER, CENTER);
    textSize(16);
    text("Wind " + (int)(wind_dir), width-50, 70);
  }
  
  void draw_compass()
  {
    float x = width-150;
    float y = 70;
    float space = 40;
    float space2 = 25;
    pushMatrix();
    
    stroke(200);
    line(x-space2, y, x+space2, y);
    line(x, y+space2, x, y-space2);
    
    textSize(12);
    textAlign(CENTER, CENTER);
    text("N\n0" , x, y-space);
    text("90 E", x+space, y);
    text("180\nS", x, y+space);
    text("W 270", x-space, y);
    popMatrix();
  }

  
  void draw(){
    draw_grid();
    draw_current();
    draw_compass();
    ps.addParticle(new PVector(random(0, width), random(0, height)), (float)m2pix(wind_speed/frame_rate), wind_dir, color(255, 255, 255));
    ps.run();
  }
}
