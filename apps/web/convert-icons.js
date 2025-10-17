const fs = require("fs");
const { createCanvas, loadImage } = require("canvas");

async function convertSvgToPng() {
  try {
    // Para simplificar, voy a crear archivos PNG básicos usando canvas
    const canvas192 = createCanvas(192, 192);
    const ctx192 = canvas192.getContext("2d");

    // Crear un gradiente azul
    const gradient192 = ctx192.createLinearGradient(0, 0, 192, 192);
    gradient192.addColorStop(0, "#3b82f6");
    gradient192.addColorStop(1, "#1d4ed8");

    // Dibujar fondo
    ctx192.fillStyle = gradient192;
    ctx192.fillRect(0, 0, 192, 192);

    // Dibujar círculo blanco
    ctx192.fillStyle = "rgba(255, 255, 255, 0.9)";
    ctx192.beginPath();
    ctx192.arc(96, 96, 60, 0, 2 * Math.PI);
    ctx192.fill();

    // Dibujar icono médico simple
    ctx192.fillStyle = "#3b82f6";
    ctx192.fillRect(76, 76, 40, 40);
    ctx192.fillStyle = "white";
    ctx192.fillRect(86, 86, 20, 20);

    // Guardar como PNG
    const buffer192 = canvas192.toBuffer("image/png");
    fs.writeFileSync("public/pwa-192x192.png", buffer192);

    // Crear versión 512x512
    const canvas512 = createCanvas(512, 512);
    const ctx512 = canvas512.getContext("2d");

    const gradient512 = ctx512.createLinearGradient(0, 0, 512, 512);
    gradient512.addColorStop(0, "#3b82f6");
    gradient512.addColorStop(1, "#1d4ed8");

    ctx512.fillStyle = gradient512;
    ctx512.fillRect(0, 0, 512, 512);

    ctx512.fillStyle = "rgba(255, 255, 255, 0.9)";
    ctx512.beginPath();
    ctx512.arc(256, 256, 160, 0, 2 * Math.PI);
    ctx512.fill();

    ctx512.fillStyle = "#3b82f6";
    ctx512.fillRect(196, 196, 120, 120);
    ctx512.fillStyle = "white";
    ctx512.fillRect(226, 226, 60, 60);

    const buffer512 = canvas512.toBuffer("image/png");
    fs.writeFileSync("public/pwa-512x512.png", buffer512);

    console.log("Iconos PNG generados exitosamente");
  } catch (error) {
    console.error("Error generando iconos:", error);
  }
}

convertSvgToPng();
