
// earth radius. 
float R = 6371000.0;

class Coor {
  double lon;
  double lat;
  Coor(double latitude, double longitude){
    this.lon = longitude;
    this.lat = latitude;
  }
  
  Coor(Coor c){ 
    this.lon = c.lon;
    this.lat = c.lat;
  }
}


class World {
  double timestamp = 0;
  double timestamp_updated = 0;
  
  Coor coor_centre = new Coor(1,1);
  float world_width = 800; // the size of the world in metre = windows width
  
  Coor coor_min = new Coor(-1, -1);
  Coor coor_max = new Coor(1, 1);
  
  float wind_speed = 0;  // wind speed in m/s
  float wind_speed_init = 5; 
  float wind_guest = 1;  // wind guest in m/s
  float wind_dir = 135;    // wind direction from 0-360
  float wind_dir_random = 0; // rate of randomized wind direction drifting. 
  
  float current_speed = 0;  // current speed in m/s
  float current_speed_init = 0;
  float current_guest = 0;  // current guest in m/s
  float current_dir = 0;    // current direction from 0-360
  float current_dir_random = 0; // rate of randomized wind direction drifting. 
  
  ParticleSystem ps = new ParticleSystem(new PVector(width/2, 255));
  
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
    return deg2pix(deg - coor_centre.lon) + width/2;
  }
  double deg2pix_y(double deg){
    return -deg2pix(deg - coor_centre.lat) + height/2;// (width/world_width) is the scale factor. 
  }
  
  double pix2deg(int pix){
    return pix * 180/PI / R / width * world_width;
  }
  double pix2deg_x(int pix){
    return pix2deg(pix - width/2) + coor_centre.lon;
  }
  double pix2deg_y(int pix){
    return -pix2deg(pix - height/2)  + coor_centre.lat;
  }
   

  void update(float step){
    // only update every second. 
    timestamp += step;
    if(timestamp <= timestamp_updated +1)
       return;
    timestamp_updated = timestamp;
    
    wind_speed = wind_speed_init + random(-wind_guest, wind_guest);
    wind_dir += random(-wind_dir_random, wind_dir_random);
    wind_dir = (float)get_bearing(wind_dir);
    current_speed = current_speed_init + random(-current_guest, current_guest);
    current_dir += random(-current_dir_random, current_dir_random);
    current_dir = (float)get_bearing(current_dir);
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
          fill(128);
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
          fill(128);
          textAlign(LEFT, CENTER);
          text(round(-mark) + "m", width/2, y);
        }
        tick++;
    }
  }
  
  AngleFilter filter = new AngleFilter(0.98);
  void draw_current()
  {
    float rotate = wind_dir;
    rotate = (float)filter.update_deg((float)rotate);
    
    pushMatrix();
    translate(width-60, 60);
    rotate((rotate+180) / 180 * PI);
    fill(255, 255, 255);
    beginShape();
    vertex(-10.0, -10.0);
    vertex(0, 20);
    vertex(10, -10);
    vertex(0, 0);
    endShape(CLOSE);
    popMatrix();
    textAlign(CENTER, CENTER);
    textSize(14);
    text("Wind " + (int)(wind_dir) + "deg", width-60, 90);
    text("Speed " + (int)(wind_speed) + "m/s", width-60, 110);
  }
  
  void draw_compass()
  {
    float x = width-180;
    float y = 70;
    float space = 40;
    float space2 = 20;
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

  
  void draw(float acc){
    draw_grid();
    draw_current();
    draw_compass();
    //for( int i=0; i<acc; i++)
    //{
    //  ps.addParticle(new PVector(random(0, width), random(0, height)), 
    //    (float)m2pix(wind_speed/frame_rate*acc), wind_dir, 10000.0/acc, color(255, 255, 255));
    //}
    ps.addParticle(new PVector(random(0, width), random(0, height)), 
        (float)m2pix(wind_speed/frame_rate), wind_dir, 1000, color(255, 255, 255));
    ps.run();
  }
}
