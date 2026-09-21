#define _POSIX_C_SOURCE 200809L
#define _DEFAULT_SOURCE

/*********************************************************
 *
 * ALUMNO QUE HA REALIZADO ESTA PRÁCTICA:
 *
 *   Nombre: Guillermo Aladro Abad
 *   Correo: Guillermo.aladro@alumons.upm.es
 *
 *********************************************************/

#include <sys/param.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sysexits.h>
#include <sys/wait.h>
#include <signal.h>

static void uso(void);
static void convertir(const char* fich_imagen, const char* dir_resultados);
static void manejador_SIGTERM(int sig);

static int pids_hijos[105];   // Guarda los PID de todos los hijos creados
static int numero_hijos = 0;  // Cuenta total de hijos creados
static int activo_hijo = 0;   // Hijos activos en este instante (máximo 4)
static pid_t pid;

int main(int argc, char** argv)
{
    const char* dir_resultados;

    printf("PID del proceso padre: %d\n", getpid());

    /*
     * Si se recibe una señal SIGTERM, en lugar de terminar de forma
     * predeterminada se llama al manejador definido por el programa.
     */
    signal(SIGTERM, manejador_SIGTERM);

    if (argc < 3) {
        uso();
        exit(EX_USAGE);
    }

    dir_resultados = argv[1];

    for (int i = 2; i < argc; i++) {
        /*
         * Antes de crear un nuevo proceso hijo, se comprueba si ya hay
         * cuatro hijos activos. Si es así, se espera a que termine alguno.
         */
        while (activo_hijo >= 4) {
            int status;
            pid_t terminated_pid = waitpid(-1, &status, WNOHANG);

            if (terminated_pid > 0) {
                activo_hijo--;
            }
        }

        pid = fork();

        switch (pid) {
        case -1:
            perror("Error en fork");
            exit(EX_OSERR);

        case 0:
            printf("Soy el hijo. Mi PID es: %d\n", getpid());
            convertir(argv[i], dir_resultados);
            exit(EX_OK);

        default:
            pids_hijos[numero_hijos++] = pid;
            activo_hijo++;
            printf(
                "Proceso hijo número %d creado con PID: %d\n",
                numero_hijos,
                pid
            );
        }
    }

    /*
     * Una vez lanzados todos los hijos, el padre espera de forma bloqueante
     * a que terminen los que todavía siguen activos.
     */
    while (activo_hijo > 0) {
        int status;
        pid_t terminated_pid = waitpid(-1, &status, 0);

        if (terminated_pid > 0) {
            activo_hijo--;
        }
    }

    exit(EX_OK);
}

static void uso(void)
{
    fprintf(stderr, "\nUso: paralelo dir_resultados fich_imagen...\n");
    fprintf(stderr, "\nEjemplo: paralelo difuminadas orig/*.jpg\n\n");
}

static void convertir(const char* fich_imagen, const char* dir_resultados)
{
    const char* nombre_base;
    char nombre_destino[MAXPATHLEN];

    nombre_base = strrchr(fich_imagen, '/');

    if (nombre_base == NULL) {
        nombre_base = fich_imagen;
    } else {
        nombre_base++;
    }

    snprintf(
        nombre_destino,
        sizeof(nombre_destino),
        "%s/%s",
        dir_resultados,
        nombre_base
    );

    printf(
        "Hijo con PID %d va a procesar la imagen: %s -> %s\n\n",
        getpid(),
        fich_imagen,
        nombre_destino
    );
    fflush(stdout);

    execlp(
        "magick",
        "magick",
        fich_imagen,
        "-blur",
        "0x08",
        nombre_destino,
        NULL
    );

    perror("Error en execlp");
    exit(EX_OSERR);
}

static void manejador_SIGTERM(int sig)
{
    (void)sig;

    printf(
        "Recibida orden SIGTERM, terminando todos los procesos hijos\n\n"
    );
    printf("Hay que terminar %d procesos hijos\n\n", numero_hijos);

    for (int i = 0; i < numero_hijos; i++) {
        printf(
            "Enviando SIGTERM al proceso hijo %d\n",
            pids_hijos[i]
        );
        kill(pids_hijos[i], SIGTERM);
    }

    exit(EX_OK);
}
