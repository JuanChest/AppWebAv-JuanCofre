# PoliMusic

Aplicación web de música estilo Spotify desarrollada en **ASP clásico** con **SQL Server**.
Incluye catálogo de canciones, reproducción con cola, playlists personales y un panel de
administración para canciones, artistas y álbumes. El diseño es propio, en naranja y negro.

## Funcionalidades

- **Inicio de sesión y cierre de sesión** con sesión ASP (`uid`, `uname`, `utype`, `uphoto`).
- **Dos roles**: usuario normal y administrador.
- **Song List** en la pantalla de inicio, con búsqueda, reproducción, cola, volumen y barra de progreso.
- **Playlists personales**: crear, editar (título, tipo y portada), agregar/quitar canciones y eliminar.
- **Panel de administración** (solo rol admin):
  - Canciones: crear/editar con archivo MP3 o audio de la biblioteca, artistas y álbumes asociados.
  - Artistas y álbumes: crear/editar con imagen o imagen de la biblioteca.
  - Eliminación con limpieza de archivos subidos y relaciones.
- **Reproducciones**: `api-play.asp` incrementa el contador `PLAYS` de la canción.
- **Portadas y avatares** con respaldo visual si falta la imagen.

## Requisitos

- Windows.
- **IIS Express 10** (viene con Visual Studio) o IIS con la característica **ASP** habilitada.
- **SQL Server** escuchando en el puerto `1433` (o ajustar la cadena de conexión).
- Proveedor **SQLOLEDB** (incluido en Windows).
- PowerShell (para generar la configuración local de IIS Express desde `start.cmd`).

## Base de datos

1. Abrir SQL Server Management Studio.
2. Ejecutar el script [`webapppolimusicv1_asp/BDD_PoliMusic.sql`](webapppolimusicv1_asp/BDD_PoliMusic.sql)
   sobre la instancia local. El script está codificado en UTF-16LE; SSMS lo abre correctamente.
3. Verificar la cadena de conexión en [`includes/config.asp`](webapppolimusicv1_asp/includes/config.asp):

   ```vbscript
   Const DB_SERVER   = "localhost,1433"
   Const DB_NAME     = "BDD_PoliMusic"
   Const DB_USER     = "usr_polimusic"
   Const DB_PASSWORD = "Politecnica1"
   ```

   Si el login SQL no existe en tu instancia, créalo o cambia estos valores por los de tu entorno.

## Cómo ejecutar

1. Abrir la carpeta `webapppolimusicv1_asp`.
2. Hacer doble clic en **`start.cmd`** (o ejecutarlo desde una consola).
3. Abrir <http://localhost:8099/>.
4. Cerrar la ventana de la consola para detener el servidor.

`start.cmd`:

- Busca IIS Express en `Program Files` o `Program Files (x86)`.
- Genera una configuración temporal en `%TEMP%\polimusic-iisexpress.config` reemplazando
  `__APPDIR__` por la ruta absoluta de la aplicación (así el proyecto se puede mover de carpeta).
- Inicia el sitio `PoliMusic` en el puerto **8099**.

Si el puerto está ocupado, cambia la línea del binding en la plantilla
[`.iisexpress/applicationHost.config`](webapppolimusicv1_asp/.iisexpress/applicationHost.config):

```xml
<binding protocol="http" bindingInformation=":8099:localhost" />
```

## Credenciales de prueba

| Usuario     | Contraseña | Rol           |
|-------------|------------|---------------|
| `userNormal`| `12345678` | Normal        |
| `userAdmin` | `12345678` | Administrador |
| `username1` | `12345678` | Normal        |

`username1` guarda la contraseña como hash SHA1 en la base; el login acepta tanto texto plano
como `HASHBYTES('SHA1', ...)`.

## Límites de subida

- Audio: hasta **25 MB** (`.mp3`, `.wav`, `.ogg`).
- Imágenes: hasta **5 MB** (`.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`).
- Petición multipart máxima de la aplicación: **30 MB** (`UPLOAD_MAX` en `includes/config.asp`).
- Límite de ASP en la configuración de IIS Express: **100 MB**
  (`<limits maxRequestEntityAllowed="104857600" />`).

En IIS completo, el límite de ASP se ajusta una vez con:

```bat
%windir%\system32\inetsrv\appcmd.exe set config /section:asp /limits.maxRequestEntityAllowed:104857600
```

## Estructura del proyecto

```text
webapppolimusicv1_asp/
  default.asp, login.asp, logout.asp, home.asp
  playlists.asp, playlist.asp, playlist-form.asp
  albums.asp, artists.asp, api-play.asp
  admin-songs.asp, admin-song-form.asp
  admin-albums.asp, admin-album-form.asp
  admin-artists.asp, admin-artist-form.asp
  includes/
    config.asp      Constantes, cadena de conexión y ruta base
    db.asp          Helpers ADO (DBQuery, RunSql, Scalar, InsertId, ...)
    helpers.asp     Escape HTML, URLs, iconos, avatares, borrado de archivos
    auth.asp        Sesión, guards de rol y login
    upload.asp      Parser multipart binario y guardado de archivos
    layout-top.asp  Cabecera, navegación y reproductor
    layout-bottom.asp
  css/app.css
  js/app.js
  songFiles/        MP3
  albumImages/      Portadas de álbumes
  ArtistImages/     Fotos de artistas
  playlistImages/   Portadas de playlists
  userImages/       Avatares
  .iisexpress/applicationHost.config   Plantilla de IIS Express (start.cmd la procesa)
  BDD_PoliMusic.sql
  start.cmd
```

## Notas

- Las páginas de administración viven en la raíz con prefijo `admin-` para evitar el bloqueo de
  IIS Express a `#include file="../..."` (error `ASP 0131`).
- El seed referencia cinco MP3; se incluyeron copias del mismo audio de demostración para que
  todas las canciones del catálogo puedan reproducirse.
- La imagen `username1.png` no venía en los recursos originales; se agregó una copia de
  `default.jpg` para que el avatar del seed se muestre correctamente.
- Los archivos subidos desde la aplicación se guardan en las carpetas anteriores y se eliminan
  al borrar el registro correspondiente o al reemplazarlos, siempre que ya no estén en uso.
