# Calca Casera ✏️

App web casera para **calcar dibujos** con el móvil, al estilo de las apps de "trace & sketch":
ves el papel a través de la cámara con la imagen elegida superpuesta y semitransparente, y repasas las líneas con el lápiz.

## Cómo se usa
1. Abre la app y elige una imagen **de la galería** o pulsa **🔎 Buscar en internet**.
2. Apoya el móvil sobre un vaso o soporte, unos 20–30 cm por encima del papel.
3. Ajusta la imagen: **un dedo** para moverla, **dos dedos** para hacer zoom y girarla.
4. Baja/sube la **opacidad** hasta ver bien tanto el papel como la imagen.
5. Pulsa el **candado 🔒** para que no se mueva al tocar la pantalla sin querer, y ¡a dibujar!

## Funciones
- 🔎 **Buscar en internet**: buscador integrado con imágenes de uso libre de [Wikimedia Commons](https://commons.wikimedia.org) y [Openverse](https://openverse.org) (con la opción «Solo dibujos»). En inglés suele haber más resultados.
- **Google Imágenes**: abre la búsqueda en Google; mantén pulsada la imagen → «Copiar imagen» (o «Copiar dirección de la imagen») y vuelve a la app para pulsar **📋 Pegar**. También puedes pegar el enlace directamente en el cuadro de búsqueda.
- 🎥 **Modo cámara**: imagen superpuesta a la cámara trasera.
- 💡 **Modo calco directo**: sin cámara, la imagen a pantalla completa sobre fondo blanco para poner un papel fino encima de la pantalla.
- 📤 **Compartir a la app** (Android, con la app instalada): en Google, la galería o cualquier web, pulsa **Compartir** en una imagen y elige **Calca Casera**; se abre directamente lista para calcar. También acepta enlaces de Google Imágenes.
- ✏️ **Líneas**: convierte la foto en contornos (detección de bordes) con control de detalle.
- ↔️ Espejo, ⟲ recolocar, 🔦 linterna (si el móvil lo permite).
- La pantalla no se apaga mientras calcas y funciona sin conexión una vez instalada.

## Instalarla en el móvil
La cámara solo funciona en **HTTPS**, así que la forma más sencilla es GitHub Pages:
1. En GitHub: *Settings → Pages → Deploy from a branch* y elige la rama y la carpeta raíz.
2. Abre `https://<usuario>.github.io/demogitlesson/calcaapp/` en el móvil.
3. Menú del navegador → **Añadir a pantalla de inicio**. Aparecerá como una app más.

Para probarla en el ordenador: `cd calcaapp && python3 -m http.server 8000` y abre `http://localhost:8000`.

> Nota: algunas webs no dejan leer los píxeles de sus imágenes; con esas se puede calcar normal, pero no funciona el modo ✏️ Líneas.
