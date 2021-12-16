

float ship_bearing = 180;
float ship_speed = 1.2;
float ship_rotate_speed = 2;
float ship_x = 50;
float ship_y = 100;

float max_current_speed  = 2;
float current_speed = max_current_speed;
float current_direct = 90;

float current_direct_noise = 1;
float current_speed_noise = 1; 

float target_distance = 0;
float crosstrack_err = 0;

boolean is_critical_bearing = false;
float freezed_correction = 0;

// navi
float path_width = 50; 
float target_x = 500, target_y = 300;
float base_x = 100, base_y = 300;

float ship_base_x = ship_x, ship_base_y = ship_y; // temporary based point when distance from ship is too far from track (2x pathwidth.)
float intcpt_target_x, intcpt_target_y;
boolean is_ship_base_locked = false;


// sail
float sail_cl = 0.5; // lift to drag coefficient. 
float sail_bearing = 0; // absolute sail bearing. 
float sail_relative_angle = 0; // relative angle to the ship
float sail_aoa = 10; // sail angle of attack
float sail_speed = 0;

float zigzag_side = 1;

ParticleSystem ps;

void settings(){
    //fullScreen();
   size(1000,600);
}

void setup() {
    ps = new ParticleSystem(new PVector(width/2, 50));
}

float limit(float value, float max, float min)
{
    if(value < min)
        return min;
    if(value >max)
        return max;
    return value;
}
float current_speed_rand = 1;
void noise(){
    //current_speed  += random(-current_direct_noise, current_direct_noise);  
    current_speed_rand += random(0, 0.1);
    //current_speed = sin(radians(current_speed_rand)) * max_current_speed;
    //current_direct += random(-current_speed_noise, current_speed_noise);  
}

// output angle to range -180 to 180
float angle_corr(float diff)
{
   if(diff < -180)
     diff += 360;
   else if(diff >=180)
     diff -= 360;
   return diff;
}

float nav(){
    float ship_rotate = 0;
    float ship_angle = atan2(ship_x-target_x, ship_y-target_y);
    ship_angle = -ship_angle * 180/PI;

    float track_angle = atan2(base_x-target_x, base_y-target_y);
    track_angle = -track_angle * 180/PI;
    
    // test, avoid heading wind. 
    float head_wind_offset = 0;
    float relative_angle = sail_bearing - (ship_bearing - 180);
    sail_relative_angle = angle_corr(relative_angle);
    
    // head wind
    if(abs(sail_relative_angle) > 150)
    {
      // convert it back 
      sail_relative_angle = angle_corr(180 - sail_relative_angle);
    }
        
    float offset_angle = angle_corr(track_angle - ship_angle);
    //print("off", int(offset_angle), "track:", int(track_angle), "ship", int(ship_angle), "\n");

    // calculate the distance between ship and 
    target_distance = sqrt((ship_x-target_x)*(ship_x-target_x)+(ship_y-target_y)*(ship_y-target_y));
    crosstrack_err = sin(radians(offset_angle)) * target_distance;
    
    // when ship is too far from path, add an temporary target where intercept with the path
    if(crosstrack_err > path_width *2 && is_ship_base_locked == false)
    {
      is_ship_base_locked = true;
      ship_base_x = ship_x;
      ship_base_y = ship_y;
      
      //
      intcpt_target_x = ship_base_x + crosstrack_err * sin(track_angle);
      intcpt_target_y = ship_base_y + crosstrack_err * cos(track_angle);
      
      print(ship_base_x, ship_base_y, intcpt_target_x, intcpt_target_y, '\n');
    
    }
    if(crosstrack_err < path_width)
    {
      is_ship_base_locked = false;
    }
    

    // change zigzag side. when distance too far or already close to target.
    if(abs(crosstrack_err) >= path_width || abs(crosstrack_err) >= target_distance*0.3)
    {
      if(crosstrack_err >0)// && zigzag_side == 1) 
        zigzag_side = -1;
      else if(crosstrack_err <0)// && zigzag_side == -1)
        zigzag_side = 1;
    }
    
    if(abs(sail_relative_angle) < 30)
    {
      float a = (60 - abs(sail_relative_angle)) + (45 - abs(offset_angle)); // why this is 45
      head_wind_offset = zigzag_side * (a);
      print("head wind",  sail_relative_angle, head_wind_offset, zigzag_side, offset_angle, '\n');
    }
    else{
      head_wind_offset = 0;
    }
      
    // if headwind, we ignore the cross track error because we are doing zigzaging
    if(abs(crosstrack_err) < path_width && head_wind_offset != 0)
    {
      crosstrack_err = 0;
    }
    
    float correction = 0;
    
    // avoid over shooting when go back to track when track is far away
    float lim_angle = 70;
    if(abs(offset_angle) <= lim_angle)
    {
        lim_angle = lim_angle - abs(offset_angle); // this lim angle is perpendicular to the track
        crosstrack_err = limit(crosstrack_err, lim_angle, -lim_angle); // limit the range. 
        correction += -(crosstrack_err * 1);
        correction = angle_corr(correction);
    }
    // when the ship is behine the track
    // do not do crosstrack correction, not going to the track but to the target directly. 
    else 
    {}

    correction += ship_angle - (ship_bearing - 180);  // use track angle?
    correction = angle_corr(correction);
    correction += head_wind_offset; 
    //correction = angle_corr(correction);

    // avoid oscillation, when angle >90, free the correction until it turns. 
    if(abs(correction) > 90)
    {
        if(!is_critical_bearing)
        {
            is_critical_bearing = true;
             freezed_correction = correction; 
        }
        correction = freezed_correction;
    }
    else 
        is_critical_bearing = false;
        
    if(correction > 0)
        ship_rotate += ship_rotate_speed;
    else if (correction < 0){
        ship_rotate -= ship_rotate_speed;
    }    
    //print("correction", correction,"shipangle:", ship_angle, "ship bearing", ship_bearing, "distance", target_distance,"cross", crosstrack_err, "\n");
    
    return ship_rotate;
}

void sail_model()
{
    // calculate the sail angle to the ship
    float vx = cos((ship_bearing) / 180 * PI)*ship_speed - cos((current_direct) / 180 * PI)*current_speed; // inverted current flow
    float vy = sin((ship_bearing) / 180 * PI)*ship_speed - sin((current_direct) / 180 * PI)*current_speed; 
    float v_sail = sqrt(vx*vx + vy*vy);
    float angle = atan2(vy, vx)*180/PI;
    sail_bearing = angle;
    sail_speed = v_sail;
    
    //print("vsail", v_sail, "sail", int(angle), "\n");
}

float turn_momenten = 0;
void ship_model(float turn)
{
    // ship bearing
    turn_momenten = turn_momenten*0.8 + turn*0.2; // filter
    ship_bearing += turn_momenten*sqrt(ship_speed); // simulate the turning effectiveness, the faster you turn, larger radius
    if(ship_bearing < 0)
        ship_bearing += 360;
    else if(ship_bearing >=360)
        ship_bearing -= 360;
        
    // calculate ship speed according to sail
    float lift =  sail_speed * sail_cl;
    float forward = sin((sail_bearing-ship_bearing) / 180 * PI) * lift;
    ship_speed = max(abs(forward), 0.1) * 0.1+ ship_speed*0.9;

    // ship move
    ship_x += -sin((ship_bearing) / 180 * PI)*ship_speed;
    ship_y += cos((ship_bearing) / 180 * PI)*ship_speed;
    
    ship_x += -sin((current_direct) / 180 * PI)*current_speed * 0.1;  // drift by wind
    ship_y += cos((current_direct) / 180 * PI)*current_speed * 0.1; 
     
    ship_x = min(max(ship_x, 0), width);
    ship_y = min(max(ship_y, 0), height);
}

void draw_ship(){
    stroke(32);
    // draw
    pushMatrix();
    translate(ship_x, ship_y);
    rotate((ship_bearing) / 180 * PI);
    ps.addParticle(new PVector(ship_x, ship_y), 0, 0, color(0,255,255)); // draw path
    
    // ship
    beginShape();    
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
    line(0,0, 0, 50*ship_speed);
    popMatrix();
     
    // sail
    pushMatrix();
    translate(ship_x, ship_y);
    rotate((sail_bearing) / 180 * PI);
    // sail colour
    stroke(255, 128, 128);
    fill(255, 0, 0);
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
    line(0,0, 0, 50*sail_speed);
    popMatrix();
    
    //print(sail_bearing, ship_bearing);
}
void grid(){
    int space = 50;
    for (int x = 0; x  < width; x += space){
        line(x, 0, x, height);
    }
    for (int y = 0; y < height; y += space) {
        line(0, y, width, y);
    }
}


void draw_current()
{
    pushMatrix();
    translate(width-50, 50);
    rotate((current_direct+180) / 180 * PI);
    fill(255, 255, 255);
    beginShape();
    vertex(-10.0, -10.0);
    vertex(0, 20);
    vertex(10, -10);
    vertex(0, 0);
    endShape(CLOSE);
    popMatrix();
}

void draw_info()
{
    stroke(32);
    fill(255);

    float space = 30;
    int idx = 3;
    textSize(20);
    text("speed:" +acc_speed + "x", width - 200, idx++*space); 
    text("bearing:" + int(ship_bearing) + "deg", width - 200, idx++*space);
    text("sail be:" + int(sail_bearing), width - 200, idx++*space);
    text("curr be:" + int(current_direct), width - 200, idx++*space);
    text("cross_err:" + int(crosstrack_err), width - 200, idx++*space);
    text("distance:" + int(target_distance), width - 200, idx++*space);
    text("curr_speed:" + current_speed , width - 200, idx++*space);
    text("curr_dir:" + int(current_direct), width - 200, idx++*space);
    text("ship_v:" + ship_speed, width - 200, idx++*space);
}


void draw_target(float x, float y, float size)
{
    pushMatrix();
    circle(x, y, size);
    popMatrix();
}

void draw_path()
{
  stroke(32);
  draw_target(base_x, base_y, 10);
  draw_target(target_x, target_y, 20);
  stroke(0, 255, 255);
  line(target_x, target_y, ship_x, ship_y);
  
  stroke(255, 128, 128);
  line(base_x, base_y, target_x, target_y);
  stroke(32);

  
  float x1, y1, x2, y2, ang, clen, slen;
  x1 = base_x;
  y1 = base_y;
  x2 = target_x;
  y2 = target_y;
  ang = -atan2(y2-y1, x2-x1); // why this is negative?
  clen = cos(ang)*path_width;
  slen = sin(ang)*path_width;
  // draw 

  stroke(192, 96, 96);
  line(x1+slen, y1+clen, x2+slen, y2+clen);
  line(x1-slen, y1-clen, x2-slen, y2-clen);
  
  stroke(253, 22, 92);
  line(ship_base_x, ship_base_y, intcpt_target_x, intcpt_target_y);

}

int acc_speed = 1;
void draw() {
    int i = acc_speed;
    while(i-- != 0)
    {
        noise();
        float rot = nav();
        ship_model(rot);
        sail_model();
    
        // draw
        background(100);
        stroke(32);
        fill(255);
        grid();  
        draw_current();
        draw_path();
        draw_ship();
        draw_info();
        // update position
        
        ps.addParticle(new PVector(random(0, width), random(0,height)), current_speed, current_direct);
        ps.run();
    }

    if(target_distance < 10)
    {
        float x, y;
        x = target_x;
        y = target_y;
        target_x = base_x;
        target_y = base_y;
        base_x = x;
        base_y = y;
    }
}

void mousePressed(){
    base_x = target_x;
    base_y = target_y;

    target_x = mouseX;
    target_y = mouseY;
}

void keyPressed() {
    if (key == CODED) {
        if (keyCode == UP) {
            acc_speed += 1;
            if(acc_speed >16)
                acc_speed =16;
        } else if (keyCode == DOWN) {
            acc_speed -= 1;
            if(acc_speed <= 0)
                acc_speed = 1;
        }
    } 
    else if(key == ' ')
    {
      if(acc_speed == 0)
        acc_speed = 1;
      else
        acc_speed = 0;
      print("pause\n");
    }
}
