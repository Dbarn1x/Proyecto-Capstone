# Proyecto Capstone - MatchPet App (Paws) 🐾

¡Bienvenidos al repositorio oficial de **Paws** (MatchPet Social)! Esta aplicación está diseñada en Flutter para conectar mascotas y dueños mediante un sistema de matches y un mapa GPS interactivo.

## 🛠️ Requisitos Previos (Instalación)

Para que cualquier integrante del equipo pueda compilar y ejecutar este proyecto en su propio PC (Windows), es **indispensable** tener instalado el SDK de Flutter.

### Paso 1: Instalar Flutter SDK
1. Ingresa a la página oficial de descargas de Flutter: [https://docs.flutter.dev/get-started/install/windows/desktop](https://docs.flutter.dev/get-started/install/windows/desktop)
2. Descarga el instalador para Windows (el archivo `.zip`).
3. Extrae la carpeta `flutter` en la ubicación raíz de tu PC (por ejemplo, `C:\src\flutter`).
4. Añade la ruta `C:\src\flutter\bin` a las **Variables de Entorno** (Path) de tu sistema Windows.
5. Abre una terminal (CMD o PowerShell) y ejecuta `flutter doctor` para verificar que la instalación se haya completado correctamente.

---

## 🚀 Guía de Ejecución Rápida para el Equipo

Una vez que tengas Flutter instalado y funcionando, y hayas descargado el archivo **`Paws.rar`** de este repositorio (y lo hayas extraído en tu escritorio), sigue estos pasos exactos en Visual Studio Code:

1. **Abre la carpeta en VS Code:**
   Ve a `Archivo` > `Abrir Carpeta...` y selecciona la carpeta **Paws** que acabas de extraer.

2. **Abre la Terminal integrada:**
   Presiona `Ctrl + ñ` (o ve al menú superior `Terminal` > `Nueva Terminal`).

3. **Reconstruye las carpetas nativas de tu PC:**
   Como el repositorio solo contiene el código fuente (`lib` y `pubspec.yaml`), necesitas que Flutter genere las carpetas de compilación para tu propio sistema. Ejecuta este comando:
   ```bash
   flutter create .
