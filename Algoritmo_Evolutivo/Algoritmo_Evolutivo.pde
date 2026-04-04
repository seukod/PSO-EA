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
float crossoverRate = 0.8;  // Tasa de cruzamiento (80%)
float mutationRate = 0.15;   // Tasa inicial de mutación (será reducida dinámicamente)
float mutationForce = 30.0; // Fuerza inicial de mutación (será reducida dinámicamente)
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
// VARIABLES PARA GRÁFICOS Y VISUALIZACIÓN (HD - 1.25x)
// ===============================================================
ArrayList<Float> fitnessHistory; // Historial de fitness
ArrayList<Float> diversityHistory; // Historial de diversidad
boolean mostrarMapaCalor = false; // Toggle para mapa de calor
int simWidth = 1024; // Ancho de la simulación
int simHeight = 512; // Alto de la simulación
int graphWidth = 350; // Ancho de la sección de gráficos
int buttonAreaHeight = 50; // Altura del área de botones
int buttonW = 140; // Ancho del botón
int buttonH = 32; // Alto del botón

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
// FUNCIONES PARA MAPA DE CALOR Y GRAFICOS
// ===============================================================
void generarSuperficie() {
  surf = createImage(simWidth, simHeight, RGB);
  surf.loadPixels();

  for (int i = 0; i < simWidth; i++) {
    for (int j = 0; j < simHeight; j++) {
      float val = evaluarRastrigin(i, j);

      if (mostrarMapaCalor) {
        float normalizado = map(val, 0, 150, 0, 1);
        color c = lerpColor(color(0, 0, 255), color(255, 0, 0), normalizado);
        surf.pixels[i + j * simWidth] = c;
      } else {
        float colorPixel = map(val, 0, 150, 255, 0);
        surf.pixels[i + j * simWidth] = color(colorPixel);
      }
    }
  }
  surf.updatePixels();
}

float calcularDiversidad() {
  float centroX = 0, centroY = 0;
  for (int i = 0; i < puntos; i++) {
    centroX += pop[i].x;
    centroY += pop[i].y;
  }
  centroX /= puntos;
  centroY /= puntos;

  float distanciaTotal = 0;
  for (int i = 0; i < puntos; i++) {
    float dx = pop[i].x - centroX;
    float dy = pop[i].y - centroY;
    distanciaTotal += sqrt(dx*dx + dy*dy);
  }
  return distanciaTotal / puntos;
}

void dibujarGraficos() {
  int graphX = simWidth + 15;
  int graph1Y = 15;
  int graph2Y = simHeight / 2 + 15;
  int graphH = simHeight / 2 - 30;
  int graphW = graphWidth - 30;

  fill(240);
  noStroke();
  rect(simWidth, 0, graphWidth, simHeight);

  dibujarGraficoConvergencia(graphX, graph1Y, graphW, graphH);
  dibujarGraficoDiversidad(graphX, graph2Y, graphW, graphH);
}

void dibujarGraficoConvergencia(int x, int y, int w, int h) {
  stroke(0);
  strokeWeight(2);
  noFill();
  rect(x, y, w, h);

  fill(0);
  textAlign(LEFT);
  textSize(14);
  text("Convergencia (Fitness)", x + 10, y + 22);

  if (fitnessHistory.size() < 2) return;

  float minFit = Float.MAX_VALUE;
  float maxFit = Float.MIN_VALUE;
  for (Float f : fitnessHistory) {
    if (f < minFit) minFit = f;
    if (f > maxFit) maxFit = f;
  }
  if (maxFit - minFit < 0.001) maxFit = minFit + 1;

  stroke(0, 100, 255);
  strokeWeight(2);
  noFill();
  beginShape();
  for (int i = 0; i < fitnessHistory.size(); i++) {
    float px = map(i, 0, max(fitnessHistory.size() - 1, 1), x + 10, x + w - 10);
    float py = map(fitnessHistory.get(i), minFit, maxFit, y + h - 10, y + 35);
    vertex(px, py);
  }
  endShape();

  fill(0);
  textAlign(RIGHT);
  textSize(11);
  text(nf(maxFit, 0, 2), x + w - 10, y + 40);
  text(nf(minFit, 0, 2), x + w - 10, y + h - 12);
}

void dibujarGraficoDiversidad(int x, int y, int w, int h) {
  stroke(0);
  strokeWeight(2);
  noFill();
  rect(x, y, w, h);

  fill(0);
  textAlign(LEFT);
  textSize(14);
  text("Diversidad (Dispersión)", x + 10, y + 22);

  if (diversityHistory.size() < 2) return;

  float minDiv = Float.MAX_VALUE;
  float maxDiv = Float.MIN_VALUE;
  for (Float d : diversityHistory) {
    if (d < minDiv) minDiv = d;
    if (d > maxDiv) maxDiv = d;
  }
  if (maxDiv - minDiv < 0.001) maxDiv = minDiv + 1;

  stroke(255, 100, 0);
  strokeWeight(2);
  noFill();
  beginShape();
  for (int i = 0; i < diversityHistory.size(); i++) {
    float px = map(i, 0, max(diversityHistory.size() - 1, 1), x + 10, x + w - 10);
    float py = map(diversityHistory.get(i), minDiv, maxDiv, y + h - 10, y + 35);
    vertex(px, py);
  }
  endShape();

  fill(0);
  textAlign(RIGHT);
  textSize(11);
  text(nf(maxDiv, 0, 2), x + w - 10, y + 40);
  text(nf(minDiv, 0, 2), x + w - 10, y + h - 12);
}

// ===============================================================
// FUNCIÓN DE RASTRIGIN 2D
// ===============================================================
float evaluarRastrigin(float screenX, float screenY) {
  float x = map(screenX, 0, simWidth, -3, 7);
  float y = map(screenY, 0, simHeight, -3, 7);
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
  child.x = constrain(child.x, 0, simWidth);
  child.y = constrain(child.y, 0, simHeight);
  
  return child;
}

void mutar(Individual ind) {
  // Mayor tasa de mutación para mejor exploración
  if (random(1) < mutationRate) {
    // Ruido aleatorio a la posición
    ind.x += random(-mutationForce, mutationForce);
    ind.y += random(-mutationForce, mutationForce);
    
    // Mantener dentro de los límites
    ind.x = constrain(ind.x, 0, simWidth);
    ind.y = constrain(ind.y, 0, simHeight);
  }
}

void evolucionar() {
  Individual[] newPop = new Individual[puntos];
  
  /* --- Elitismo desactivado temporalmente ---
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
      elite.x = constrain(elite.x, 0, simWidth);
      elite.y = constrain(elite.y, 0, simHeight);
      elite.evaluate();
    }
  }
  newPop[0] = elite;
  */
  
  // Generar toda la población (se inicia de 0 al quitar elitismo)
  for (int i = 0; i < puntos; i++) {
    Individual padre1 = torneo();
    Individual hijo;
    
    // Aplicar cruzamiento con probabilidad
    if (random(1) < crossoverRate) {
      Individual padre2 = torneo();
      hijo = cruzar(padre1, padre2);
    } else {
      // Si no se cruza, el hijo es un clon del padre1
      hijo = new Individual();
      hijo.x = padre1.x;
      hijo.y = padre1.y;
    }
    
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
  
  fitnessHistory = new ArrayList<Float>();
  diversityHistory = new ArrayList<Float>();

  generarSuperficie();

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
  println("  - Tasa de Cruzamiento: " + crossoverRate);
  println("  - Tasa de Mutación: " + mutationRate);
  println("  - Fuerza de Mutación: " + mutationForce + " píxeles");
  println("  - Tamaño del Torneo: " + tournamentSize + " individuos");
  println("  - Semilla Actual: " + currentSeed);
  println("==================================================");
}

void despliegaBest() {
  fill(#0000ff);
  ellipse(gbestx, gbesty, d, d);
  textAlign(LEFT, BASELINE);
  fill(#00ff00);
  textSize(15);
  text("EA Best fitness: " + str(gbest) + "\nEvals to best: " + str(evals_to_best) + "\nIteraciones: " + str(iteracion) + "\nSin mejora: " + str(iteraciones_sin_mejora) + "/" + str(patience) + "\nTime to best: " + nf(timeToBest, 0, 2) + "s" + "\nMut Rate: " + nf(mutationRate, 0, 3) + " | Mut Force: " + nf(mutationForce, 0, 1), 15, 25);
}

void setup() {
  size(1374, 562, P2D);
  smooth();
  frameRate(20);
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
  dibujarGraficos();
  dibujarAreaBotones();
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
  
  fitnessHistory.add(gbest);
  diversityHistory.add(calcularDiversidad());

  guardarDatos();
  
  // Decaimiento dinámico de mutación: balance exploración/explotación
  if (mutationRate > mutationRateMin) {
    mutationRate *= mutationDecay;
  }
  if (mutationForce > mutationForceMin) {
    mutationForce *= mutationDecay;
  }
}

// ===============================================================
// INTERACCIÓN Y CONTROLES (UI)
// ===============================================================
void dibujarAreaBotones() {
  fill(220);
  noStroke();
  rect(0, simHeight, simWidth + graphWidth, buttonAreaHeight);

  int buttonY = simHeight + 10;
  int button1X = 20;
  int button2X = button1X + buttonW + 20;

  boolean mouseOverButton1 = mouseX > button1X && mouseX < button1X + buttonW &&
                             mouseY > buttonY && mouseY < buttonY + buttonH;

  stroke(0);
  strokeWeight(2);
  if (mouseOverButton1) fill(180); else fill(255);
  rect(button1X, buttonY, buttonW, buttonH, 5);

  fill(0);
  textAlign(CENTER, CENTER);
  textSize(13);
  if (mostrarMapaCalor) text("Vista Normal", button1X + buttonW/2, buttonY + buttonH/2);
  else text("Mapa de Calor", button1X + buttonW/2, buttonY + buttonH/2);

  boolean mouseOverButton2 = mouseX > button2X && mouseX < button2X + buttonW &&
                             mouseY > buttonY && mouseY < buttonY + buttonH;

  stroke(0);
  strokeWeight(2);
  if (mouseOverButton2) fill(180); else fill(255);
  rect(button2X, buttonY, buttonW, buttonH, 5);

  fill(0);
  textAlign(CENTER, CENTER);
  textSize(13);
  text("Reiniciar", button2X + buttonW/2, buttonY + buttonH/2);
}

void mousePressed() {
  int buttonY = simHeight + 12;
  int button1X = 20;
  int button2X = button1X + buttonW + 20;

  if (mouseX > button1X && mouseX < button1X + buttonW &&
      mouseY > buttonY && mouseY < buttonY + buttonH) {
    mostrarMapaCalor = !mostrarMapaCalor;
    generarSuperficie();
  }

  if (mouseX > button2X && mouseX < button2X + buttonW &&
      mouseY > buttonY && mouseY < buttonY + buttonH) {
    println("=== Reiniciando simulación EA ===");
    inicializarSimulacion();
  }
}

void keyPressed(){
  // Presiona 's' para guardar manualmente en cualquier momento
  if (key == 's' || key == 'S') {
    nombreArchivo = carpeta + "ea_manual_seed_" + currentSeed + ".csv";
    saveTable(table, nombreArchivo);
    println(">>> Datos guardados manualmente en: " + nombreArchivo);
  }
}
