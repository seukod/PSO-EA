PImage surf;
Table table;

// ===============================================================
// PARÁMETROS DEL ALGORITMO EVOLUTIVO
// ===============================================================
int puntos = 100; // Tamaño de la población (equivalente a partículas)
Individual[] pop; 
float d = 15; // Radio para el dibujo

float gbestx, gbesty, gbest = Float.MAX_VALUE; 
int evals = 0, evals_to_best = 0; 

// Parámetros Genéticos
float mutationRate = 0.1; // 10% de probabilidad de mutar
float mutationForce = 15.0; // Píxeles máximos de desplazamiento al mutar
int tournamentSize = 3; // Presión selectiva

long startTime; 
float timeToBest = 0; 
int iteracion = 0;

String nombreArchivo;
String carpeta = "registros/";

// ===============================================================
// VARIABLES DE SIMULACIÓN
// ===============================================================
int simulacion_count = 0;
int max_simulaciones = 30;
int tiempo_simulacion = 10000; // 10 segundos
boolean simulacion_activa = true;

// ===============================================================
// TABLA DE EXPORTACIÓN
// ===============================================================
void InitTable() {
  table = new Table();
  table.addColumn("iteracion");
  table.addColumn("fitness");
  table.addColumn("gbestx");
  table.addColumn("gbesty");
  table.addColumn("poblacion");
  table.addColumn("tasa_mutacion");
  table.addColumn("fuerza_mutacion");
  table.addColumn("tam_torneo");
  table.addColumn("evals");
  table.addColumn("evals to best");
  table.addColumn("tiempo_al_mejor");
}

void guardarDatos() {
  TableRow fila = table.addRow();
  fila.setFloat("fitness", gbest);
  fila.setFloat("gbestx", gbestx);
  fila.setFloat("gbesty", gbesty);
  fila.setFloat("tiempo_al_mejor", timeToBest);
  fila.setInt("poblacion", puntos);
  fila.setFloat("tasa_mutacion", mutationRate);
  fila.setFloat("fuerza_mutacion", mutationForce);
  fila.setInt("tam_torneo", tournamentSize);
  fila.setInt("evals", evals);
  fila.setInt("evals to best", evals_to_best);
  fila.setInt("iteracion", iteracion);
  iteracion++;
}

// ===============================================================
// FUNCIÓN DE RASTRIGIN 2D
// ===============================================================
float evaluarRastrigin(float screenX, float screenY) {
  float x = map(screenX, 0, width, -3, 7);
  float y = map(screenY, 0, height, -3, 7);
  float termX = (x * x) - 10 * cos(TWO_PI * x);
  float termY = (y * y) - 10 * cos(TWO_PI * y);
  return 20 + termX + termY; 
}

// ===============================================================
// CLASE INDIVIDUO
// ===============================================================
class Individual {
  float x, y, fit; 
  
  Individual() {
    x = random(width);
    y = random(height);
    fit = Float.MAX_VALUE;
  }
  
  void evaluate() {
    evals++;
    fit = evaluarRastrigin(x, y);
    
    if (fit < gbest) {
      gbest = fit;
      gbestx = x;
      gbesty = y;
      evals_to_best = evals;
      timeToBest = (millis() - startTime) / 1000.0;
      println("EA Nuevo Global Best: " + gbest + " a los " + timeToBest + "s");
    }
  }
  
  void display() {
    color c = surf.get(int(x), int(y)); 
    fill(c);
    stroke(255);
    ellipse(x, y, d, d);
  }
}

// ===============================================================
// OPERADORES EVOLUTIVOS
// ===============================================================
Individual torneo() {
  Individual best = null;
  for (int i = 0; i < tournamentSize; i++) {
    Individual randomInd = pop[int(random(puntos))];
    if (best == null || randomInd.fit < best.fit) {
      best = randomInd;
    }
  }
  return best;
}

Individual cruzar(Individual p1, Individual p2) {
  Individual child = new Individual();
  // Cruzamiento aritmético: punto medio entre los padres
  child.x = (p1.x + p2.x) / 2.0;
  child.y = (p1.y + p2.y) / 2.0;
  return child;
}

void mutar(Individual ind) {
  if (random(1) < mutationRate) {
    // Ruido aleatorio a la posición
    ind.x += random(-mutationForce, mutationForce);
    ind.y += random(-mutationForce, mutationForce);
    
    // Mantener dentro de los límites
    ind.x = constrain(ind.x, 0, width);
    ind.y = constrain(ind.y, 0, height);
  }
}

void evolucionar() {
  Individual[] newPop = new Individual[puntos];
  
  // Elitismo: Guardar al mejor de la generación actual
  Individual elite = new Individual();
  elite.x = gbestx; elite.y = gbesty; elite.fit = gbest;
  newPop[0] = elite;
  
  // Generar el resto de la población
  for (int i = 1; i < puntos; i++) {
    Individual padre1 = torneo();
    Individual padre2 = torneo();
    Individual hijo = cruzar(padre1, padre2);
    mutar(hijo);
    newPop[i] = hijo;
  }
  
  pop = newPop;
}

// ===============================================================
// INICIALIZACIÓN Y BUCLE PRINCIPAL
// ===============================================================
void inicializarSimulacion() {
  File f = new File(sketchPath(carpeta));
  if (!f.exists()) f.mkdir();

  InitTable();

  surf = createImage(width, height, RGB);
  surf.loadPixels();
  for (int i = 0; i < width; i++) {
    for (int j = 0; j < height; j++) {
      float val = evaluarRastrigin(i, j);
      surf.pixels[i + j * width] = color(map(val, 0, 150, 255, 0));
    }
  }
  surf.updatePixels(); 

  pop = new Individual[puntos];
  for (int i = 0; i < puntos; i++) {
    pop[i] = new Individual();
    pop[i].evaluate(); // Evaluación inicial
  }

  gbestx = pop[0].x; gbesty = pop[0].y; gbest = pop[0].fit;
  evals = 0; evals_to_best = 0; iteracion = 0; timeToBest = 0;
  startTime = millis(); 
}

void despliegaBest() {
  fill(#0000ff);
  ellipse(gbestx, gbesty, d, d);
  fill(#00ff00);
  textSize(15);
  text("EA Best fitness: " + str(gbest) + "\nEvals to best: " + str(evals_to_best) + "\nGenerations: " + str(iteracion) + "\nTime to best: " + nf(timeToBest, 0, 2) + "s", 10, 20);
}

void setup() {
  size(1024, 512);
  smooth();
  inicializarSimulacion();
}

void draw() {
  if (!simulacion_activa) return;

  if (millis() - startTime >= tiempo_simulacion) {
    simulacion_count++;
    nombreArchivo = carpeta + "ea_tabla" + simulacion_count + ".csv";
    saveTable(table, nombreArchivo);
    println("=== Simulación EA " + simulacion_count + " completada ===");
    
    if (simulacion_count >= max_simulaciones) {
      println("✓ ¡30 simulaciones completadas!");
      simulacion_activa = false;
      return;
    }
    inicializarSimulacion();
  }

  image(surf, 0, 0);
  
  // Dibujar población actual
  for (int i = 0; i < puntos; i++) {
    pop[i].display();
  }
  despliegaBest();
  
  // Proceso evolutivo por cada frame (1 generación)
  evolucionar();
  for (int i = 0; i < puntos; i++) {
    pop[i].evaluate();
  }
  
  guardarDatos();
}
