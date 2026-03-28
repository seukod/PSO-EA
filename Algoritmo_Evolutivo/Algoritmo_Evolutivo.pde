PImage surf;
Table table;
long currentSeed; // Variable para rastrear la semilla actual

// ===============================================================
// PARÁMETROS DEL ALGORITMO EVOLUTIVO
// ===============================================================
int puntos = 100; // Tamaño de la población (equivalente a partículas)
Individual[] pop; 
float d = 15; // Radio para el dibujo

float gbestx, gbesty, gbest = Float.MAX_VALUE; 
int evals = 0, evals_to_best = 0; 

// Parámetros Genéticos
float mutationRate = 0.4;   // Tasa inicial de mutación (será reducida dinámicamente)
float mutationForce = 55.0; // Fuerza inicial de mutación (será reducida dinámicamente)
int tournamentSize = 5;     // Presión selectiva

// Decaimiento dinámico de mutación (cooling schedule)
float mutationDecay = 0.995;  // Factor de decaimiento por iteración (0.5% por iteración)
float mutationRateMin = 0.05; // Tasa mínima de mutación (nunca baja de esto)
float mutationForceMin = 2.0; // Fuerza mínima de mutación

long startTime; 
float timeToBest = 0; 
int iteracion = 0;
int iteraciones_sin_mejora = 0;
int patience = 150; // Iteraciones sin mejora antes de detener
float gbest_anterior = Float.MAX_VALUE;

String nombreArchivo;
String carpeta = "registros/";

// ===============================================================
// VARIABLES DE SIMULACIÓN
// ===============================================================
int simulacion_count = 0;
int max_simulaciones = 30;
int max_iteraciones = 2000; // Máximo de iteraciones como respaldo
boolean simulacion_activa = true;

// ===============================================================
// TABLA DE EXPORTACIÓN
// ===============================================================
void InitTable() {
  table = new Table();
  table.addColumn("iteracion");
  table.addColumn("semilla"); // Nueva columna
  table.addColumn("fitness");
  table.addColumn("fitness_promedio"); // Promedio de la población
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
  // Calcular promedio de fitness de toda la población
  float sumaFitness = 0;
  for (int i = 0; i < puntos; i++) {
    sumaFitness += pop[i].fit;
  }
  float fitnessPromedio = sumaFitness / puntos;
  
  TableRow fila = table.addRow();
  fila.setFloat("fitness", gbest);
  fila.setFloat("fitness_promedio", fitnessPromedio);
  fila.setLong("semilla", currentSeed); // Guardamos la semilla en cada fila
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
  // Cruzamiento BLX-alpha: menos explorativo para más explotación
  float alpha = 0.2; // Factor de exploración (reducido)
  float min_x = min(p1.x, p2.x);
  float max_x = max(p1.x, p2.x);
  float min_y = min(p1.y, p2.y);
  float max_y = max(p1.y, p2.y);
  
  float range_x = max_x - min_x;
  float range_y = max_y - min_y;
  
  // Expande el rango de cruzamiento para mayor exploración
  child.x = random(min_x - alpha * range_x, max_x + alpha * range_x);
  child.y = random(min_y - alpha * range_y, max_y + alpha * range_y);
  
  // Mantener dentro de límites
  child.x = constrain(child.x, 0, width);
  child.y = constrain(child.y, 0, height);
  
  return child;
}

void mutar(Individual ind) {
  // Mayor tasa de mutación para mejor exploración
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
  
  // Elitismo: Guardar al mejor pero CON MUTACIÓN para diversidad
  Individual elite = new Individual();
  elite.x = gbestx;
  elite.y = gbesty;
  elite.fit = gbest;
  
  // MUTACIÓN DE ÉLITE: pequeña probabilidad de diversificar
  if (random(1) < 0.1) {  // 10% de probabilidad de mutar la élite
    if (random(1) < mutationRate * 0.5) {
      elite.x += random(-mutationForce * 0.3, mutationForce * 0.3);
      elite.y += random(-mutationForce * 0.3, mutationForce * 0.3);
      elite.x = constrain(elite.x, 0, width);
      elite.y = constrain(elite.y, 0, height);
      elite.evaluate();
    }
  }
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
  currentSeed = System.currentTimeMillis();
  randomSeed((int)currentSeed);
  noiseSeed((int)random(1000000));
  
  File f = new File(sketchPath(carpeta));
  if (!f.exists()) f.mkdir();

  InitTable();

  gbest = Float.MAX_VALUE; 
  gbest_anterior = Float.MAX_VALUE;
  evals = 0; 
  evals_to_best = 0; 
  iteracion = 0;
  iteraciones_sin_mejora = 0;
  timeToBest = 0;
  
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
    pop[i].evaluate();
  }

  startTime = millis(); 
  
  // Mensajes en español para la consola
  println("==================================================");
  println("INICIANDO SIMULACIÓN #" + (simulacion_count + 1) + " de 30");
  println(">>> CONFIGURACIÓN DE PARÁMETROS:");
  println("  - Tasa de Mutación: " + mutationRate);
  println("  - Fuerza de Mutación: " + mutationForce + " píxeles");
  println("  - Tamaño del Torneo: " + tournamentSize + " individuos");
  println("  - Semilla Actual: " + currentSeed);
  println("==================================================");
}

void despliegaBest() {
  fill(#0000ff);
  ellipse(gbestx, gbesty, d, d);
  fill(#00ff00);
  textSize(15);
  text("EA Best fitness: " + str(gbest) + "\nEvals to best: " + str(evals_to_best) + "\nIteraciones: " + str(iteracion) + "\nSin mejora: " + str(iteraciones_sin_mejora) + "/" + str(patience) + "\nTime to best: " + nf(timeToBest, 0, 2) + "s" + "\nMut Rate: " + nf(mutationRate, 0, 3) + " | Mut Force: " + nf(mutationForce, 0, 1), 10, 20);
}

void setup() {
  size(1024, 512);
  smooth();
  inicializarSimulacion();
}

void draw() {
  if (!simulacion_activa) return;

  // Verifica convergencia: si 150 iteraciones sin mejora O máximo de iteraciones
  if (iteraciones_sin_mejora >= patience || iteracion >= max_iteraciones) {
    simulacion_count++;
    nombreArchivo = carpeta + "ea_sim" + simulacion_count + "_seed_" + currentSeed + ".csv";
    saveTable(table, nombreArchivo);
    println("=== Simulación EA " + simulacion_count + " completada ===");
    println("Iteraciones totales: " + iteracion);
    println("Iteraciones sin mejora: " + iteraciones_sin_mejora);
    println("Datos guardados en: " + nombreArchivo);
    println("Mejor fitness: " + gbest);
    println();
    
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
  
  // Contar iteraciones sin mejora
  if (gbest < gbest_anterior) {
    iteraciones_sin_mejora = 0;
    gbest_anterior = gbest;
  } else {
    iteraciones_sin_mejora++;
  }
  
  guardarDatos();
  
  // Decaimiento dinámico de mutación: balance exploración/explotación
  if (mutationRate > mutationRateMin) {
    mutationRate *= mutationDecay;
  }
  if (mutationForce > mutationForceMin) {
    mutationForce *= mutationDecay;
  }
}
