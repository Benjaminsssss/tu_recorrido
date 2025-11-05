#!/usr/bin/env python3
"""
Script para procesar insignias: crear versiones circulares con fondo transparente.
Procesa todas las imágenes PNG de la carpeta Insignias y guarda las versiones
procesadas en una subcarpeta '_procesadas'.
"""

import os
import sys
from PIL import Image, ImageDraw
import numpy as np

def create_circular_mask(size):
    """Crea una máscara circular del tamaño especificado."""
    mask = Image.new('L', size, 0)
    draw = ImageDraw.Draw(mask)
    
    # Crear círculo centrado
    center = size[0] // 2, size[1] // 2
    radius = min(size) // 2 - 2  # Reducir ligeramente el radio para evitar bordes cortados
    
    # Dibujar círculo blanco en máscara negra
    draw.ellipse(
        [center[0] - radius, center[1] - radius, 
         center[0] + radius, center[1] + radius], 
        fill=255
    )
    
    return mask

def process_badge_image(input_path, output_path):
    """Procesa una imagen de insignia para hacerla circular con fondo transparente."""
    try:
        # Abrir imagen
        img = Image.open(input_path)
        
        # Convertir a RGBA si no lo está ya
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Obtener tamaño y crear imagen cuadrada si es necesario
        width, height = img.size
        
        # Hacer la imagen cuadrada tomando la dimensión menor
        size = min(width, height)
        
        # Recortar al centro para hacer cuadrada
        left = (width - size) // 2
        top = (height - size) // 2
        right = left + size
        bottom = top + size
        
        img_square = img.crop((left, top, right, bottom))
        
        # Crear máscara circular
        mask = create_circular_mask((size, size))
        
        # Crear imagen de salida con fondo transparente
        output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        
        # Aplicar máscara circular
        output.paste(img_square, (0, 0))
        
        # Aplicar la máscara circular usando putalpha
        output.putalpha(mask)
        
        # Guardar imagen procesada
        output.save(output_path, 'PNG', optimize=True)
        
        print(f"✅ Procesada: {os.path.basename(input_path)} -> {os.path.basename(output_path)}")
        return True
        
    except Exception as e:
        print(f"❌ Error procesando {input_path}: {str(e)}")
        return False

def main():
    """Función principal que procesa todas las insignias."""
    
    # Rutas
    insignias_folder = r"c:\Users\andre\OneDrive\Imagenes\Escritorio\Insignias"
    output_folder = os.path.join(insignias_folder, "_procesadas")
    
    # Crear carpeta de salida si no existe
    os.makedirs(output_folder, exist_ok=True)
    
    # Lista de archivos a procesar
    badge_files = [
        "Antiguo_Teatro_Carrera.png",
        "Barrio_Lastarria.png", 
        "Casa_de_las_Arañas.png",
        "Casa_Larrain_Bravo.png",
        "Cerro_Santa_Lucia.png",
        "La_Casa_de_las_Gargolas.png",
        "La_Catedral_de_Santiago.png",
        "Muse_de_la_memoria.png",
        "Museo_historico_nacional.png",
        "Palacio_de_la_Moneda.png",
        "Palacio_Ossa.png",
        "Parque_del_Tíbet.png",
        "PedroDeValdivia_PlazadeArmas.png",
        "Templo_Bahai.png",
        "Virgen_Cerro_San_Cristobal.png"
    ]
    
    print(f"🔄 Procesando {len(badge_files)} insignias...")
    print(f"📂 Carpeta origen: {insignias_folder}")
    print(f"📂 Carpeta destino: {output_folder}")
    print("-" * 60)
    
    processed_count = 0
    
    for filename in badge_files:
        input_path = os.path.join(insignias_folder, filename)
        output_path = os.path.join(output_folder, filename)
        
        if os.path.exists(input_path):
            if process_badge_image(input_path, output_path):
                processed_count += 1
        else:
            print(f"⚠️  Archivo no encontrado: {filename}")
    
    print("-" * 60)
    print(f"✅ Procesamiento completado: {processed_count}/{len(badge_files)} insignias")
    print(f"📁 Archivos guardados en: {output_folder}")
    print("\n🔧 Instrucciones:")
    print("1. Revisar las imágenes procesadas en la carpeta '_procesadas'")
    print("2. Subir estas versiones PNG con transparencia a tu app")
    print("3. Las insignias se verán perfectamente circulares sin marco")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n❌ Procesamiento cancelado por el usuario")
    except Exception as e:
        print(f"❌ Error fatal: {str(e)}")
        sys.exit(1)