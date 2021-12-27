// A class to describe a group of Particles
// An ArrayList is used to manage the list of Particles 

class ParticleSystem {
  ArrayList<Particle> particles;
  PVector origin;

  ParticleSystem(PVector position) {
    origin = position.copy();
    particles = new ArrayList<Particle>();
  }

  void addParticle(PVector location, float speed, float bearing) {
    particles.add(new Particle(location, speed, bearing));
  }
  
    void addParticle(PVector location, float speed, float bearing, float life, color c) {
    particles.add(new Particle(location, speed, bearing, life, c));
  }

  void run() {
    for (int i = particles.size()-1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.run();
      if (p.isDead()) {
        particles.remove(i);
      }
    }
  }
}
