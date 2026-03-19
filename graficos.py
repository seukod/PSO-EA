import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import sys
import os
import glob

def graficar_pro_v2():
    if len(sys.argv) < 2:
        print("Uso: python graficos.py [numero]")
        return

    arg = sys.argv[1]
    patron = f"registros/pso_{arg}_*.csv"
    archivos = glob.glob(patron) + glob.glob(f"registros/pso_{arg}.csv")

    if not archivos:
        print(f"No se encontró el archivo para el experimento {arg}")
        return

    path = archivos[0]
    df = pd.read_csv(path)

    # --- PROCESAMIENTO DE DATOS ---
    # Para que no se vea "gordo" el gráfico, tomamos una muestra
    paso = max(1, len(df) // 500) 
    df_resumido = df.iloc[::paso, :]

    # --- CONFIGURACIÓN DE ESTILO ---
    plt.style.use('bmh') # Estilo con cuadrícula limpia
    fig = plt.figure(figsize=(16, 9))
    gs = fig.add_gridspec(2, 2, height_ratios=[1, 1], width_ratios=[1, 1.2])
    
    fig.patch.set_facecolor('#ffffff')
    plt.suptitle(f"Reporte de Optimización PSO: {os.path.basename(path)}", fontsize=18, fontweight='bold', y=0.98)

    # --- 1. GRÁFICO DE CONVERGENCIA (LOG) ---
    ax1 = fig.add_subplot(gs[0, 0])
    ax1.plot(df['iteracion'], df['fitness'], color='#1f77b4', linewidth=1.5, label='Mejor Fitness Global')
    ax1.fill_between(df['iteracion'], df['fitness'], color='#1f77b4', alpha=0.1)
    ax1.set_yscale('log')
    ax1.set_title("Curva de Convergencia", fontsize=13)
    ax1.set_ylabel("Fitness (Log)")
    ax1.grid(True, which="both", alpha=0.3)

    # --- 2. TRAYECTORIA SOBRE RASTRIGIN ---
    ax2 = fig.add_subplot(gs[:, 1])
    # Fondo Rastrigin
    x = np.linspace(0, 1024, 150)
    y = np.linspace(0, 512, 100)
    X, Y = np.meshgrid(x, y)
    Xm, Ym = -3 + (X/1024)*10, -3 + (Y/512)*10
    Zm = 20 + (Xm**2 - 10*np.cos(2*np.pi*Xm)) + (Ym**2 - 10*np.cos(2*np.pi*Ym))
    
    ax2.contourf(X, Y, Zm, levels=20, cmap='Spectral_r', alpha=0.4)
    sc = ax2.scatter(df_resumido['gbestx'], df_resumido['gbesty'], 
                     c=df_resumido['iteracion'], cmap='viridis', s=15, alpha=0.8, edgecolors='none')
    
    ax2.scatter(df['gbestx'].iloc[0], df['gbesty'].iloc[0], c='green', marker='P', s=100, label='Inicio')
    ax2.scatter(df['gbestx'].iloc[-1], df['gbesty'].iloc[-1], c='red', marker='*', s=150, label='Final')
    
    ax2.set_title("Búsqueda en el Espacio (Rastrigin Background)", fontsize=13)
    ax2.set_xlim(0, 1024); ax2.set_ylim(512, 0)
    plt.colorbar(sc, ax=ax2, label='Iteración')
    ax2.legend()

    # --- 3. ESFUERZO DE CÓMPUTO ---
    ax3 = fig.add_subplot(gs[1, 0])
    # Usamos step (escalones) en vez de barras para que no se vea como bloque
    ax3.step(df['iteracion'], df['evals to best'], color='#e67e22', where='post', linewidth=1.5)
    ax3.set_title("Eficiencia: Evaluaciones hasta el Récord", fontsize=13)
    ax3.set_xlabel("Iteraciones")
    ax3.set_ylabel("Evaluaciones")

    # --- 4. CAJA DE PARÁMETROS (FLOTANTE) ---
    p = df.iloc[0]
    info_text = (
        f"Configuración:\n"
        f"• Partículas: {int(p['puntos'])}\n"
        f"• Inercia (w): {p['inercia']}\n"
        f"• C1 / C2: {p['C1']} / {p['C2']}\n\n"
        f"Resultados:\n"
        f"• Mejor Fit: {df['fitness'].min():.5f}\n"
        f"• Tiempo: {df['tiempo_al_mejor'].max():.2f}s"
    )
    fig.text(0.02, 0.05, info_text, fontsize=10, bbox=dict(facecolor='white', alpha=0.8, boxstyle='round,pad=0.5'))

    plt.tight_layout(rect=[0, 0.03, 1, 0.95])
    plt.show()

if __name__ == "__main__":
    graficar_pro_v2()