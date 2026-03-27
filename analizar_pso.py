#!/usr/bin/env python3
"""
Script de Análisis PSO - 30 Ejecuciones Independientes
=======================================================
Genera gráfico de convergencia con mejor caso vs promedio.

Uso desde terminal:
    python analizar_pso.py          # Genera gráfico de convergencia
    python analizar_pso.py --help   # Ayuda
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
RUTA_REGISTROS = "registros"
PATRON_ARCHIVOS = "pso_sim*.csv"
SALIDA_GRAFICO = "convergencia_pso.png"

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
        description="Gráfico de convergencia PSO (30 ejecuciones)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  python analizar_pso.py                    # Genera gráfico de convergencia
  python analizar_pso.py -o resultados/     # Guardar gráfico en directorio
        """
    )
    parser.add_argument('-o', '--output', default='.', 
                       help='Directorio de salida (default: directorio actual)')
    
    args = parser.parse_args()
    
    # Crear directorio de salida si no existe
    if args.output != '.' and not os.path.exists(args.output):
        os.makedirs(args.output)
    
    print("="*70)
    print("ANÁLISIS PSO - GRÁFICO DE CONVERGENCIA")
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
