
// REF: https://www.movable-type.co.uk/scripts/latlong.html
// haversine method
// a = sin²(Δφ/2) + cos φ1 ⋅ cos φ2 ⋅ sin²(Δλ/2)
// return angular distance, value x R = real distance
double get_rad_distance(Coor p1, Coor p2)
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

double get_distance(Coor p1, Coor p2)
{
    return get_rad_distance(p1, p2)*R;
}

// get the angle between 2 coordinate.
// return θ ranges from -180 to 180, and faces north for 0 degree.
double get_theta(Coor p1, Coor p2)
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
double get_bearing(double theta)
{
    return  (theta + 360 ) % 360.0;
}

// convert angel to +- 180 range
double get_direction(double theta)
{
    return -(theta + 180) % 180.0;
}

// p1 = start, p2=end, curr = current point
// negative means the current location is on the left side of the path.
double get_cross_track(Coor p1, Coor  p2, Coor curr)
{
   double dist = 0;
   double a13 = get_rad_distance(p1, curr);                 // angular distance
   double theta13 = get_theta(p1, curr) * PI / 180;   // start to current.
   double theta12 = get_theta(p1, p2) * PI / 180;     // start to end.
   dist = Math.asin(Math.sin(a13)* Math.sin(theta13- theta12));
   return dist;
}

double get_cross_track_distance(Coor p1, Coor  p2, Coor curr)
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
Coor intersection(Coor p1, double bearing1, Coor p2, double bearing2) {
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
    if (Math.abs(delta12) < EPSILON*0.001) // even EPSILON is not small enough
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
Coor intermediate_point(Coor psrc, Coor pdes, double fraction) {
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

float limit(float v, float max, float min)
{
  return max(min(v, max), min);
}

class Navigator{

  float path_width = 10; 
  float out_path_dis = path_width * 3;
  float max_off_angle = 70;
  float cross_track_ratio = 10; // 1 meter cross track error = N degree
  float L1 = 10;
  float wing_limit_angle = 35;  // the minimum wing relative angle 
  
  // outputs
  float bearing = 0; // output the expected bearing
  float rudder = 0;  // the rudder output, currently only the side of adjustment. 
  
  // primary path
  Coor target = new Coor(0.0005, 0.0001); // path target location
  Coor base = new Coor(-0.0005, -0.0001);   // path base location
  
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
  }
  
  Navigator(float path_width)
  {
    this.path_width = path_width;
  }
  
  void set_target(double lat, double lon)
  {
    target.lat = lat; target.lon = lon;
    is_inpath = true; // this need to reset to generate new temporary path when needed. 
    is_target_updated = true;
  }
  
  // Basic L1 for line tracking.
  // Output: Acc
  float L1(Coor base, Coor target, Ship ship, float l, float step)
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
  
  float reset_zigzag_side(float condition)
  {
    if(condition > 0)
      return -1;
    else
      return 1;
  }
  
  void update(float step, Ship ship) // we need to adjust the path with wings direction. 
  {
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
     

         
    //boolean is_sailing = true;
    boolean is_sailing = true;
    
    //float correction = angle_corr(base2target - ship.bearing); // use track bearing
    float correction = angle_corr(ship2target - ship.bearing); // use ship bearing. 
    float lim_angle = max_off_angle;  
    float ship_target_base_angle = angle_corr(ship2target - base2target);
          
    if(abs(ship_target_base_angle) <= lim_angle){
      lim_angle = lim_angle - abs(ship_target_base_angle); // this lim angle is perpendicular to the track
      
      float ct_corr = ct_dis;
      // when sailing, we expend the track size to path width. 
      if(is_sailing){
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
    
    // change zigzag side. when distance too far or already close to target.
    if(abs(ct_dis) >= path_width/2  || abs(ct_dis) >= ta_dis*0.3 || is_target_updated)
    {
      if(ct_dis >0)// && zigzag_side == 1) 
        zigzag_side = -1;
      else if(ct_dis <0)// && zigzag_side == -1)
        zigzag_side = 1;
    }
    
     // see if reset
    if(is_target_updated)
    {
      is_target_updated = false;
      print("target reseted\n");
      zigzag_side = reset_zigzag_side(ct_dis);
      //zigzag_side = reset_zigzag_side(zigzag_side);
      //zigzag_side = reset_zigzag_side(ship.wing.angle);
    }
        
    float wing_angle = ship.wing.angle ;
    // convert +-180 to +-90, mod is not working correctly in java with negative number???
    if(ship.wing.angle > 90)
      wing_angle -= 180;
    else if(ship.wing.angle < -90)
      wing_angle += 180;
    
    float target_bearing = (float)get_bearing(correction + ship.bearing);
    //print(target_bearing+"\n");
    // get upper and lower boundary
    float wing_front_upper = (float)get_bearing((ship.bearing + wing_angle) + wing_limit_angle); // get the current wing bearing 
    float wing_front_lower = (float)get_bearing((ship.bearing + wing_angle) - wing_limit_angle);
    
    //print('\n', (int)wing_front_lower, (int)wing_front_upper, (int)target_bearing, correction);
    
    // head wind
    if((angle_corr(wing_front_lower - target_bearing) < 0 
        && angle_corr(wing_front_upper - target_bearing) > 0)
        || abs(wing_angle) < wing_limit_angle) // this is needed. otherwise it keep turn in when target is around 30 degree
    if(abs(wing_angle) < wing_limit_angle) // ... why this simple things works? other than the above
    {      
      //print((int) zigzag_side, " head wind!  ");
      if(zigzag_side < 0)
      {
        correction += angle_corr(wing_front_lower - target_bearing);
      }
      else
      {
        correction += angle_corr(wing_front_upper - target_bearing); 
      }
      correction = angle_corr(correction);
    }
    //print((int)wing_front_upper,(int) wing_front_lower, (int)wing_angle, (int)target_bearing, (int)correction, " \n");
    
    //float first, second, third, forth; // dimemsion of available angle
    //float wing_bearing = (float)get_bearing(ship.bearing + wing_angle);
    //first = (float)get_bearing(wing_bearing + 180 + (180 -wing_limit_angle));
    //second = (float)get_bearing(wing_bearing + wing_limit_angle);
    //third = (float)get_bearing(wing_bearing + (180 - wing_limit_angle));
    //forth = (float)get_bearing(wing_bearing + 180 + wing_limit_angle);
    
    //if(abs(wing_angle) < wing_limit_angle) // ... why this simple things works? other than the above
    //{ 
    //  // calculate each angle and decide which to use. 
    //  first = angle_corr(first - target_bearing);
    //  second = angle_corr(second - target_bearing);
    //  third = angle_corr(third - target_bearing);
    //  forth = angle_corr(forth - target_bearing);
      
    //  // trick
    //  // head wind swing
    //  if(abs(first) + abs(second) < 90)
    //  {
    //    print("head wind ");
    //    if(zigzag_side < 0) // zigzag > 0 = left
    //        correction += first; 
    //    else
    //        correction += second;
    
    //  }
    //  // tail wind swing
    //  else
    //  {
    //    print("tail wind ");
    //   if(zigzag_side < 0) // zigzag > 0 = left
    //        correction += first; 
    //    else
    //        correction += second;
    //  }
       
    //  correction = angle_corr(correction);
    //  print((int)first, (int)second, (int)third, (int)forth, (int)correction, (int)target_bearing, int(ship.bearing)," \n");
    //}
    
    //print((int)wing_front_upper,(int) wing_front_lower, (int)wing_angle, (int)target_bearing, (int)correction, " \n");
    
    //// see the zigzag side is matching the boundary. 
    //if((angle_corr(wing_front_lower - target_bearing) < 0 || zigzag_side > 0) &&
    //   (angle_corr(wing_front_upper - target_bearing) > 0 || zigzag_side < 0) && 
    //   abs(angle_corr(target_bearing - ship.bearing)) < 120)
    ////if((angle_corr(wing_front_lower - target_bearing) < 0) &&
    ////   (angle_corr(wing_front_upper - target_bearing) > 0))
    //{      
    //  //float b = abs(limit(angle_corr(ship2target - ship.bearing), 90, -90)); // also add ship bearing to track bearing. 
    //  //float b = abs(limit(angle_corr(base2target - ship.bearing), 90, -90)); // track bearing
    //  float a = wing_limit_angle - abs(wing_angle); // why this is 45
    //  float b = abs(limit(angle_corr(ship2target - ship.bearing), 120-a, -(120-a))); // also add ship bearing to track bearing.     
    //  head_wind_offset = zigzag_side * (a + b); 
    //  // print(correction);
    //  correction += head_wind_offset;
    //  correction = angle_corr(correction);
    //  print("bad  \n");
    //  print(zigzag_side, ship.wing.angle, wing_angle, a, b,  head_wind_offset, correction, "\n");
    //}
    //else
    //{
    //   print("good \n");
    //}
   
    //print((int)ship.bearing, (int)ship.wing.angle, '\n');

    // avoid oscillation and shooting backward, when angle >90, freezed the correction until it turns back to target. 
    float  corr_angle = angle_corr(ship2target - ship.bearing);
    if(abs(corr_angle) >120 && !is_critical_bearing)
    {
       is_critical_bearing = true;  
       freezed_correction = zigzag_side ; // turn to the zigzag side
       print("\ncritical bearing", freezed_correction, "\n ");   
    }
    if(abs(corr_angle) < 90)
    {
        if(is_critical_bearing)
        {
          is_target_updated = true; // test, to reset all 
          zigzag_side = -zigzag_side; // test, when reach the target, invert the side. 
        }
        is_critical_bearing = false;
    }
     
    if(is_critical_bearing)
    {
        correction = freezed_correction; // override
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
    
    //return rudder;
          
  }
  
  void draw_target(Coor loc, float size)
  {
      float x = (float)world.deg2pix_x(loc.lat);
      float y = (float)world.deg2pix_y(loc.lon);
      pushMatrix();
      stroke(32);
      textAlign(CENTER, TOP);
      fill(255, 255, 255);
      circle(x, y, size);
      text("("+nf((float)loc.lat, 0, 5) + ", " + nf((float)loc.lon, 0, 5)+")", x, y+size);
      popMatrix();

  }
  
  void draw(Ship ship, World world){
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
