# Historial de versiones

| Versión | Fecha | Autor | Descripción del cambio |
|---|---|---|---|
| 1.0.0 | 2026-08-29 | Andrés García | Primera versión publicada |

## [1.0.0] - 2026-08-29

### Añadido
- Instalación completa en un comando desde el DVD original.
- Despliegue por paquetes (`0compressed.zip` y `1compressed.zip`) sin ejecutar el
  instalador de EA.
- Parche oficial 1.4 aplicado en silencio, y sustitución del ejecutable por el
  limpio de 7.217.152 bytes tras comprobar que el parche no quita SafeDisc.
- Widescreen Fix de ThirteenAG y NFSC Extra Options con un único cargador.
- Registro con las **cuatro** ramas que el ejecutable referencia, incluidas las
  variantes españolas "Need for Speed Carbono".
- Ajustes gráficos volcados a fichero de texto, con sombras, detalle de coches y
  reflejos del asfalto subidos.
- Réplica de esos ajustes en el registro como red de seguridad.
- Override de `dinput8` fijado también en el registro del prefijo.
- Comprobación de que `ShowSubs` queda sin tocar: su documentación aclara que esa
  opción sirve solo para añadir subtítulos al inglés ("German, French, Spanish, all
  have subtitles. Why not English?"), porque en español ya son nativos. Activarla en
  una instalación en español no aporta nada.
- Desactivación preventiva de los mandos fantasma.
- Lanzador con opciones y entrada en el menú de escritorio con icono propio.
- Guion de comprobación posterior a la instalación.

### Decisiones tomadas con medidas
- **Suavizado de bordes en 2, no al máximo.** Medido: la GPU ya trabaja al 92 % con
  132 fotogramas de mediana y 85 en el peor 1 %. Subirlo solo restaría fluidez.
- **`WindowedMode = 4`** en vez de pantalla completa exclusiva, por el fallo de KDE
  con el cursor bajo Wayland. Medido: ventana de 1920x1080 exactos en 0,0.
- **Última publicación del Widescreen Fix, nunca una versión fija**: las incidencias
  525, 1013 y 1794 describen pantalla negra bajo Wine con versiones anteriores, y la
  del 4 de mayo de 2026 lo resuelve.

### Detalles que costaron encontrar
- El parche 1.4 **renombra** `nfsc.exe` a `NFSC.exe`. En Linux son ficheros distintos.
- El ISO del disco es **UDF, no ISO9660**: el sector 16 está vacío y las herramientas
  que buscan ahí la firma `CD001` fallan.
- Dentro de los ZIP las rutas usan barra invertida, que `unzip` interpreta como
  escape: los patrones hay que darlos sin la parte de directorio.
