PImage surf;
Table table;

// ===============================================================
int puntos = 100;
Particle[] fl; // arreglo de partículas
float d = 15; // radio del círculo, solo para despliegue
float gbestx, gbesty, gbest = Float.MAX_VALUE; // posición y fitness del mejor global
float w = 10; // inercia: baja (~50): explotación, alta (~5000): exploración (2000 ok)
float C1 = 30, C2 =  30; // learning factors (C1: own, C2: social) (ok)
int evals = 0, evals_to_best = 0; //número de evaluaciones, sólo para despliegue
float maxv = 3; // max velocidad (modulo)
float time = 0; //tiempo en el que el algoritmo encuentra el minimo

int iteracion = 0;

// ===============================================================
// Tabla de exportación de datos
// ===============================================================
void InitTable(){
   table = new Table();
   table.addColumn("iteracion");
   table.addColumn("fitness");
   table.addColumn("gbestx");
   table.addColumn("gbesty");
   table.addColumn("puntos");
   table.addColumn("inercia");
   table.addColumn("C1");
   table.addColumn("C2");
   table.addColumn("evals");
   table.addColumn("evals to best");

}
void guardarDatos(){

  TableRow fila = table.addRow();

  fila.setFloat("fitness", gbest);
  fila.setFloat("gbestx", gbestx);
  fila.setFloat("gbesty", gbesty);

  fila.setInt("puntos", puntos);
  fila.setFloat("inercia", w);
  fila.setFloat("C1", C1);
  fila.setFloat("C2", C2);

  fila.setInt("evals", evals);
  fila.setInt("evals to best", evals_to_best);
  fila.setInt("iteracion", iteracion);
  iteracion++;
}
void keyPressed(){
  saveTable(table, "datos_pso.csv");
  println("datos guardados");
}


// ===============================================================
// FUNCIÓN DE RASTRIGIN 2D
// ===============================================================
float evaluarRastrigin(float screenX, float screenY) {
  // Mapeamos las coordenadas de la pantalla (0 a width/height) 
  // al dominio matemático (-3 a 7)
  float x = map(screenX, 0, width, -3, 7);
  float y = map(screenY, 0, height, -3, 7);
  
  // Ecuación matemática pura
  float termX = (x * x) - 10 * cos(TWO_PI * x);
  float termY = (y * y) - 10 * cos(TWO_PI * y);
  float z = 20 + termX + termY;
  
  return z; // Retornamos el valor Z (fitness)
}

// ===============================================================

class Particle{
  float x, y, fit; 
  float px, py, pfit; 
  float vx, vy; 
  
  Particle(){
    x = random (width); y = random(height);
    vx = random(-1,1) ; vy = random(-1,1);
    // CAMBIO 2: Inicializamos en el valor máximo posible
    pfit = Float.MAX_VALUE; fit = Float.MAX_VALUE; 
  }
  
  float Eval(){ 
    evals++;
    fit = evaluarRastrigin(x, y); 
    
    // CAMBIO 3: Ahora buscamos que el fitness sea MENOR (minimización)
    if(fit < pfit){ 
      pfit = fit;
      px = x;
      py = y;
    }
    if (fit < gbest){ 
      gbest = fit;
      gbestx = x;
      gbesty = y;
      evals_to_best = evals;
      println("Nuevo Global Best: " + str(gbest));
    }
    return fit; 
  }
  
  void move(){
    //actualiza velocidad (fórmula con factores de aprendizaje C1 y C2)
    vx = vx + random(0,1)*C1*(px - x) + random(0,1)*C2*(gbestx - x);
    vy = vy + random(0,1)*C1*(py - y) + random(0,1)*C2*(gbesty - y);
    //actualiza velocidad (fórmula con inercia, p.250)
    //vx = w * vx + random(0,1)*(px - x) + random(0,1)*(gbestx - x);
    //vy = w * vy + random(0,1)*(py - y) + random(0,1)*(gbesty - y);
    //actualiza velocidad (fórmula mezclada)
    //vx = w * vx + random(0,1)*C1*(px - x) + random(0,1)*C2*(gbestx - x);
    //vy = w * vy + random(0,1)*C1*(py - y) + random(0,1)*C2*(gbesty - y);
    // trunca velocidad a maxv
    float modu = sqrt(vx*vx + vy*vy);
    if (modu > maxv){
      vx = vx/modu*maxv;
      vy = vy/modu*maxv;
    }
    // update position
    x = x + vx;
    y = y + vy;
    // rebota en murallas
    if (x > width || x < 0) vx = - vx;
    if (y > height || y < 0) vy = - vy;
  
  }
  
  void display(){
    color c = surf.get(int(x),int(y)); 
    fill(c);
    ellipse (x,y,d,d);
    stroke(#ff0000);
    line(x,y,x-10*vx,y-10*vy);
  }
} 

void despliegaBest(){
  fill(#0000ff);
  ellipse(gbestx,gbesty,d,d);
  PFont f = createFont("Arial",16,true);
  textFont(f,15);
  fill(#00ff00);
  text("Best fitness: "+str(gbest)+"\nEvals to best: "+str(evals_to_best)+"\nEvals: "+str(evals),10,20);
}

// ===============================================================

void setup(){  
  size(1024,512); 
  
  //Creación de tabla para exportar datos
  InitTable();
  
  
  // Generar el mapa visual
  surf = createImage(width, height, RGB);
  surf.loadPixels();
  colorMode(HSB, 360, 100, 100);
  for(int i = 0; i < width; i++) {
    for(int j = 0; j < height; j++) {
      float val = evaluarRastrigin(i, j);
      
      // Mapeamos el fitness a un tono (hue)
      // Mínimo (0) se verá rojo (caliente) y altos niveles se verán azul (frío)
      float h = map(constrain(val, 0, 150), 0, 150, 0, 240); 
      surf.pixels[i + j * width] = color(h, 100, 100);
    }
  }
  colorMode(RGB, 255);
  surf.updatePixels(); 
  
  smooth();
  fl = new Particle[puntos];
  for(int i =0;i<puntos;i++)
    fl[i] = new Particle();
}

void draw(){
  image(surf,0,0);
  
  for(int i = 0;i<puntos;i++){
    fl[i].display();
  }
  despliegaBest();
  
  for(int i = 0;i<puntos;i++){
    fl[i].move();
    fl[i].Eval(); 
  }
  guardarDatos(); 
  
}
