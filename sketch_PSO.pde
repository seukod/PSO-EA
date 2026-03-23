PImage surf;
Table table;
long currentSeed;
//30 tablas x parametro 
// ===============================================================
int puntos = 100;
Particle[] fl; // arreglo de partículas
float d = 15; // radio del círculo, solo para despliegue
float gbestx, gbesty, gbest = Float.MAX_VALUE; // posición y fitness del mejor global
float w = 3000; //inercia: baja (~50): explotación, alta (~5000): exploración (2000 ok)
float C1 = 30, C2 = 10; // learning factors (C1: own, C2: social) (ok)
int evals = 0, evals_to_best = 0; //número de evaluaciones, sólo para despliegue
float maxv = 3; // max velocidad (modulo)
float time = 0; //tiempo en el que el algoritmo encuentra el minimo
// variables para el temporizador
long startTime; // Tiempo de inicio 
float timeToBest = 0; // Tiempo en el que se encontró el mejor actual

int iteracion = 0;
//Almacenamiento csv
String nombreArchivo;
String carpeta = "registros/";

// ===============================================================
// VARIABLES PARA LAS 30 SIMULACIONES DE 10 SEGUNDOS
// ===============================================================
int simulacion_count = 0;
int max_simulaciones = 30;
int tiempo_simulacion = 10000; // 10 segundos en milisegundos
boolean simulacion_activa = true;

// ===============================================================
// Tabla de exportación de datos
// ===============================================================
void InitTable(){
   table = new Table();
   table.addColumn("iteracion");
   table.addColumn("fitness");
   table.addColumn("semilla");
   table.addColumn("gbestx");
   table.addColumn("gbesty");
   table.addColumn("puntos");
   table.addColumn("inercia");
   table.addColumn("C1");
   table.addColumn("C2");
   table.addColumn("evals");
   table.addColumn("evals to best");
   table.addColumn("tiempo_al_mejor");

}
void guardarDatos(){

  TableRow fila = table.addRow();
  
  fila.setLong("semilla", currentSeed);
  fila.setFloat("fitness", gbest);
  fila.setFloat("gbestx", gbestx);
  fila.setFloat("gbesty", gbesty);
  
  fila.setFloat("tiempo_al_mejor", timeToBest);

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
  // Presiona 's' para guardar manualmente (opcional)
  if (key == 's' || key == 'S') {
    saveTable(table, nombreArchivo);
    println("Datos guardados en: " + nombreArchivo);
  }
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
      
      timeToBest = (millis() - startTime) / 1000.0;// Calcula el tiempo solo cuando hay un récord real
      println("Nuevo Global Best: " + gbest + " a los " + timeToBest + "s");
    }
    
    return fit; 
  }
  
  void move(){
    //actualiza velocidad (fórmula con factores de aprendizaje C1 y C2)
    //vx = vx + random(0,1)*C1*(px - x) + random(0,1)*C2*(gbestx - x);
    //vy = vy + random(0,1)*C1*(py - y) + random(0,1)*C2*(gbesty - y);
    //actualiza velocidad (fórmula con inercia, p.250)
    //vx = w * vx + random(0,1)*(px - x) + random(0,1)*(gbestx - x);
    //vy = w * vy + random(0,1)*(py - y) + random(0,1)*(gbesty - y);
    //actualiza velocidad (fórmula mezclada)
    vx = w * vx + random(0,1)*C1*(px - x) + random(0,1)*C2*(gbestx - x);
    vy = w * vy + random(0,1)*C1*(py - y) + random(0,1)*C2*(gbesty - y);
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
  text("Best fitness: "+str(gbest)+"\nEvals to best: "+str(evals_to_best)+"\nEvals: "+str(evals)+"\nTime to best: "+nf(timeToBest, 0, 2)+"s", 10, 20);

}

// ===============================================================
int obtenerSiguienteNumero(String ruta) {
  File dir = new File(ruta);
  File[] archivos = dir.listFiles();
  int contador = 1;
  
  if (archivos != null) {
    for (File archivo : archivos) {
      if (archivo.getName().startsWith("pso_") && archivo.getName().endsWith(".csv")) {
        contador++;
      }
    }
  }
  return contador;
}

void inicializarSimulacion() {
  
  currentSeed = System.currentTimeMillis();
  randomSeed((int)currentSeed);
  noiseSeed((int)random(1000000));
  
  // 1. Crear la carpeta si no existe
  File f = new File(sketchPath(carpeta));
  if (!f.exists()) {
    f.mkdir();
  }

  // 2. Crear tabla para exportar datos
  InitTable();
  
  //REINICIA VARIABLES
  gbest = Float.MAX_VALUE; 
  gbestx = 0;
  gbesty = 0;
  evals = 0;
  evals_to_best = 0;
  iteracion = 0;
  timeToBest = 0;
  
  // 3. Generar el mapa visual (Rastrigin Landscape)
  surf = createImage(width, height, RGB);
  surf.loadPixels();
  for (int i = 0; i < width; i++) {
    for (int j = 0; j < height; j++) {
      float val = evaluarRastrigin(i, j);
      float colorPixel = map(val, 0, 150, 255, 0); 
      surf.pixels[i + j * width] = color(colorPixel);
    }
  }
  surf.updatePixels(); 

  // 4. Inicializar partículas
  fl = new Particle[puntos];
  for (int i = 0; i < puntos; i++) {
    fl[i] = new Particle();
  }

  
  
  startTime = millis(); // Guarda el milisegundo de inicio
}

void setup() {
  size(1024, 512);
  smooth();
  inicializarSimulacion();
}

void draw(){
  if (!simulacion_activa) {
    return; // Si no hay simulación activa, no hacer nada
  }

  // Verifica si ya pasaron 10 segundos
  long tiempoTranscurrido = millis() - startTime;
  
  if (tiempoTranscurrido >= tiempo_simulacion) {
    // GUARDAR DATOS
    simulacion_count++;
    nombreArchivo = carpeta + "pso_sim" + simulacion_count + "_seed_" + currentSeed + ".csv";
    saveTable(table, nombreArchivo);
    println("=== Simulación " + simulacion_count + " completada ===");
    println("Datos guardados en: " + nombreArchivo);
    println("Mejor fitness: " + gbest);
    println();
    
    // Verificar si llegamos a 30 simulaciones
    if (simulacion_count >= max_simulaciones) {
      println("✓ ¡30 simulaciones completadas!");
      simulacion_activa = false;
      return;
    }
    
    // Reiniciar para la siguiente simulación
    inicializarSimulacion();
  }

  // NORMAL SIMULATION
  image(surf, 0, 0);
  
  for (int i = 0; i < puntos; i++) {
    fl[i].display();
  }
  despliegaBest();
  
  for (int i = 0; i < puntos; i++) {
    fl[i].move();
    fl[i].Eval(); 
  }
  guardarDatos();
}
