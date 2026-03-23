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
    if (best == null || randomInd.fit
