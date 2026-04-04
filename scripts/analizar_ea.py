#!/usr/bin/env python3
"""
Script de Análisis EA - 30 Ejecuciones Independientes
=======================================================
Carga, alinea y analiza estadísticamente 30 ejecuciones del Algoritmo Evolutivo.

Uso desde terminal:
    python analizar_ea.py          # Análisis completo
    python analizar_ea.py --solo-stats  # Solo estadísticas (sin gráficos)
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
RUTA_REGISTROS = "../src/ea/registros"  # Ruta corregida
PATRON_ARCHIVOS = "ea_manual_seed_*.csv"
SALIDA_STATS = "ea_estadisticas_resumen.csv"
SALIDA_CONV = "analisis_ea_convergencia_manual.png"
SALIDA_VAR = "analisis_ea_variabilidad_manual.png"

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


def calcular_estadisticas(dfs_alineados):
    """Calcula estadísticas por iteración."""
    df_combinado = pd.concat([
        df.assign(experimento=i)
        for i, df in enumerate(dfs_alineados)
    ], ignore_index=True)

    df_stats = df_combinado.groupby('iteracion')['fitness'].agg([
        ('media', 'mean'),
        ('std', 'std'),
        ('mediana', 'median'),
        ('q25', lambda x: x.quantile(0.25)),
        ('q75', lambda x: x.quantile(0.75)),
        ('minimo', 'min'),
        ('maximo', 'max'),
        ('count', 'count')
    ]).reset_index()

    return df_stats


def graficar_convergencia(df_stats, output_path):
    """Genera gráficos de convergencia."""
    fig, axes = plt.subplots(2, 1, figsize=(14, 10))
    fig.patch.set_facecolor('#ffffff')
    plt.style.use('seaborn-v0_8-darkgrid')

    colors = {'media': '#1f77b4', 'ci95': '#1f77b4', 'iq': '#ff7f0e', 'bounds': '#d62728'}
    iter_vals = df_stats['iteracion'].values

    # Subplot 1: Convergencia con IC95%
    ax1 = axes[0]
    ci_upper = df_stats['media'] + 1.96 * df_stats['std']
    ci_lower = df_stats['media'] - 1.96 * df_stats['std']
    ci_lower = np.maximum(ci_lower, 0)

    ax1.plot(iter_vals, df_stats['media'],
             color=colors['media'], linewidth=2.5, label='Fitness Promedio', zorder=3)
    ax1.fill_between(iter_vals, ci_lower, ci_upper,
                     color=colors['ci95'], alpha=0.25, label='IC 95% (±1.96σ)', zorder=1)
    ax1.plot(iter_vals, df_stats['minimo'],
             color=colors['bounds'], linewidth=1.2, linestyle='--', alpha=0.6, label='Mejor Fit (min)', zorder=2)
    ax1.plot(iter_vals, df_stats['maximo'],
             color=colors['bounds'], linewidth=1.2, linestyle=':', alpha=0.6, label='Peor Fit (max)', zorder=2)

    ax1.set_ylabel("Fitness", fontsize=12, fontweight='bold')
    ax1.set_title("Convergencia EA - 30 Ejecuciones Independientes (Intervalo de Confianza 95%)",
                  fontsize=13, fontweight='bold', pad=15)
    ax1.grid(True, alpha=0.3)
    ax1.legend(fontsize=10, loc='best', framealpha=0.95)
    ax1.set_xlim(left=0)

    # Subplot 2: Percentiles
    ax2 = axes[1]
    ax2.plot(iter_vals, df_stats['mediana'],
             color='#2ca02c', linewidth=2.5, label='Mediana', zorder=3)
    ax2.fill_between(iter_vals, df_stats['q25'], df_stats['q75'],
                     color=colors['iq'], alpha=0.35, label='Rango IQ (Q1-Q3)', zorder=1)
    ax2.fill_between(iter_vals, df_stats['minimo'], df_stats['maximo'],
                     color='#d62728', alpha=0.1, label='Rango Min-Max', zorder=0)

    ax2.set_xlabel("Iteraciones", fontsize=12, fontweight='bold')
    ax2.set_ylabel("Fitness", fontsize=12, fontweight='bold')
    ax2.set_title("Análisis por Percentiles - Estabilidad del Algoritmo",
                  fontsize=13, fontweight='bold', pad=15)
    ax2.grid(True, alpha=0.3)
    ax2.legend(fontsize=10, loc='best', framealpha=0.95)
    ax2.set_xlim(left=0)

    plt.tight_layout()
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"\n💾 Gráfico guardado: {output_path}")
    plt.close()


def graficar_variabilidad(df_stats, output_path):
    """Genera gráfico del coeficiente de variación."""
    df_stats['cv'] = (df_stats['std'] / df_stats['media']) * 100

    fig, ax = plt.subplots(figsize=(13, 6))
    ax.plot(df_stats['iteracion'], df_stats['cv'],
            color='#9467bd', linewidth=2.5, marker='o', markersize=3, alpha=0.8)
    ax.fill_between(df_stats['iteracion'], 0, df_stats['cv'], alpha=0.2, color='#9467bd')

    ax.set_xlabel("Iteraciones", fontsize=12, fontweight='bold')
    ax.set_ylabel("Coeficiente de Variación (%)", fontsize=12, fontweight='bold')
    ax.set_title("Variabilidad de Fitness a lo largo del EA (CV = σ/μ × 100)",
                 fontsize=13, fontweight='bold', pad=15)
    ax.grid(True, alpha=0.3)
    ax.set_xlim(left=0)

    plt.tight_layout()
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"💾 Gráfico guardado: {output_path}")
    plt.close()


def imprimir_resumen(df_stats, min_iters):
    """Imprime un resumen de estadísticas."""
    print("\n" + "="*70)
    print("ANÁLISIS COMPLETADO - RESUMEN EJECUTIVO")
    print("="*70)

    print(f"\n📊 RESULTADO FINAL:")
    print(f"   Fitness Promedio (última iter): {df_stats['media'].iloc[-1]:.6f}")
    print(f"   Desviación Estándar Final: {df_stats['std'].iloc[-1]:.6f}")
    print(f"   Mejor Fit Alcanzado: {df_stats['minimo'].min():.6f}")
    print(f"   Peor Fit Alcanzado: {df_stats['maximo'].max():.6f}")
    print(f"   Intervalo Q1-Q3: [{df_stats['q25'].iloc[-1]:.6f}, {df_stats['q75'].iloc[-1]:.6f}]")

    # Mejora
    mejora_total = df_stats['media'].iloc[0] - df_stats['media'].iloc[-1]
    porcentaje_mejora = (mejora_total / df_stats['media'].iloc[0] * 100) if df_stats['media'].iloc[0] != 0 else 0

    print(f"\n🎯 CONVERGENCIA:")
    print(f"   Fitness inicial: {df_stats['media'].iloc[0]:.6f}")
    print(f"   Fitness final: {df_stats['media'].iloc[-1]:.6f}")
    print(f"   Mejora total: {mejora_total:.6f}")
    print(f"   Porcentaje de mejora: {porcentaje_mejora:.2f}%")
    print(f"   Iteraciones analizadas: {min_iters}")

    # Variabilidad
    cv_inicial = (df_stats['std'].iloc[0] / df_stats['media'].iloc[0] * 100) if df_stats['media'].iloc[0] != 0 else 0
    cv_final = (df_stats['std'].iloc[-1] / df_stats['media'].iloc[-1] * 100) if df_stats['media'].iloc[-1] != 0 else 0

    print(f"\n📉 VARIABILIDAD (Coeficiente de Variación):")
    print(f"   CV inicial: {cv_inicial:.3f}%")
    print(f"   CV final: {cv_final:.3f}%")
    print(f"   CV máximo: {df_stats['std'].max() / df_stats['media'].mean() * 100:.3f}%")


def main():
    """Función principal."""
    parser = argparse.ArgumentParser(
        description="Análisis estadístico de 30 ejecuciones del Algoritmo Evolutivo",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  python analizar_ea.py                    # Análisis completo con gráficos
  python analizar_ea.py --solo-stats       # Solo estadísticas, sin visualización
  python analizar_ea.py -o resultados/     # Guardar outputs en directorio
        """
    )
    parser.add_argument('--solo-stats', action='store_true',
                       help='Genera solo estadísticas sin gráficos')
    parser.add_argument('-o', '--output', default='.',
                       help='Directorio de salida (default: directorio actual)')

    args = parser.parse_args()

    # Crear directorio de salida si no existe
    if args.output != '.' and not os.path.exists(args.output):
        os.makedirs(args.output)

    print("="*70)
    print("ANÁLISIS ALGORITMO EVOLUTIVO - 30 EJECUCIONES INDEPENDIENTES")
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

    # Calcular estadísticas
    print(f"\n📈 CALCULANDO ESTADÍSTICAS POR ITERACIÓN...")
    df_stats = calcular_estadisticas(dfs_alineados)

    # Guardar estadísticas
    output_archivo = os.path.join(args.output, SALIDA_STATS)
    df_stats.to_csv(output_archivo, index=False, float_format='%.6f')
    print(f"✓ Estadísticas guardadas en: {output_archivo}")

    # Generar gráficos si no está el flag --solo-stats
    if not args.solo_stats:
        output_conv = os.path.join(args.output, SALIDA_CONV)
        output_var = os.path.join(args.output, SALIDA_VAR)
        graficar_convergencia(df_stats, output_conv)
        graficar_variabilidad(df_stats, output_var)

    # Imprimir resumen
    imprimir_resumen(df_stats, min_iters)
    print("\n" + "="*70)


if __name__ == "__main__":
    main()
