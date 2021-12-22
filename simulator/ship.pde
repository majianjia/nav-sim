

float angle_corr(float ang)
{
  ang = ang % 360;
   if(ang <= -180)
     ang += 360;
   else if (ang >= 180)
     ang -= 360;
  return ang;
}

class Wing {
  float cl = 0.5;         // lift to drag coefficient. 
  float angle = 0;  // relative angle to the ship
  float aoa = 10;       // sail angle of attack
  float speed = 0;      // relative speed to air. 
  
  float lift;          // lift generated from the wing, perpendicular to the  direction
  float drag;          // not using it yet. 
 
  
  void update(float step, Ship ship, World world)
  {
      // calculate the sail angle to the ship
      float vx = cos((ship.bearing) / 180 * PI)*ship.speed - cos((world.wind_dir - 180) / 180 * PI)*world.wind_speed; // inverted current flow
      float vy = sin((ship.bearing) / 180 * PI)*ship.speed - sin((world.wind_dir - 180) / 180 * PI)*world.wind_speed; 
      float v = sqrt(vx*vx + vy*vy);
      angle = atan2(vy, vx)*180/PI - ship.bearing;
      angle = angle_corr(angle); // convert it back to -180 to 180
      speed = v;
      lift = speed * cl; // simple linear test 
      //print("v", v, "angle", int(angle), "\n");
  }
}

class Ship {
  Coor loc = new Coor(0, 0);

  // ship
  float speed = 0;        // speed in m/s
  float speed_momentum = 0.9; // speed momentum
  float speed_min= 0.5; // speed momentum
  float bearing = 0;      // 0-360 degree
  float rudder_cof = 2;   // rudder coefficient 
  float turn_momentum = 0; //
  float turn_momentum_filter = 0.9; //
  
  // wings
  Wing wing = new Wing();
  
  // for the path. 
  ParticleSystem ps = new ParticleSystem(new PVector(width/2, 255));

  Ship(){ }
  Ship(float lat, float lon){
    loc.lat = lat;
    loc.lon = lon;
  }
  
  void update(float step, float rudder, World world){
    // ship bearing
    turn_momentum = turn_momentum*turn_momentum_filter + rudder*(1-turn_momentum_filter); // filter
    bearing += turn_momentum;//*sqrt(speed); // simulate the turning effectiveness, the faster you turn, larger radius
    if(bearing < 0)
        bearing += 360;
    else if(bearing >=360)
        bearing -= 360;
    
    // update wings
    wing.update(step, this, world); // use ship current state to update wings status
    
    // calculate ship speed according to wing
    float forward = abs(sin((wing.angle) / 180 * PI) * wing.lift); // we change the direction to allow force to face forward. 
    speed = max(abs(forward), speed_min) * (1-speed_momentum)+ speed*speed_momentum;

    // ship move
    loc.lat += Math.sin((bearing) / 180 * PI) * speed / R * 180/PI * step ; // also consider the step.
    loc.lon += Math.cos((bearing) / 180 * PI) * speed / R * 180/PI * step;
    
    loc.lat -= Math.sin((world.wind_dir) / 180 * PI)*speed * 0.2 / R * 180/PI * step;  // drift by wind, test only
    loc.lon -= Math.cos((world.wind_dir) / 180 * PI)*speed * 0.2 / R * 180/PI * step; 
     
    loc.lon = Math.min(Math.max(loc.lon, world.coor_min.lon), world.coor_max.lon);
    loc.lat = Math.min(Math.max(loc.lat, world.coor_min.lat), world.coor_max.lat);
  }
  
  void draw(World world){
    // translate
    float ship_x = (float)world.deg2pix_x(loc.lat);
    float ship_y = (float)world.deg2pix_y(loc.lon);
    
    ps.addParticle(new PVector(ship_x, ship_y), 0, 0, color(255,128,255)); // draw path
    ps.run();
    
    stroke(32);
    // draw
    pushMatrix();
    translate(ship_x, ship_y);
    rotate((bearing + 180) / 180 * PI); // 
    
    // ship
    beginShape();   
    fill(255);
    vertex(0, 30.0);  // left front
    vertex(5.0, 10.0);
    vertex(6.0, 0.0);
    vertex(6.0, -15.0);
    vertex(3.0, -30.0);
    vertex(-3.0, -30.0); // right
    vertex(-6.0, -15.0);
    vertex(-6.0, 0.0);
    vertex(-5.0, 10.0);
    endShape(CLOSE);
    stroke(255, 255, 0);
    line(0,0, 0, 10*speed);
    popMatrix();
     
    // wing
    pushMatrix();
    translate(ship_x, ship_y);
    rotate((wing.angle + bearing + 180) / 180 * PI);
    // sail colour
    
    if(abs(wing.angle) < 30 || abs(wing.angle)>150){
      stroke(255, 128, 128);
      fill(255, 0, 0);
    }
    else{
      stroke(128, 255, 128);
      fill(0, 200, 0);
    }
    beginShape();    
    vertex(0, 15.0);  // left front
    vertex(1.0, 10.0);
    vertex(2.0, 0.0);
    vertex(0.0, -15.0);
    vertex(-2.0, 0.0);  // right
    vertex(-1.0, 10.0); 
    endShape(CLOSE);
    //
    stroke(255, 0, 200);
    line(0,0, 0, 10*wing.speed);
    popMatrix();
    
    //print(bearing, wing.angle, "\n");
  }
  

}
