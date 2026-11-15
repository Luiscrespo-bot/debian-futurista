# Debian Futurista

Instalador para convertir una instalación mínima de **Debian** en un escritorio gráfico XFCE de estilo oscuro y tecnológico.

## Qué instala

- XFCE4 como entorno de escritorio.
- LightDM como gestor de inicio de sesión.
- Plank como dock y Picom como compositor.
- Arc-Dark y Papirus-Dark para la apariencia.
- Firefox ESR, terminal, gestor de archivos y utilidades habituales.
- Inicio automático del dock y compositor al entrar en XFCE.
- NetworkManager para la gestión de red.

## Requisitos

- Debian con systemd.
- Una cuenta de usuario normal con permisos sudo.
- Conexión a Internet.
- Espacio libre suficiente para instalar los paquetes.

## Instalación rápida

El siguiente comando descarga el instalador y lo ejecuta con permisos de administrador:

```bash
curl -fsSL https://raw.githubusercontent.com/Luiscrespo-bot/debian-futurista/main/personalizar.sh | sudo bash
```

**Importante:** ejecutar un script remoto con sudo concede privilegios de administrador al contenido descargado. Si prefieres revisarlo antes, descárgalo y examínalo:

```bash
curl -fsSLO https://raw.githubusercontent.com/Luiscrespo-bot/debian-futurista/main/personalizar.sh
less personalizar.sh
sudo bash personalizar.sh
```

El instalador programa un reinicio automático con una cuenta atrás de 30 segundos. Pulsa `Ctrl+C` durante la cuenta atrás para cancelarlo. Guarda tu trabajo antes de iniciar la instalación.

## Personalización persistente

La configuración se guarda en la carpeta personal del usuario: tema GTK, configuración de Picom y un lanzador de inicio automático para Plank y Picom. Se vuelve a aplicar al iniciar sesión en XFCE.

## Registro

Si ocurre algún problema, revisa el registro:

```
/var/log/debian-futurista-install.log
```

## Nota

El resultado visual puede variar según el hardware, los controladores gráficos y la versión de Debian. Este proyecto configura un escritorio XFCE; no reemplaza el kernel ni convierte Debian en una distribución independiente.
