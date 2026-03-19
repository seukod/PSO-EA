import pandas as pd
import matplotlib.pyplot as plt
import sys
import os

def graficar_por_numero():
    if len(sys.argv) < 2:
        print("Error: Indica el número del experimento. Ejemplo: python graficos.py 1")
        return

    numero = sys.argv[1]
    archivo = f"registros/pso_{numero}.csv"

    if not os.path.exists(archivo):
        print(f"Error: El archivo '{archivo}' no existe en la carpeta registros.")
        return

    df = pd.read_csv(archivo)
    
    # Limpieza para visualización
    if len(df) > 1000:
        df = df.iloc[::10, :]

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
    fig.suptitle(f'Experimento PSO #{numero}', fontsize=16)

    # Convergencia
    ax1.plot(df['iteracion'], df['fitness'], color='blue')
    ax1.set_yscale('log')
    ax1.set_title('Convergencia (Fitness)')
    ax1.set_xlabel('Iteración')
    ax1.grid(True, which="both", alpha=0.3)

    # Trayectoria
    sc = ax2.scatter(df['gbestx'], df['gbesty'], c=df['iteracion'], cmap='plasma', s=10)
    ax2.set_title('Trayectoria GBest')
    ax2.set_xlim(0, 1024)
    ax2.set_ylim(512, 0) # Invertido
    plt.colorbar(sc, ax=ax2, label='Progreso (Iteración)')

    plt.show()

if __name__ == "__main__":
    graficar_por_numero()