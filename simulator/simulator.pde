
float frame_rate = 60; // frame/sec
int start = millis();
int time = 0;
World world;
Ship ship;
Navigator navi;

float wing_efficiency = 0; 
float wing_good_time = 0;
float wing_bad_time = 0;

void settings(){
    //fullScreen();
   size(1200,720);
}

void setup() {
  frameRate(frame_rate);
  world = new World();
  ship = new Ship(-0.0005, -0.0002);
  navi = new Navigator();
}

void wing_evaluation()
{
    if(abs(ship.wing.angle) < 28)
      wing_bad_time ++;
    else
      wing_good_time++;
    wing_efficiency = wing_good_time / (wing_good_time + wing_bad_time) * 100;
}


void draw_info(Ship ship, Navigator navi, World world)
{
    stroke(32);
    fill(255);

    float space = 20;
    float x = width - 180;
    int idx = 8;
    textSize(16);
    textAlign(LEFT, CENTER);
    text("speed: " +acc_speed + "x", x, idx++*space); 
    text("ship bearing: " + int(ship.bearing) + "deg", x, idx++*space);
    text("ship speed: " + nf(ship.speed, 0, 1), x, idx++*space);
    text("wing angle: " + int(ship.wing.angle), x, idx++*space);
    text("wing effi: " + int(wing_efficiency) + '%', x, idx++*space);
    text("wind speed: " + nf(world.wind_speed, 0, 1) + "m/s", x, idx++*space);
    text("wind dir: " + int(world.wind_dir), x, idx++*space);
    text("cross_err: " + int(navi.crosstrack_dis), x, idx++*space);
    text("distance: " + int(navi.target_dis), x, idx++*space);
    
    text("ship lat: "+ nf((float)ship.loc.lat, 0, 5),  x, idx++*space);
    text("ship lon: "+ nf((float)ship.loc.lon, 0, 5), x, idx++*space);  
    
    text("Navi output: "+ nf(navi.rudder, 0, 3), x, idx++*space);
    text("Navi zigzag: "+ nf(navi.zigzag_side, 0, 0), x, idx++*space);
    text("Time: "+ time/1000, x, idx++*space);
     
}




int acc_speed = 1;
boolean is_paused = false;
void draw() {
    int i = acc_speed;
    
   if(is_paused)
      return;
    
    while(i-- != 0){
        world.update(1/frame_rate);
        navi.update(1/frame_rate, ship);
        ship.update(1/frame_rate, navi.rudder, world);
        
        // test
        wing_evaluation();
    }

    // draw
    background(60);
    stroke(32);
    fill(255);

    world.draw();
    navi.draw(ship, world);
    ship.draw(world);
    draw_info(ship, navi, world);

    if(navi.target_dis < 10)
    {
        navi.target_reached();
        //double lat, lon;
        //lat = navi.target.lat;
        //lon = navi.target.lon;
        //navi.set_target(navi.base.lat, navi.base.lon);
        ////navi.target.lat = navi.base.lat;
        ////navi.target.lon = navi.base.lon;
        //navi.base.lat = lat;
        //navi.base.lon = lon;
        //
        time = millis() - start;
        start = millis();
    }
}

void mousePressed(){
    
    //navi.base.lat = navi.target.lat;
    //navi.base.lon = navi.target.lon;
    double lat = world.pix2deg_x(mouseX);
    double lon = world.pix2deg_y(mouseY);
    
    if (mousePressed && (mouseButton == LEFT)) {
      //navi.set_target(lat, lon);
      navi.add_waypoint(lat, lon);
      
    } else if (mousePressed && (mouseButton == RIGHT)) {
     navi.target_reached(); 
    }
}

void keyPressed() {
    if (key == CODED) {
        if (keyCode == UP) {
            acc_speed *= 2;
            if(acc_speed >128)
                acc_speed =128;
        } else if (keyCode == DOWN) {
            acc_speed /= 2;
            if(acc_speed <= 0)
                acc_speed = 1;
        }
    } 
    else if(key == ' ')
    {
      if(is_paused)
        is_paused = false;
      else
        is_paused = true;
      print("pause\n");
    }
}
