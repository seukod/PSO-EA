PImage surf;
Table table;
long currentSeed;

// ===============================================================
// PARÁMETROS DEL ALGORITMO EVOLUTIVO
// ===============================================================
int puntos = 100; // Tamaño de la población
Individual[] pop; 
float d = 16; // Radio del círculo

float gbestx, gbesty, gbest = Float.MAX_VALUE; 
int evals = 0, evals_to_best = 0; 

// Parámetros Genéticos
float crossoverRate = 0.1;  // 10% de probabilidad de cruzamiento (Baja)
float mutationRate = 0.9;   // 90% de probabilidad de mutación (Alta)
float mutationForce = 55.0; // Píxeles máximos de desplazamiento al mutar
int tournamentSize = 3;     // Presión selectiva

long startTime; 
float timeToBest = 0; 
int iteracion = 0;

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
// VARIABLES PARA CONTROL MANUAL
// ===============================================================
boolean simulacion_activa = true;

// ===============================================================
// TABLA DE EXPORTACIÓN
// ===============================================================
void InitTable() {
  table = new Table();
  table.addColumn("iteracion");
  table.addColumn("semilla");
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
  fila.setLong("semilla", currentSeed);
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

void keyPressed(){
  // Presiona 's' para guardar manualmente
  if (key == 's' || key == 'S') {
    nombreArchivo = carpeta + "ea_manual_seed_" + currentSeed + ".csv";
    saveTable(table, nombreArchivo);
    println("Datos guardados manualmente en: " + nombreArchivo);
  }
}

// ===============================================================
// FUNCIONES PARA MAPA DE CALOR
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

// ===============================================================
// FUNCIÓN PARA CALCULAR DIVERSIDAD
// ===============================================================
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

// ===============================================================
// FUNCIONES PARA DIBUJAR GRÁFICOS
// ===============================================================
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
    x = random(simWidth);
    y = random(simHeight);
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
  child.x = (p1.x + p2.x) / 2.0;
  child.y = (p1.y + p2.y) / 2.0;
  return child;
}

void mutar(Individual ind) {
  if (random(1) < mutationRate) {
    ind.x += random(-mutationForce, mutationForce);
    ind.y += random(-mutationForce, mutationForce);
    ind.x = constrain(ind.x, 0, simWidth);
    ind.y = constrain(ind.y, 0, simHeight);
  }
}

void evolucionar() {
  Individual[] newPop = new Individual[puntos];
  
  // Elitismo: Conservamos al mejor
  Individual elite = new Individual();
  elite.x = gbestx; elite.y = gbesty; elite.fit = gbest;
  newPop[0] = elite;
  
  for (int i = 1; i < puntos; i++) {
    Individual padre1 = torneo();
    Individual hijo;
    
    // Evaluar probabilidad de cruzamiento
    if (random(1) < crossoverRate) {
      Individual padre2 = torneo();
      hijo = cruzar(padre1, padre2);
    } else {
      // Si no hay cruzamiento, el hijo es un clon del padre 1
      hijo = new Individual();
      hijo.x = padre1.x;
      hijo.y = padre1.y;
    }
    
    // Evaluar probabilidad de mutación (aplicada al hijo o al clon)
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
  evals = 0; 
  evals_to_best = 0; 
  iteracion = 0; 
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
}

void despliegaBest() {
  fill(#0000ff);
  ellipse(gbestx, gbesty, d, d);
  textAlign(LEFT, BASELINE);
  PFont f = createFont("Arial", 18, true);
  textFont(f, 18);
  fill(#00ff00);
  text("EA Best fitness: " + str(gbest) + "\nEvals to best: " + str(evals_to_best) + "\nEvals: " + str(evals) + "\nTime to best: " + nf(timeToBest, 0, 2) + "s", 15, 25);
}

void setup() {
  size(1374, 562, P2D);
  smooth();
  frameRate(20); // Reducido a 10 FPS para visualizar mejor el comportamiento
  inicializarSimulacion();
}

void draw() {
  if (!simulacion_activa) return;

  image(surf, 0, 0);
  
  for (int i = 0; i < puntos; i++) {
    pop[i].display();
  }
  despliegaBest();
  dibujarGraficos();
  dibujarAreaBotones();
  
  evolucionar();
  for (int i = 0; i < puntos; i++) {
    pop[i].evaluate();
  }
  
  fitnessHistory.add(gbest);
  diversityHistory.add(calcularDiversidad());
  
  guardarDatos();
}

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
