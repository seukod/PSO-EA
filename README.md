# PSO-EA: Particle Swarm Optimization vs Evolutionary Algorithm

Comparación experimental entre algoritmos de optimización: PSO (Particle Swarm Optimization) y EA (Evolutionary Algorithm).

## 📁 Estructura del Proyecto

```
PSO-EA/
├── src/                    # Código fuente de los algoritmos
│   ├── pso/               # Implementación de PSO (Processing)
│   │   ├── sketch_PSO.pde
│   │   └── sketch.properties
│   └── ea/                # Implementación de EA (Processing)
│       └── Algoritmo_Evolutivo.pde
│
├── data/                   # Datos experimentales
│   ├── pso/               # Registros CSV de ejecuciones PSO
│   └── ea/                # Registros CSV de ejecuciones EA
│
├── scripts/               # Scripts de análisis (Python)
│   ├── analizar_pso.py    # Análisis estadístico de PSO
│   ├── analizar_ea.py     # Análisis estadístico de EA
│   └── graficos.py        # Generación de gráficos
│
├── notebooks/             # Jupyter Notebooks
│   └── graficos.ipynb     # Análisis y visualización interactiva
│
├── results/              # Resultados y outputs
│   └── images/           # Gráficos generados (.png)
│
└── README.md             # Este archivo
```

## 🚀 Uso

### Análisis PSO
```bash
python scripts/analizar_pso.py
```

### Análisis EA
```bash
python scripts/analizar_ea.py
```

### Generar gráficos
```bash
python scripts/graficos.py
```

### Análisis interactivo (Jupyter)
```bash
jupyter notebook notebooks/graficos.ipynb
```

## 📊 Datos

- **PSO**: Registros CSV en `data/pso/`
- **EA**: Registros CSV en `data/ea/`
- **Resultados**: Imágenes de análisis en `results/images/`

## 🔬 Algoritmos

### PSO (Particle Swarm Optimization)
Implementado en `src/pso/sketch_PSO.pde` (Processing)

### EA (Evolutionary Algorithm)
Implementado en `src/ea/Algoritmo_Evolutivo.pde` (Processing)

---

**Última actualización**: Marzo 2026
