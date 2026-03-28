PImage surf;
Table table;
long currentSeed;
//30 tablas x parametro 
// ===============================================================
int puntos = 100;
Particle[] fl; // arreglo de partículas
float d = 15; // radio del círculo, solo para despliegue
float gbestx, gbesty, gbest = Float.MAX_VALUE; // posición y fitness del mejor global
// SOLUCIÓN 3: Sintonía de Inercia - Valores teóricos estándar de PSO
float w = 0.9;  // Inercia inicial (valores estándar: 0.4-0.9)
float C1 = 2.0, C2 = 2.0; // Learning factors estándar (cognitivo y social)
int evals = 0, evals_to_best = 0; //número de evaluaciones, sólo para despliegue
float maxv = 50; // Velocidad máxima aumentada para permitir mejor exploración
float time = 0; //tiempo en el que el algoritmo encuentra el minimo
// variables para el temporizador
long startTime; // Tiempo de inicio
float timeToBest = 0; // Tiempo en el que se encontró el mejor actual

float decay = 0.99; // Decaimiento suave estándar (~1% por iteración)
float decay_fast = 0.97; // Decaimiento moderado si no hay mejora (~3% por iteración)
float w_min = 0.4;   // Inercia mínima estándar para explotación final
float w_inicial = 0;  // Para guardar valor inicial

int iteracion = 0;
int iteraciones_sin_mejora = 0;
int patience = 150; // Iteraciones sin mejora antes de detener
float gbest_anterior = Float.MAX_VALUE;
//Almacenamiento csv
String nombreArchivo;
String carpeta = "registros/";

// ===============================================================
// VARIABLES PARA LAS 30 SIMULACIONES DE 10 SEGUNDOS
// ===============================================================
int simulacion_count = 0;
int max_simulaciones = 30;
int max_iteraciones = 500; // Número máximo de iteraciones por simulación
boolean simulacion_activa = true;

// ===============================================================
// Tabla de exportación de datos
// ===============================================================
void InitTable(){
   table = new Table();
   table.addColumn("iteracion");
   table.addColumn("fitness");
   table.addColumn("fitness_promedio");
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
  // Calcular promedio de fitness de toda la población
  float sumaFitness = 0;
  for (int i = 0; i < puntos; i++) {
    sumaFitness += fl[i].fit;
  }
  float fitnessPromedio = sumaFitness / puntos;

  TableRow fila = table.addRow();
  
  fila.setLong("semilla", currentSeed);
  fila.setFloat("fitness", gbest);
  fila.setFloat("fitness_promedio", fitnessPromedio);
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
  
  // SOLUCIÓN 1: Inicialización correcta - Evaluar inmediatamente la posición inicial
  Particle(){
    x = random (width); y = random(height);
    vx = random(-1,1) ; vy = random(-1,1);

    // Evaluar posición inicial INMEDIATAMENTE para evitar desfase
    fit = evaluarRastrigin(x, y);
    evals++;

    // Inicializar personal best con la posición actual
    pfit = fit;
    px = x;
    py = y;
  }
  
  float Eval(){
    evals++;
    fit = evaluarRastrigin(x, y);

    // Actualizar personal best si encontramos mejor fitness
    if(fit < pfit){
      pfit = fit;
      px = x;
      py = y;
    }

    // Actualizar global best si encontramos mejor fitness
    if (fit < gbest){
      gbest = fit;
      gbestx = x;
      gbesty = y;
      evals_to_best = evals;

      timeToBest = (millis() - startTime) / 1000.0;
      println("Nuevo Global Best: " + gbest + " a los " + timeToBest + "s");
    }

    return fit;
  }
  
  void move(){
    // Actualiza velocidad (fórmula estándar PSO con inercia)
    vx = w * vx + random(0,1)*C1*(px - x) + random(0,1)*C2*(gbestx - x);
    vy = w * vy + random(0,1)*C1*(py - y) + random(0,1)*C2*(gbesty - y);

    // Trunca velocidad a maxv (velocity clamping)
    float modu = sqrt(vx*vx + vy*vy);
    if (modu > maxv){
      vx = vx/modu*maxv;
      vy = vy/modu*maxv;
    }

    // Update position
    x = x + vx;
    y = y + vy;

    // SOLUCIÓN 3: Clamping en vez de rebote - Mantiene partículas dentro del espacio
    // sin invertir velocidad (mejor para convergencia hacia gbest)
    if (x > width) { x = width; vx = 0; }
    if (x < 0) { x = 0; vx = 0; }
    if (y > height) { y = height; vy = 0; }
    if (y < 0) { y = 0; vy = 0; }
  }
  
  void display(){
    color c = surf.get(int(x),int(y));
    fill(c);
    ellipse (x,y,d,d);
    stroke(#ff0000);
    // Reducir multiplicador para que las colas se vean proporcionadas
    line(x,y,x-2*vx,y-2*vy);
  }
} 

void despliegaBest(){
  // Dibujar referencia (0,0) en coordenadas matemáticas
  float refX = map(0, -3, 7, 0, width);  // Coordenada (0,0) mapeada a pantalla
  float refY = map(0, -3, 7, 0, height);
  fill(#9400D3);  // Morado
  ellipse(refX, refY, d, d);
  
  // Dibujar mejor global
  fill(#0000ff);
  ellipse(gbestx, gbesty, d, d);
  PFont f = createFont("Arial",16,true);
  textFont(f,15);
  fill(#00ff00);
  text("Best fitness: "+str(gbest)+"\nEvals to best: "+str(evals_to_best)+"\nEvals: "+str(evals)+"\nIteraciones: "+str(iteracion)+"/"+str(max_iteraciones)+"\nTime to best: "+nf(timeToBest, 0, 2)+"s", 10, 20);

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
  w = 0.9; // Reiniciar inercia al valor inicial estándar
  gbest = Float.MAX_VALUE;
  gbest_anterior = Float.MAX_VALUE;
  gbestx = 0;
  gbesty = 0;
  evals = 0;
  evals_to_best = 0;
  iteracion = 0;
  iteraciones_sin_mejora = 0;
  timeToBest = 0;
  w_inicial = w; // Guardar valor inicial para referencia
  
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

  // Verifica convergencia: si 150 iteraciones sin mejora O máximo de iteraciones
  if (iteraciones_sin_mejora >= patience || iteracion >= max_iteraciones) {
    // GUARDAR DATOS
    simulacion_count++;
    nombreArchivo = carpeta + "pso_sim" + simulacion_count + "_seed_" + currentSeed + ".csv";
    saveTable(table, nombreArchivo);
    println("=== Simulación " + simulacion_count + " completada ===");
    println("Iteraciones totales: " + iteracion);
    println("Iteraciones sin mejora: " + iteraciones_sin_mejora);
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

  // SOLUCIÓN 2: Orden correcto del ciclo de vida del PSO
  // Paso 1: EVALUAR todas las partículas (actualiza fit, pfit, gbest)
  for (int i = 0; i < puntos; i++) {
    fl[i].Eval();
  }

  // Paso 2: DISPLAY del estado actual (ya con información actualizada)
  image(surf, 0, 0);
  for (int i = 0; i < puntos; i++) {
    fl[i].display();
  }
  despliegaBest();

  // Paso 3: MOVER todas las partículas usando la información actualizada
  for (int i = 0; i < puntos; i++) {
    fl[i].move();
  }

  // Contar iteraciones sin mejora
  if (gbest < gbest_anterior) {
    iteraciones_sin_mejora = 0;
    gbest_anterior = gbest;
  } else {
    iteraciones_sin_mejora++;
  }

  // DECAIMIENTO DINÁMICO Y ADAPTATIVO DE LA INERCIA
  // Si hay mejora: decaimiento normal (exponencial)
  // Si NO hay mejora: decaimiento más agresivo (cambio de fase)
  if (iteraciones_sin_mejora > 0 && iteraciones_sin_mejora % 20 == 0) {
    // Cada 20 iteraciones sin mejora, aplicar decaimiento más fuerte
    if (w > w_min) {
      w *= decay_fast;
    }
  } else if (w > w_min) {
    // Decaimiento regular
    w *= decay;
  }

  // Asegurar que w nunca baje del mínimo
  if (w < w_min) {
    w = w_min;
  }

  guardarDatos();
}
