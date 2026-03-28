#!/usr/bin/env python3
"""
Script de Análisis EA - 30 Ejecuciones Independientes
=======================================================
Genera gráfico de convergencia con mejor caso vs promedio.

Uso desde terminal:
    python analizar_ea.py          # Genera gráfico de convergencia
    python analizar_ea.py --help   # Ayuda
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
import glob
import warnings
import argparse
import sys

warnings.filterwarnings('ignore')

# ============================================================================
# CONFIGURACIÓN
# ============================================================================
RUTA_REGISTROS = "Algoritmo_Evolutivo/registros"
PATRON_ARCHIVOS = "ea_sim*.csv"
SALIDA_GRAFICO = "convergencia_ea.png"

# ============================================================================
# FUNCIONES
# ============================================================================

def cargar_archivos(ruta_registros, patron):
    """Carga todos los archivos CSV que coincidan con el patrón."""
    patron_completo = os.path.join(ruta_registros, patron)
    archivos = sorted(glob.glob(patron_completo))

    if not archivos:
        print(f"❌ ERROR: No se encontraron archivos con patrón '{patron}'")
        print(f"   Buscando en: {ruta_registros}/")
        return [], []

    print(f"✓ Encontrados {len(archivos)} archivos CSV")

    dfs = []
    longitudes = []

    for i, archivo in enumerate(archivos):
        try:
            df = pd.read_csv(archivo)
            dfs.append(df)
            longitudes.append(len(df))
            print(f"  [{i+1:02d}] {os.path.basename(archivo):25s} → {len(df):6d} iteraciones")
        except Exception as e:
            print(f"  [ERROR] {archivo}: {e}")

    return dfs, longitudes


def alinear_datos(dfs, min_iters):
    """Trunca todos los dataframes a la longitud mínima."""
    return [df.iloc[:min_iters].reset_index(drop=True) for df in dfs]


def graficar_convergencia(dfs_alineados, output_path):
    """Genera 2 gráficos de convergencia: uno con escala lineal y otro logarítmica."""
    # Calcular métricas de cada iteración
    gbest_mejor = None  # Mejor gbest global entre todas las ejecuciones
    fitness_pop_promedio = None  # Promedio del fitness poblacional entre las 30 ejecuciones
    
    for df in dfs_alineados:
        if gbest_mejor is None:
            gbest_mejor = np.array(df['fitness'].values, copy=True)
            fitness_pop_promedio = np.array(df['fitness_promedio'].values, copy=True)
        else:
            # Mejor gbest global: tomar el mínimo entre iteraciones
            gbest_mejor = np.minimum(gbest_mejor, df['fitness'].values)
            # Promedio poblacional: acumular para promediar después
            fitness_pop_promedio += df['fitness_promedio'].values
    
    # Promediar el fitness poblacional (dividir por cantidad de ejecuciones)
    fitness_pop_promedio = fitness_pop_promedio / len(dfs_alineados)
    
    # Reemplazar ceros exactos con un valor muy pequeño
    gbest_mejor = np.where(gbest_mejor == 0, 1e-4, gbest_mejor)
    fitness_pop_promedio = np.where(fitness_pop_promedio == 0, 1e-4, fitness_pop_promedio)
    
    iteraciones = np.arange(len(gbest_mejor))
    
    # =========== GRÁFICO 1: ESCALA LINEAL ===========
    fig, ax = plt.subplots(figsize=(12, 7))
    
    ax.plot(iteraciones, fitness_pop_promedio, color='#0066cc', linewidth=2.5, label='Caso Promedio (Promedio Poblacional de 30 ejecuciones)', zorder=2)
    ax.plot(iteraciones, gbest_mejor, color='#cc0000', linewidth=2.5, label='Mejor Caso (Mejor Global)', zorder=2)
    ax.fill_between(iteraciones, fitness_pop_promedio, gbest_mejor, alpha=0.1, color='gray', label='Brecha (Exploración vs Explotación)')
    
    ax.set_xlabel("Iteraciones", fontsize=12, fontweight='bold')
    ax.set_ylabel("Fitness", fontsize=12, fontweight='bold')
    ax.set_title("Convergencia EA - Caso Promedio vs Mejor Caso (Escala Lineal)", fontsize=14, fontweight='bold', pad=15)
    ax.grid(True, alpha=0.3, linestyle='--')
    ax.legend(fontsize=11, loc='best', framealpha=0.95)
    ax.set_xlim(left=0)
    
    plt.tight_layout()
    # Guardar con sufijo _lineal
    output_lineal = output_path.replace('.png', '_lineal.png')
    plt.savefig(output_lineal, dpi=300, bbox_inches='tight')
    print(f"✓ Gráfico guardado: {output_lineal}")
    plt.close()
    
    # =========== GRÁFICO 2: ESCALA LOGARÍTMICA ===========
    fig, ax = plt.subplots(figsize=(12, 7))
    
    ax.plot(iteraciones, fitness_pop_promedio, color='#0066cc', linewidth=2.5, label='Caso Promedio (Promedio Poblacional de 30 ejecuciones)', zorder=2)
    ax.plot(iteraciones, gbest_mejor, color='#cc0000', linewidth=2.5, label='Mejor Caso (Mejor Global)', zorder=2)
    ax.fill_between(iteraciones, fitness_pop_promedio, gbest_mejor, alpha=0.1, color='gray', label='Brecha (Exploración vs Explotación)')
    
    ax.set_xlabel("Iteraciones", fontsize=12, fontweight='bold')
    ax.set_ylabel("Fitness (escala logarítmica)", fontsize=12, fontweight='bold')
    ax.set_title("Convergencia EA - Caso Promedio vs Mejor Caso (Escala Logarítmica)", fontsize=14, fontweight='bold', pad=15)
    ax.set_yscale('log')
    ax.set_ylim(0.001, fitness_pop_promedio.max() * 10)
    ax.grid(True, alpha=0.3, linestyle='--', which='both')
    ax.legend(fontsize=11, loc='best', framealpha=0.95)
    ax.set_xlim(left=0)
    
    plt.tight_layout()
    # Guardar con sufijo _log
    output_log = output_path.replace('.png', '_log.png')
    plt.savefig(output_log, dpi=300, bbox_inches='tight')
    print(f"✓ Gráfico guardado: {output_log}")
    plt.close()


def imprimir_resumen(dfs_alineados):
    """Imprime un resumen de los resultados."""
    print("\n" + "="*70)
    print("ANÁLISIS COMPLETADO")
    print("="*70)
    
    # Extraer fitness final y mejor de cada ejecución
    fitness_finales = [df['fitness'].iloc[-1] for df in dfs_alineados]
    fitness_mejores = [df['fitness'].min() for df in dfs_alineados]
    
    print(f"\n📊 RESULTADOS DE LAS 30 EJECUCIONES:")
    print(f"   Fitness promedio final: {np.mean(fitness_finales):.6f}")
    print(f"   Fitness mejor (min de todos): {min(fitness_mejores):.6f}")
    print(f"   Fitness peor (max de finales): {max(fitness_finales):.6f}")
    print(f"   Iteraciones por ejecución: {len(dfs_alineados[0])}")
    print("\n" + "="*70)


def main():
    """Función principal."""
    parser = argparse.ArgumentParser(
        description="Gráfico de convergencia EA (30 ejecuciones)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  python analizar_ea.py                    # Genera gráfico de convergencia
  python analizar_ea.py -o resultados/     # Guardar gráfico en directorio
        """
    )
    parser.add_argument('-o', '--output', default='.', 
                       help='Directorio de salida (default: directorio actual)')
    
    args = parser.parse_args()
    
    # Crear directorio de salida si no existe
    if args.output != '.' and not os.path.exists(args.output):
        os.makedirs(args.output)
    
    print("="*70)
    print("ANÁLISIS EA - GRÁFICO DE CONVERGENCIA")
    print("="*70)
    
    # Cargar archivos
    print(f"\n📁 Buscando archivos en: {RUTA_REGISTROS}/")
    dfs, longitudes = cargar_archivos(RUTA_REGISTROS, PATRON_ARCHIVOS)
    
    if not dfs:
        print("❌ No se pudieron cargar los archivos. Abortando.")
        sys.exit(1)
    
    # Analizar longitudes
    min_iters = min(longitudes)
    max_iters = max(longitudes)
    
    print(f"\n📊 ESTADÍSTICAS DE LONGITUD:")
    print(f"   Iteraciones mínimas: {min_iters}")
    print(f"   Iteraciones máximas: {max_iters}")
    print(f"   Diferencia: {max_iters - min_iters} iteraciones")
    
    # Alinear datos
    print(f"\n🔄 ALINEACIÓN: Truncando a {min_iters} iteraciones")
    dfs_alineados = alinear_datos(dfs, min_iters)
    
    # Generar gráfico
    print(f"\n📈 GENERANDO GRÁFICO DE CONVERGENCIA...")
    output_grafico = os.path.join(args.output, SALIDA_GRAFICO)
    graficar_convergencia(dfs_alineados, output_grafico)
    
    # Imprimir resumen
    imprimir_resumen(dfs_alineados)


if __name__ == "__main__":
    main()
