import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class simulator extends PApplet {


float frame_rate = 60; // frame/sec
int start = millis();
int time = 0;
World world;
Ship ship;
Navigator navi;

float wing_efficiency = 0; 
float wing_good_time = 0;
float wing_bad_time = 0;

public void settings(){
    //fullScreen();
   size(1200,720);
}

public void setup() {
  frameRate(frame_rate);
  world = new World();
  ship = new Ship(world.coor_centre.lat, world.coor_centre.lon);
  navi = new Navigator();
}

public void wing_evaluation()
{
    if(abs(ship.wing.angle) < 28)
      wing_bad_time ++;
    else
      wing_good_time++;
    wing_efficiency = wing_good_time / (wing_good_time + wing_bad_time) * 100;
}


public void draw_info(Ship ship, Navigator navi, World world)
{
    stroke(32);
    fill(255);

    float space = 20;
    float x = width - 180;
    int idx = 8;
    textSize(16);
    textAlign(LEFT, CENTER);
    text("speed: " +acc_speed + "x", x, idx++*space); 
    text("ship bearing: " + PApplet.parseInt(ship.bearing) + "deg", x, idx++*space);
    text("target bearing: " + PApplet.parseInt(navi.bearing) + "deg", x, idx++*space);
    text("ship speed: " + nf(ship.speed, 0, 1), x, idx++*space);
    text("wing angle: " + PApplet.parseInt(ship.wing.angle), x, idx++*space);
    text("wing effi: " + PApplet.parseInt(wing_efficiency) + '%', x, idx++*space);
    text("wind speed: " + nf(world.wind_speed, 0, 1) + "m/s", x, idx++*space);
    text("wind dir: " + PApplet.parseInt(world.wind_dir), x, idx++*space);
    text("cross_err: " + PApplet.parseInt(navi.crosstrack_dis), x, idx++*space);
    text("distance: " + PApplet.parseInt(navi.target_dis), x, idx++*space);
    
    text("ship lat: "+ nf((float)ship.loc.lat, 0, 5),  x, idx++*space);
    text("ship lon: "+ nf((float)ship.loc.lon, 0, 5), x, idx++*space);  
    
    text("Navi output: "+ nf(navi.rudder, 0, 3), x, idx++*space);
    text("Navi zigzag: "+ nf(navi.zigzag_side, 0, 0), x, idx++*space);
    text("Time: "+ time/1000, x, idx++*space);
     
}




int acc_speed = 1;
boolean is_paused = false;
public void draw() {
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

    world.draw(acc_speed);
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

public void mousePressed(){
    
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

public void keyPressed() {
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
// A simple Particle class

class Particle {
  PVector position;
  PVector velocity;
  float lifespan;
  int linecolor;
  float step;

  Particle(PVector l, float speed, float bearing) {
    float x = -sin((bearing) / 180 * PI)*speed;
    float y = cos((bearing) / 180 * PI)*speed;
    velocity = new PVector(x, y);
    position = l.copy();
    lifespan = 500.0f;
    linecolor = 255;
    step = 1.0f;
  }
  
  Particle(PVector l, float speed, float bearing, float life, int c) {
    float x = -sin((bearing) / 180 * PI)*speed;
    float y = cos((bearing) / 180 * PI)*speed;
    velocity = new PVector(x, y);
    position = l.copy();
    lifespan = life;
    linecolor = c;
    step = 10000.0f/life;
  }


  public void run() {
    update();
    display();
  }

  // Method to update position
  public void update() {
    //velocity.add(acceleration);
    position.add(velocity);
    lifespan -= step;
  }

  // Method to display
  public void display() {
    stroke(linecolor, lifespan);
    fill(linecolor, lifespan);
    //stroke(linecolor, 200);
    //fill(linecolor, 200);
    line(position.x, position.y, position.x+velocity.x*10, position.y+velocity.y*10);
  }

  // Is the particle still useful?
  public boolean isDead() {
    if (lifespan < 0.0f) {
      return true;
    } else {
      return false;
    }
  }
}
// A class to describe a group of Particles
// An ArrayList is used to manage the list of Particles 

class ParticleSystem {
  ArrayList<Particle> particles;
  PVector origin;

  ParticleSystem(PVector position) {
    origin = position.copy();
    particles = new ArrayList<Particle>();
  }

  public void addParticle(PVector location, float speed, float bearing) {
    particles.add(new Particle(location, speed, bearing));
  }
  
    public void addParticle(PVector location, float speed, float bearing, float life, int c) {
    particles.add(new Particle(location, speed, bearing, life, c));
  }

  public void run() {
    for (int i = particles.size()-1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.run();
      if (p.isDead()) {
        particles.remove(i);
      }
    }
  }
}
 


// REF: https://www.movable-type.co.uk/scripts/latlong.html
// haversine method
// a = sin²(Δφ/2) + cos φ1 ⋅ cos φ2 ⋅ sin²(Δλ/2)
// return angular distance, value x R = real distance
public double get_rad_distance(Coor p1, Coor p2)
{
    double lat1 = p1.lat * PI/180;
    double lat2 = p2.lat * PI/180;
    double delta_lat = (p2.lat - p1.lat) * PI/180;
    double delta_lon = (p2.lon - p1.lon) * PI/180;
    double a, dist;
    a = Math.sin(delta_lat/2) * Math.sin(delta_lat/2)
            + Math.cos(lat1)* Math.cos(lat2) * Math.sin(delta_lon/2) * Math.sin(delta_lon/2);
    dist = 2*Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return dist;
}

public double get_distance(Coor p1, Coor p2)
{
    return get_rad_distance(p1, p2)*R;
}

// get the angle between 2 coordinate.
// return θ ranges from -180 to 180, and faces north for 0 degree.
public double get_theta(Coor p1, Coor p2)
{
    double lat1 = p1.lat * PI/180;
    double lat2 = p2.lat * PI/180;
    double lon1 = p1.lon * PI/180;
    double lon2 = p2.lon * PI/180;
    double x, y, theta;
    y = Math.sin(lon2-lon1) * Math.cos(lat2);
    x = Math.cos(lat1)*Math.sin(lat2) - Math.sin(lat1)*Math.cos(lat2)*Math.cos(lon2-lon1);
    theta = Math.atan2(x, y) * 180/PI; // reverse to get north direction as 0.
    return theta;
}
// to cover theta to bearing
// bearing = (θ + 360) % 360; // in degrees
public double get_bearing(double theta)
{
    return  (theta + 360 ) % 360.0f;
}

// convert angel to +- 180 range
public double get_direction(double theta)
{
    return -(theta + 180) % 180.0f;
}

// p1 = start, p2=end, curr = current point
// negative means the current location is on the left side of the path.
public double get_cross_track(Coor p1, Coor  p2, Coor curr)
{
   double dist = 0;
   double a13 = get_rad_distance(p1, curr);                 // angular distance
   double theta13 = get_theta(p1, curr) * PI / 180;   // start to current.
   double theta12 = get_theta(p1, p2) * PI / 180;     // start to end.
   dist = Math.asin(Math.sin(a13)* Math.sin(theta13- theta12));
   return dist;
}

public double get_cross_track_distance(Coor p1, Coor  p2, Coor curr)
{
    return get_cross_track(p1, p2, curr) * R;
}

/**
 * Returns the point of intersection of two paths defined by point and bearing.
 *
 *  note –   
 *  if sin α1 = 0 and sin α2 = 0: infinite solutions
 *  if sin α1 ⋅ sin α2 < 0: ambiguous solution
 *  this formulation is not always well-conditioned for meridional or equatorial lines
 *
 * @param   {LatLon}      p1 - First point.
 * @param   {number}      brng1 - Initial bearing from first point.
 * @param   {LatLon}      p2 - Second point.
 * @param   {number}      brng2 - Initial bearing from second point.
 * @returns {LatLon|null} Destination point (null if no unique intersection defined).
 *
 * @example
 *   const p1 = new LatLon(51.8853, 0.2545), brng1 = 108.547;
 *   const p2 = new LatLon(49.0034, 2.5735), brng2 =  32.435;
 *   const pInt = LatLon.intersection(p1, brng1, p2, brng2); // 50.9078°N, 004.5084°E
 */
public Coor intersection(Coor p1, double bearing1, Coor p2, double bearing2) {
    // δ: Delta
    // φ: Phi
    // λ: lambda
    // θ: theta
    // α: alpha
    // Δ: d_
  
    double phi1 = p1.lat * Math.PI / 180;
    double lambda1 = p1.lon * Math.PI / 180;
    double phi2 = p2.lat * Math.PI / 180;
    double lambda2 = p2.lon * Math.PI / 180;;
    double theta13 = bearing1 * Math.PI / 180;
    double theta23 = bearing2 * Math.PI / 180;
    double d_phi = phi2 - phi1;
    double d_lambda = lambda2 - lambda1;

    // angular distance p1-p2
    double delta12 = 2 * Math.asin(Math.sqrt(Math.sin(d_phi/2) * Math.sin(d_phi/2)
        + Math.cos(phi1) * Math.cos(phi2) * Math.sin(d_lambda/2) * Math.sin(d_lambda/2)));
    if (Math.abs(delta12) < EPSILON*0.001f) // even EPSILON is not small enough
      return p1; // coincident points

    // initial/final bearings between points
    double cos_theta_a = (Math.sin(phi2) - Math.sin(phi1)*Math.cos(delta12)) / (Math.sin(delta12)*Math.cos(phi1));
    double cos_theta_b = (Math.sin(phi1) - Math.sin(phi2)*Math.cos(delta12)) / (Math.sin(delta12)*Math.cos(phi2));
    double theta_a = Math.acos(Math.min(Math.max(cos_theta_a, -1), 1)); // protect against rounding errors
    double theta_b = Math.acos(Math.min(Math.max(cos_theta_b, -1), 1)); // protect against rounding errors
    double theta12 = Math.sin(lambda2-lambda1)>0 ? theta_a : 2*PI-theta_a;
    double theta21 = Math.sin(lambda2-lambda1)>0 ? 2*PI-theta_b : theta_b;
    double alpha1 = theta13 - theta12; // angle 2-1-3
    double alpha2 = theta21 - theta23; // angle 1-2-3

    if (Math.sin(alpha1) == 0 && Math.sin(alpha2) == 0) return p1; // infinite intersections
    if (Math.sin(alpha1) * Math.sin(alpha2) < 0) return p1;        // ambiguous intersection (antipodal/360°)

    double cosalpha3 = -Math.cos(alpha1)*Math.cos(alpha2) + Math.sin(alpha1)*Math.sin(alpha2)*Math.cos(delta12);
    double delta13 = Math.atan2(Math.sin(delta12)*Math.sin(alpha1)*Math.sin(alpha2), Math.cos(alpha2) + Math.cos(alpha1)*cosalpha3);
    double phi3 = Math.asin(Math.min(Math.max(Math.sin(phi1)*Math.cos(delta13) + Math.cos(phi1)*Math.sin(delta13)*Math.cos(theta13), -1), 1));
    double d_lambda13 = Math.atan2(Math.sin(theta13)*Math.sin(delta13)*Math.cos(phi1), Math.cos(delta13) - Math.sin(phi1)*Math.sin(phi3));
    double lambda3 = lambda1 + d_lambda13;
    double lat = phi3 * 180/Math.PI;
    double lon = lambda3 *180/Math.PI;
    return new Coor(lat, lon);
}



/**
 * Returns the point at given fraction between ‘this’ point and given point.
 *
 * @param   {LatLon} point - Latitude/longitude of destination point.
 * @param   {number} fraction - Fraction between the two points (0 = this point, 1 = specified point).
 * @returns {LatLon} Intermediate point between this point and destination point.
 *
 * @example
 *   const p1 = new LatLon(52.205, 0.119);
 *   const p2 = new LatLon(48.857, 2.351);
 *   const pInt = p1.intermediatePointTo(p2, 0.25); // 51.3721°N, 000.7073°E
 */
public Coor intermediate_point(Coor psrc, Coor pdes, double fraction) {
    // δ: Delta
    // φ: Phi
    // λ: lambda
    // θ: theta
    // α: alpha
    // Δ: d_
  
    double phi1 = psrc.lat /180 * Math.PI;
    double lambda1 = psrc.lon /180 * Math.PI;
    double phi2 = pdes.lat /180 * Math.PI;
    double lambda2 = pdes.lon /180 * Math.PI;

    // distance between points
    double d_phi = phi2 - phi1;
    double d_lambda = lambda2 - lambda1;
    double a = Math.sin(d_phi/2) * Math.sin(d_phi/2)
        + Math.cos(phi1) * Math.cos(phi2) * Math.sin(d_lambda/2) * Math.sin(d_lambda/2);
    double delta = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

    double A = Math.sin((1-fraction)*delta) / Math.sin(delta);
    double B = Math.sin(fraction*delta) / Math.sin(delta);

    double x = A * Math.cos(phi1) * Math.cos(lambda1) + B * Math.cos(phi2) * Math.cos(lambda2);
    double y = A * Math.cos(phi1) * Math.sin(lambda1) + B * Math.cos(phi2) * Math.sin(lambda2);
    double z = A * Math.sin(phi1) + B * Math.sin(phi2);

    double phi3 = Math.atan2(z, Math.sqrt(x*x + y*y));
    double lambda3 = Math.atan2(y, x);

    double lat = phi3 * 180/Math.PI;
    double lon = lambda3 * 180/Math.PI;

    return new Coor(lat, lon);
}

public float limit(float v, float max, float min)
{
  return max(min(v, max), min);
}

// this work on range -180 to 180. 0-360 need extra conversion before feading to the filter. 
class AngleFilter {
  double hist = 0;
  double alpha = 0.95f;
  
  AngleFilter(double alpha){
    this.alpha = alpha;
  }
  // input output rad. -pi to pi. 
  public double update(double rad)
  {
     double cosa = alpha * Math.cos(hist) + (1 - alpha) * Math.cos(rad);
     double sina = alpha * Math.sin(hist) + (1 - alpha) * Math.sin(rad);
     hist = Math.atan2(sina, cosa);
     return hist;
  }
  // input/output degree, -180 to 180
  public double update_deg(double deg)
  {
     update(deg/180*PI);
     return hist*180/PI;
  }
}

class Navigator{
  
  LinkedList<Coor> waypoints =new LinkedList<Coor>();

  float path_width = 50; 
  float out_path_dis =   path_width * 3;
  float max_off_angle = 60;
  float cross_track_ratio = 5; // 1 meter cross track error = N degree
  float L1 = 10;
  float wing_limit_angle = 30;  // the minimum wing relative angle 
  
  // outputs
  float bearing = 0; // output the expected bearing
  float rudder = 0;  // the rudder output, currently only the side of adjustment. 
  
  // primary path
  Coor target = new Coor(0.0005f, 0.0001f); // path target location
  Coor base = new Coor(-0.0005f, -0.0001f);   // path base location
  
  Coor old_base = new Coor(-0.0f, -0.0f);   // path base location
  
  // when the distance is too far from path, the ship need to go back to the track first. 
  // In this case, these are temporary target/base. will over take the path and lead the ship back to the path. 
  // t_base is the ship's initial location
  // t_target is the intersection point of the path with maximum angle from t_base. 
  Coor t_target = new Coor(0, 0); //
  Coor t_base  = new Coor(0, 0);  
  float t_path_bearing = 0;

  float zigzag_side = 1;      // which side of the zigzagging. 
  
  float path_bearing = 0;     // the angle from base to target. 
  float crosstrack_dis = 0;   // cross track distance
  float target_dis = 0;
  float path_seg_dis = 0; // the distance of the base to target. 
  
  boolean is_wing_sailing = true; 
  boolean is_zigzagging = true;
  boolean is_inpath = true; 
  boolean is_critical_bearing = false;
  boolean is_target_updated = false;    // whether to trigger a recalculation of related 

  float freezed_correction = 0;
  
  Navigator(){   
    //Coor p1= new Coor(51.8853, 0.2545);
    //float brng1 = 108.547;
    //Coor p2 = new Coor(49.0034, 2.5735);
    //float brng2 =  32.435;
    //Coor pint = intersection(p1, brng1, p2, brng2); // 50.9078°N, 004.5084°E
    //print(pint);
    
    waypoints.add(new Coor(target));
    base = new Coor(ship.loc);
  }
  
  Navigator(float path_width)
  {
    this.path_width = path_width;
    waypoints.add(new Coor(target));
    base = new Coor(ship.loc);
  }
  
  public void target_reached()
  {
    if(waypoints.size() > 1)
    {
      base = waypoints.get(0);
      waypoints.removeFirst();
      target = waypoints.get(0);
    }
    else
    {
        double lat, lon;
        lat = target.lat;
        lon = target.lon;
        target.lat = base.lat;
        target.lon = base.lon;
        base.lat = lat;
        base.lon = lon;
    }  
    is_inpath = true; 
    is_target_updated = true;
    is_critical_bearing  = true;// test, turn until it back to good track.
    freezed_correction = angle_corr((float)get_bearing(get_theta(base, target)) - ship.bearing);
  }
  
  public void add_waypoint(double lat, double lon)
  {
    waypoints.add(new Coor(lat, lon));
  }
  
  public void set_target(double lat, double lon)
  {
    target.lat = lat; target.lon = lon;
    is_inpath = true; // this need to reset to generate new temporary path when needed. 
    is_target_updated = true;
  }
  
  // Basic L1 for line tracking.
  // Output: Acc
  public float L1(Coor base, Coor target, Ship ship, float l, float step)
  {
    float d = (float)get_cross_track_distance(base, target, ship.loc);
    float eta = ship.bearing - (float)get_bearing(get_theta(base, target));
    if(eta > 180)
       eta -= 360;
    else if(eta < -180)
       eta += 360;
       
    if(eta > 45)
       eta = 45;
    else if(eta < -45)
       eta = -45;
       
    float a;  
    a = 2 * ship.speed*ship.speed/l* sin(eta/180*PI) * (d)*step;
    print(eta, a, "\n");
    return a;
  }
  
  public float reset_zigzag_side(float condition)
  {
    if(condition > 0)
      return -1;
    else
      return 1;
  }
  
  public void update(float step, Ship ship) // we need to adjust the path with wings direction. 
  {
    // rest when target changed. 
     if(old_base.lat != base.lat)
     {
       is_inpath = true;
       is_critical_bearing = false;
       is_target_updated = false; 
     }
     old_base.lat = base.lat;
     old_base.lon = base.lon;
    
     // calculate the primary path cross error. 
     crosstrack_dis = (float)get_cross_track_distance(base, target, ship.loc);
     path_bearing = (float)get_bearing(get_theta(base, target));
     path_seg_dis = (float)get_distance(base, target);
     target_dis = (float)get_distance(ship.loc, target);
    
     // detect if too far from path, then we create a temporary path to work with. 
     if(abs(crosstrack_dis) > out_path_dis){
       // ship is already out of primary path, check the cross track to the temporary track, if it is too large, we need to reset the temporary track
       if(!is_inpath){
         float cross_err = (float)get_cross_track_distance(t_base, t_target, ship.loc);
         float angle = (float)get_theta(t_base, t_target) - (float)get_theta(t_base, ship.loc);
         angle = angle_corr(angle);
         if(abs(cross_err) > out_path_dis ) // if ship keep going back
           is_inpath = true;  // set it to true to enter the temporary track relocation. 
           
         //print("angle", angle, "\n");
       }
       
       // when the ship just out of the track. or a relocation is needed.
       if(is_inpath)
       {
         is_inpath = false;
         // use ship location as base (copy value)
         t_base.lat = ship.loc.lat;
         t_base.lon = ship.loc.lon;
         // get inception on path or direct to base depending on whether the ship is behine the base already. 
         float t_base_to_base_bearing = (float)get_bearing(get_theta(base, t_base));
         
         // if it is smaller than right angle, means it is behine
         float angle_diff = t_base_to_base_bearing - path_bearing;
         if(angle_diff > 180)
           angle_diff -= 360;
         else if(angle_diff < -180)
           angle_diff += 360;
         
         if(abs(angle_diff) >= (90 - max_off_angle) + 90)
         {
           //print("Angle diff", angle_diff);
           t_target = base;
         }
         // already in the middle of path, then calculate the "intersection point". 
         // not using intersection point here, because the intersection calculation is not stable for meridional or equatorial lines.
         else
         {
           double offset_dis = crosstrack_dis * Math.tan((90-max_off_angle)/180*Math.PI);
           if(crosstrack_dis < 0)
             offset_dis = -offset_dis;
           double passed_path = crosstrack_dis / Math.tan(angle_diff /180*Math.PI) + offset_dis; 
           double fraction = passed_path / path_seg_dis;
           
           if(fraction >= 1)
             t_target = target;
           else
             // instead of intersection, we use the projected length on path, and add a little offset to see how much path has been completed. 
             // then calculate a intermidiate point on the path. 
             t_target = intermediate_point(base, target, fraction);
         }
         print("temp path enabled\n");
       }
     }
     
     // reset only when the ship get back into path width. 
     // there is a delay between switching "out path" and "in path.", because "outpath" is alway larger than "path_width"
     if(abs(crosstrack_dis) <= path_width) 
     {
       if(!is_inpath)
       {
         print("temp path disable\n");
         is_target_updated = true; // reset zigzag side
       }
       is_inpath = true;
     }
     
     // direct the ship to temporary path or primary path
     Coor ta; 
     Coor ba;
     if(is_inpath){
       ta = target;
       ba = base;
     }
     else{
       ta = t_target;
       ba = t_base; 
     }
     
     float ct_dis = (float)get_cross_track_distance(ba, ta, ship.loc);
     float ta_dis = (float)get_distance(ship.loc, ta);
     float base2target = (float)get_bearing(get_theta(ba, ta));
     float ship2target = (float)get_bearing(get_theta(ship.loc, ta));
       

    //float correction = angle_corr(base2target - ship.bearing); // use track bearing
    float correction = angle_corr(ship2target - ship.bearing); // use ship bearing. 
    float lim_angle = max_off_angle;  
    float ship_target_base_angle = angle_corr(ship2target - base2target);
          
    if(abs(ship_target_base_angle) <= lim_angle && abs(correction) < lim_angle ){
      //lim_angle = 180- (180 - lim_angle - abs(ship_target_base_angle)); // this lim angle is perpendicular to the track
      lim_angle = lim_angle - abs(ship_target_base_angle); // this lim angle is perpendicular to the track
      
      float ct_corr = ct_dis;
      // when sailing, we expend the track size to path width. 
      if(is_wing_sailing && is_zigzagging){
        if(ct_dis < 0)
          ct_corr = min(ct_dis + path_width/2, 0);
        else
          ct_corr = max(ct_dis - path_width/2, 0);
      }
        
      ct_corr = -(ct_corr * cross_track_ratio);
      ct_corr = limit(ct_corr, lim_angle, -lim_angle); // limit the range. cross track correction on bearing. 
      correction += ct_corr;              
      correction = angle_corr(correction);
    }
    // when the ship is behine the track
    // do not do crosstrack correction, not going to the track but to the target directly. 
    else {
    }
    
    // // see if reset
    if(is_target_updated)
    {
      is_target_updated = false;
      print("target reseted\n");
      zigzag_side = reset_zigzag_side(-correction); // change zigzag side according to correction angle.
      //zigzag_side = reset_zigzag_side(zigzag_side);
      //zigzag_side = reset_zigzag_side(ship.wing.angle);
    }
    
    if(is_wing_sailing)
    {
      float target_bearing = (float)get_bearing(correction + ship.bearing);
      float wing_angle = ship.wing.angle ;
      // convert +-180 to +-90. 
      if(ship.wing.angle > 90)
        wing_angle -= 180;
      else if(ship.wing.angle < -90)
        wing_angle += 180;
      
      float first, second, third, forth; // dimemsion of available angle
      float wing_bearing = (float)get_bearing(ship.bearing + wing_angle);
      first = (float)get_bearing(wing_bearing + 180 + (180 -wing_limit_angle));
      second = (float)get_bearing(wing_bearing + wing_limit_angle);
      third = (float)get_bearing(wing_bearing + (180 - wing_limit_angle));
      forth = (float)get_bearing(wing_bearing + 180 + wing_limit_angle);
      
      // calculate each rotation and decide which to use. 
      float dir[] = new float[4];
      dir[0] = angle_corr(first - target_bearing);
      dir[1] = angle_corr(second - target_bearing);
      dir[2] = angle_corr(third - target_bearing);
      dir[3] = angle_corr(forth - target_bearing);
     
      
      // detect the target bearing is in which section. 
      // 1 = first-second. 2 = second-third, 3 = third-forth, 4= forth-first. 
      // forbiden sections are 1 and 3. In these section, will need to perform zigzagging. 
      
      //print((int)correction, " ");
      
      //// compensate the ship bearing to track bearing 
      //// because we are using current target bearing, when it near the target, it will start oscillating between zigzaging or direct mode.
      //// so we add the compensation to the wing angles to limit the ranges.  
      float off = angle_corr(base2target - target_bearing); //
      float first_ext = dir[0];
      float second_ext = dir[1];
      //print((int)off, " ");
      //if(zigzag_side > 0)
      //  first_ext = angle_corr(dir[0] - off); 
      //else 
      //  second_ext = angle_corr(dir[1] + off);
      
      
      // expend the other side to increase the detection range.
      float corr = limit(correction, (90-wing_limit_angle), -(90-wing_limit_angle)); // make sure this wong overlap
      if(zigzag_side > 0)
        first_ext = angle_corr(dir[0]  + corr); 
      else 
        second_ext = angle_corr(dir[1]  + corr);
        
      // change zigzag side. when distance too far or already close to target.
      if(abs(ct_dis) >= path_width/2  || abs(ct_dis) >= ta_dis*0.3f || is_target_updated)
      {
        if(ct_dis >0)// && zigzag_side == 1) 
          zigzag_side = -1;
        else if(ct_dis <0)// && zigzag_side == -1)
          zigzag_side = 1;
      }
      
      
      // when target direction is in the dead zones - first-second will have different sign. 
      //if(dir[0] * dir[1] <= 0) // dead zone, both deadzone are same, so only calculate one. 
      if(first_ext * second_ext < 0)
      {
          // add ship2track and track bearing compensation. 
          //float offset = angle_corr(base2target - target_bearing);
          //correction += offset;
          //correction = angle_corr(correction);              
         
          // do zigzag
          if(abs(dir[0] * dir[1]) < abs(dir[2]*dir[3])){
            // switch side
            if(zigzag_side < 0){
              correction += dir[0];
            }
            else{
              correction += dir[1];
            }
          }
          else{
            // switch side
            if(zigzag_side < 0){
              correction += dir[3];
            }
            else{
              correction += dir[2];
            }
          }        
          // correct
          correction = angle_corr(correction);
      }
    }
        
    if(correction > 0)
        rudder = 1;
    else if (correction < 0){
        rudder = -1;
    } 
    else
      rudder = 0;
    //print("correction", (int)correction, "wing", int(ship.wing.angle), "ship bearing", int(ship.bearing), 
    //      "track angle", (int)track_angle,"offset angle", (int)offset_angle, "distance", (int)ta_dis, "cross track", (int)ct_dis, "\n");
    
    
    bearing = (float)get_bearing(ship.bearing + correction);
    //return rudder;
          
  }
  
  public void draw_target(Coor loc, float size)
  {
      float x = (float)world.deg2pix_x(loc.lat);
      float y = (float)world.deg2pix_y(loc.lon);
      pushMatrix();
      stroke(32);
      textAlign(CENTER, TOP);
      if(size <=10)
        fill(255, 255, 255);
      else
        fill(255, 255, 0);
      circle(x, y, size);
      text("("+nf((float)loc.lat, 0, 5) + ", " + nf((float)loc.lon, 0, 5)+")", x, y+size);
      popMatrix();

  }
  
  public void draw(Ship ship, World world){
    // translate
    float target_x = (float)world.deg2pix_x(target.lat);
    float target_y = (float)world.deg2pix_y(target.lon);
    float base_x = (float)world.deg2pix_x(base.lat);
    float base_y = (float)world.deg2pix_y(base.lon);
    float ship_x = (float)world.deg2pix_x(ship.loc.lat);
    float ship_y = (float)world.deg2pix_y(ship.loc.lon);

    draw_target(base, 10);
    draw_target(target, 20);
    
    // see if need to draw secondary path
    if(!is_inpath)
    {
      float t_target_x = (float)world.deg2pix_x(t_target.lat);
      float t_target_y = (float)world.deg2pix_y(t_target.lon);
      float t_base_x = (float)world.deg2pix_x(t_base.lat);
      float t_base_y = (float)world.deg2pix_y(t_base.lon);
      
      draw_target(t_target, 5);
      
      stroke(0, 255, 255);
      line(t_target_x, t_target_y, ship_x, ship_y); // line to temporary target
      
      stroke(96, 150, 192);
      line(t_base_x, t_base_y, t_target_x, t_target_y);
      stroke(32);
    
      float x1, y1, x2, y2, ang, clen, slen;
      x1 = t_base_x;
      y1 = t_base_y;
      x2 = t_target_x;
      y2 = t_target_y;
      ang = -atan2(y2-y1, x2-x1); // why this is negative?
      clen = cos(ang) * (float)world.m2pix(path_width/2);
      slen = sin(ang) * (float)world.m2pix(path_width/2);
      // draw 
      stroke(96, 150, 128);
      line(x1+slen, y1+clen, x2+slen, y2+clen);
      line(x1-slen, y1-clen, x2-slen, y2-clen);
    }
    // draw a ship line to target. 
    else
    {
      stroke(0, 255, 255);
      line(target_x, target_y, ship_x, ship_y);
    }

    // primary path
    stroke(96, 150, 192);
    line(base_x, base_y, target_x, target_y);
    stroke(32);
  
    float x1, y1, x2, y2, ang, clen, slen;
    x1 = base_x;
    y1 = base_y;
    x2 = target_x;
    y2 = target_y;
    ang = -atan2(y2-y1, x2-x1); // why this is negative?
    clen = cos(ang) * (float)world.m2pix(path_width/2);
    slen = sin(ang) * (float)world.m2pix(path_width/2);
    // draw 
    stroke(96, 150, 128);
    line(x1+slen, y1+clen, x2+slen, y2+clen);
    line(x1-slen, y1-clen, x2-slen, y2-clen);
    
    for(int i= 1; i<waypoints.size(); i++)
    {
      x1 = x2;
      y1 = y2;
      x2 = (float)world.deg2pix_x(waypoints.get(i).lat);;
      y2 = (float)world.deg2pix_y(waypoints.get(i).lon);;
      stroke(96, 150, 192);
      line(x1, y1, x2, y2);
      draw_target(waypoints.get(i), 10);
    }
  }
}



//float nav(){
//    float ship_rotate = 0;
//    float ship_angle = atan2(ship_x-target_x, ship_y-target_y);
//    ship_angle = -ship_angle * 180/PI;

//    float track_angle = atan2(base_x-target_x, base_y-target_y);
//    track_angle = -track_angle * 180/PI;
    
//    // test, avoid heading wind. 
//    float head_wind_offset = 0;
//    float relative_angle = sail_bearing - (ship_bearing - 180);
//    sail_relative_angle = angle_corr(relative_angle);
    
//    // head wind
//    if(abs(sail_relative_angle) > 150)
//    {
//      // convert it back 
//      sail_relative_angle = angle_corr(180 - sail_relative_angle);
//    }
        
//    float offset_angle = angle_corr(track_angle - ship_angle);
//    //print("off", int(offset_angle), "track:", int(track_angle), "ship", int(ship_angle), "\n");

//    // calculate the distance between ship and 
//    target_distance = sqrt((ship_x-target_x)*(ship_x-target_x)+(ship_y-target_y)*(ship_y-target_y));
//    crosstrack_err = sin(radians(offset_angle)) * target_distance;
    
//    // when ship is too far from path, add an temporary target where intersection with the path
//    if(crosstrack_err > path_width *2 && is_ship_base_locked == false)
//    {
//      is_ship_base_locked = true;
//      ship_base_x = ship_x;
//      ship_base_y = ship_y;
      
//      //
//      intcpt_target_x = ship_base_x + crosstrack_err * sin(track_angle);
//      intcpt_target_y = ship_base_y + crosstrack_err * cos(track_angle);
      
//      print(ship_base_x, ship_base_y, intcpt_target_x, intcpt_target_y, '\n');
    
//    }
//    if(crosstrack_err < path_width)
//    {
//      is_ship_base_locked = false;
//    }
    

//    // change zigzag side. when distance too far or already close to target.
//    if(abs(crosstrack_err) >= path_width || abs(crosstrack_err) >= target_distance*0.3)
//    {
//      if(crosstrack_err >0)// && zigzag_side == 1) 
//        zigzag_side = -1;
//      else if(crosstrack_err <0)// && zigzag_side == -1)
//        zigzag_side = 1;
//    }
    
//    if(abs(sail_relative_angle) < 30)
//    {
//      float a = (60 - abs(sail_relative_angle)) + (45 - abs(offset_angle)); // why this is 45
//      head_wind_offset = zigzag_side * (a);
//      print("head wind",  sail_relative_angle, head_wind_offset, zigzag_side, offset_angle, '\n');
//    }
//    else{
//      head_wind_offset = 0;
//    }
      
//    // if headwind, we ignore the cross track error because we are doing zigzaging
//    if(abs(crosstrack_err) < path_width && head_wind_offset != 0)
//    {
//      crosstrack_err = 0;
//    }
    
//    float correction = 0;
    
//    // avoid over shooting when go back to track when track is far away
//    float lim_angle = 70;
//    if(abs(offset_angle) <= lim_angle)
//    {
//        lim_angle = lim_angle - abs(offset_angle); // this lim angle is perpendicular to the track
//        crosstrack_err = limit(crosstrack_err, lim_angle, -lim_angle); // limit the range. 
//        correction += -(crosstrack_err * 1);
//        correction = angle_corr(correction);
//    }
//    // when the ship is behine the track
//    // do not do crosstrack correction, not going to the track but to the target directly. 
//    else 
//    {}

//    correction += ship_angle - (ship_bearing - 180);  // use track angle?
//    correction = angle_corr(correction);
//    correction += head_wind_offset; 
//    //correction = angle_corr(correction);

//    // avoid oscillation, when angle >90, free the correction until it turns. 
//    if(abs(correction) > 90)
//    {
//        if(!is_critical_bearing)
//        {
//            is_critical_bearing = true;
//             freezed_correction = correction; 
//        }
//        correction = freezed_correction;
//    }
//    else 
//        is_critical_bearing = false;
        
//    if(correction > 0)
//        ship_rotate += ship_rotate_speed;
//    else if (correction < 0){
//        ship_rotate -= ship_rotate_speed;
//    }    
//    //print("correction", correction,"shipangle:", ship_angle, "ship bearing", ship_bearing, "distance", target_distance,"cross", crosstrack_err, "\n");
    
//    return ship_rotate;
//}


public float angle_corr(float ang)
{
  ang = ang % 360;
   if(ang <= -180)
     ang += 360;
   else if (ang >= 180)
     ang -= 360;
  return ang;
}

class Wing {
  float cl = 0.5f;         // lift to drag coefficient. 
  float angle = 0;  // relative angle to the ship
  float aoa = 10;       // sail angle of attack
  float speed = 0;      // relative speed to air. 
  
  float lift;          // lift generated from the wing, perpendicular to the  direction
  float drag;          // not using it yet. 
  
  //AngleFilter filter = new AngleFilter(0.8);
  
  public void update(float step, Ship ship, World world)
  {
      // calculate the sail angle to the ship
      float vx = cos((ship.bearing) / 180 * PI)*ship.speed - cos((world.wind_dir - 180) / 180 * PI)*world.wind_speed; // inverted current flow
      float vy = sin((ship.bearing) / 180 * PI)*ship.speed - sin((world.wind_dir - 180) / 180 * PI)*world.wind_speed; 
      float v = sqrt(vx*vx + vy*vy);
      angle = atan2(vy, vx)*180/PI - ship.bearing;
      angle = angle_corr(angle); // convert it back to -180 to 180
      // test filter
      //angle = (float)filter.update_deg((float)angle);
      
      speed = v;
      lift = speed * cl; // simple linear test 
      //print("v", v, "angle", int(angle), "\n");
  }
}

class Ship {
  Coor loc = new Coor(0, 0);

  // ship
  float speed = 0;        // speed in m/s
  float speed_momentum = 0.98f; // speed momentum
  float speed_min= -2.0f; // speed mini (when test, set to positive to push the ship forward even wind is reversed.)
  float bearing = 0;      // 0-360 degree
  float rudder_cof = 2;   // rudder coefficient 
  float turn_momentum = 0; //
  float turn_momentum_filter = 0.99f; //
  
  // wings
  Wing wing = new Wing();
  
  // for the path. 
  ParticleSystem ps = new ParticleSystem(new PVector(width/2, 255));

  Ship(){ }
  Ship(double lat, double lon){
    loc.lat = lat;
    loc.lon = lon;
  }
  
  public void update(float step, float rudder, World world){
    // test with step
    rudder = rudder*10*step;
    // ship bearing
    turn_momentum = turn_momentum*turn_momentum_filter + (rudder)*(1-turn_momentum_filter); // filter
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
    
    loc.lat -= Math.sin((world.wind_dir) / 180 * PI)*speed * 0.2f / R * 180/PI * step;  // drift by wind, test only
    loc.lon -= Math.cos((world.wind_dir) / 180 * PI)*speed * 0.2f / R * 180/PI * step; 
     
    loc.lon = Math.min(Math.max(loc.lon, world.coor_min.lon), world.coor_max.lon);
    loc.lat = Math.min(Math.max(loc.lat, world.coor_min.lat), world.coor_max.lat);
  }
  
  public void draw(World world){
    // translate
    float ship_x = (float)world.deg2pix_x(loc.lat);
    float ship_y = (float)world.deg2pix_y(loc.lon);
    
    ps.addParticle(new PVector(ship_x, ship_y), 0, 0, 5000, color(255,128,255)); // draw path
    ps.run();
    
    stroke(32);
    // draw
    pushMatrix();
    translate(ship_x, ship_y);
    rotate((bearing + 180) / 180 * PI); // 
    
    // ship
    beginShape();   
    fill(255);
    vertex(0, 30.0f);  // left front
    vertex(5.0f, 10.0f);
    vertex(6.0f, 0.0f);
    vertex(6.0f, -15.0f);
    vertex(3.0f, -30.0f);
    vertex(-3.0f, -30.0f); // right
    vertex(-6.0f, -15.0f);
    vertex(-6.0f, 0.0f);
    vertex(-5.0f, 10.0f);
    endShape(CLOSE);
    stroke(255, 255, 0);
    line(0,0, 0, 20*speed);
    popMatrix();
     
    // wing
    pushMatrix();
    translate(ship_x, ship_y);
    rotate((wing.angle + bearing + 180) / 180 * PI);
    // sail colour
    
    if(abs(wing.angle) < 28 || abs(wing.angle)>180-28){
      stroke(255, 128, 128);
      fill(255, 0, 0);
    }
    else{
      stroke(128, 255, 128);
      fill(0, 200, 0);
    }
    beginShape();    
    vertex(0, 15.0f);  // left front
    vertex(1.0f, 10.0f);
    vertex(2.0f, 0.0f);
    vertex(0.0f, -15.0f);
    vertex(-2.0f, 0.0f);  // right
    vertex(-1.0f, 10.0f); 
    endShape(CLOSE);
    //
    stroke(255, 0, 200);
    line(0,0, 0, 10*wing.speed);
    popMatrix();
    
    //print(bearing, wing.angle, "\n");
  }
  

}

// earth radius. 
float R = 6371000.0f;

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
    coor_min.lon = coor_centre.lon - (world_width/2.0f/R) *180/PI *((float)height/width);
    coor_max.lon = coor_centre.lon + (world_width/2.0f/R) *180/PI *((float)height/width);
    coor_min.lat = coor_centre.lat - (world_width/2.0f/R) *180/PI;
    coor_max.lat = coor_centre.lat + (world_width/2.0f/R) *180/PI;
  }
  
  // no offset version 
  public double m2pix(double m){
    return m * width / world_width;
  }
  public double deg2pix(double deg){
    return deg /180*PI * R * width / world_width;
  }
  
  // offset versions
  public double m2pix_x(double m){
    return m * width / world_width + width/2;
  }
  public double m2pix_y(double m){
    return -m * width / world_width + height/2; // (width/world_width) is the scale factor. screen y is inverted. 
  }
  public double deg2pix_x(double deg){
    return deg2pix(deg - coor_centre.lon) + width/2;
  }
  public double deg2pix_y(double deg){
    return -deg2pix(deg - coor_centre.lat) + height/2;// (width/world_width) is the scale factor. 
  }
  
  public double pix2deg(int pix){
    return pix * 180/PI / R / width * world_width;
  }
  public double pix2deg_x(int pix){
    return pix2deg(pix - width/2) + coor_centre.lon;
  }
  public double pix2deg_y(int pix){
    return -pix2deg(pix - height/2)  + coor_centre.lat;
  }
   

  public void update(float step){
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
  
  public void draw_grid(){
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
  
  AngleFilter filter = new AngleFilter(0.98f);
  public void draw_current()
  {
    float rotate = wind_dir;
    rotate = (float)filter.update_deg((float)rotate);
    
    pushMatrix();
    translate(width-60, 60);
    rotate((rotate+180) / 180 * PI);
    fill(255, 255, 255);
    beginShape();
    vertex(-10.0f, -10.0f);
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
  
  public void draw_compass()
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

  
  public void draw(float acc){
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
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "simulator" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
