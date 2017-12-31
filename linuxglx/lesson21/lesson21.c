/*
 * This code was created by Jeff Molofee '00 
 * (ported to Linux/GLX by Mihael Vrbanec '01)
 *
 * If you've found this code useful, please let me know.
 *
 * Visit Jeff at http://nehe.gamedev.net/
 * 
 * or for port-specific comments, questions, bugreports etc. 
 * email to Mihael.Vrbanec@stud.uni-karlsruhe.de
 */

/* comment out for no sound */
#define WITH_SOUND

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <GL/glx.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <X11/extensions/xf86vmode.h>
#include <X11/keysym.h>
#include <math.h>
#include <sys/timeb.h>

#ifdef WITH_SOUND
/* includes needed for sound */
#include <sys/ioctl.h>
#include <sys/fcntl.h>
#include <sys/soundcard.h>
#include <unistd.h>


#define RIFF 1179011410     /* little endian value for ASCII-encoded 'RIFF' */
#define WAVE 1163280727     /* little endian value for ASCII-encoded 'WAVE' */
#define FMT 544501094       /* little endian value for ASCII-encoded 'fmt' */
#define DATA 1635017060     /* little endian value for ASCII-encoded 'data' */

typedef struct {
    unsigned int chunkID;    /* ASCII: 'RIFF' */
    unsigned int chunkSize;    /* filelength - 8 */
    unsigned int format;    /* ASCII: 'WAVE' */

    unsigned int subChunk1ID;   /* ASCII: 'fmt ' */
    unsigned int subChunk1Size; /* length of sub chunk, 16 for PCM*/
    unsigned short int audioFormat;     /* should be 1 for PCM */
    unsigned short int numberOfChannels;    /* 1 Mono, 2 Stereo */
    unsigned int sampleRate;    /* sample frequency */
    unsigned int byteRate;  /* sampleRate * numberOfChannels * bitsPerSample/8 */

    unsigned short int blockAlign;    /* numberOfChannels * bitsPerSample/8 */
    unsigned short int bitsPerSample; /* 8, 16 bit */ 

    unsigned int subChunk2ID;   /* ASCII: 'data' */
    unsigned int subChunk2Size; /* size of the sample data */
} waveHeader;

typedef struct {
    waveHeader* header;
    unsigned char* sampleData;
} waveFile;
#endif

/* stuff about our window grouped together */
typedef struct {
    Display *dpy;
    int screen;
    Window win;
    GLXContext ctx;
    XSetWindowAttributes attr;
    Bool fs;
    XF86VidModeModeInfo deskMode;
    int x, y;
    unsigned int width, height;
    unsigned int depth;
} GLWindow;

typedef struct {
    int width;
    int height;
    unsigned char* data;
} textureImage;

typedef struct {
    int fx, fy;         /* fine positions */
    int x, y;           /* grid positions */
    float spin;         /* z-axis spin direction */
} object;


/* attributes for a single buffered visual in RGBA format with at least
 * 4 bits per color and a 16 bit depth buffer */
static int attrListSgl[] = { GLX_RGBA, GLX_RED_SIZE, 4,
    GLX_GREEN_SIZE, 4,
    GLX_BLUE_SIZE, 4,
    GLX_DEPTH_SIZE, 16,
    None
};

/* attributes for a double buffered visual in RGBA format with at least
 * 4 bits per color and a 16 bit depth buffer */
static int attrListDbl[] = { GLX_RGBA, GLX_DOUBLEBUFFER,
    GLX_RED_SIZE, 4,
    GLX_GREEN_SIZE, 4,
    GLX_BLUE_SIZE, 4,
    GLX_DEPTH_SIZE, 16,
    None
};


GLWindow GLWin;
char* title = "NeHe's Line Tutorial";
Bool done;
Bool keys[256];
int keyCodes[20];        /* array to hold our fetched keycodes */
Bool vlines[11][10];    /* keep track of vertical lines */
Bool hlines[10][11];    /* keep track of horizontal lines */
Bool filled;            /* grid filled ?*/
Bool gameOver;
Bool antiAliasing;

object player;
object enemy[15];
object hourglass;

int loop1, loop2;
int delay;
int adjust = 3;         /* speed adjustment */
int lives = 5;          /* player lives */
int level = 1;          /* internal level */
int level2 = 1;         /* displayed level */
int stage = 1;          /* game stage */
int steps[6] = { 1, 2, 4, 5, 10, 20 };

GLuint texture[2];
GLuint base;

unsigned int t0;
unsigned int frames;
unsigned int t;

#ifdef WITH_SOUND
/* sound stuff */
int audioDevice;
waveFile* dieWave;
waveFile* completeWave;
waveFile* freezeWave;
waveFile* hourglassWave;
#endif

void resetObjects(void) {
    player.x = 0;
    player.y = 0;
    player.fx = 0;
    player.fy = 0;
    for (loop1 = 0; loop1 < level * stage; loop1++) {
        enemy[loop1].x = 5 + rand() % 6;
        enemy[loop1].y = rand() % 11;
        enemy[loop1].fx = enemy[loop1].x * 60;
        enemy[loop1].fy = enemy[loop1].y * 40;
    }
}

unsigned int getMilliSeconds()
{
    struct timeb tb;
    ftime(&tb);
    return tb.time * 1000 + tb.millitm;
}

/* simple loader for 24bit bitmaps (data is in rgb-format) */
int loadBmp(char* filename, textureImage* texture)
{
    FILE* file;
    unsigned short int bfType;
    long int bfOffBits;
    short int biPlanes;
    short int biBitCount;
    long int biSizeImage;
    int i;
    unsigned char temp;
    /* make sure the file is there and open it read-only (binary) */
    if ((file = fopen(filename, "rb")) == NULL) {
        printf("File not found : %s\n", filename);
        return 0;
    }
    if (!fread(&bfType, sizeof(short int), 1, file)) {
        printf("Error reading file!\n");
        return 0;
    }
    /* check if file is a bitmap */
    if (bfType != 19778) {
        printf("Not a Bitmap-File!\n");
        return 0;
    }
    /* get the file size */
    /* skip file size and reserved fields of bitmap file header */
    fseek(file, 8, SEEK_CUR);
    /* get the position of the actual bitmap data */
    if (!fread(&bfOffBits, sizeof(long int), 1, file)) {
        printf("Error reading file!\n");
        return 0;
    }
    printf("Data at Offset: %ld\n", bfOffBits);
    /* skip size of bitmap info header */
    fseek(file, 4, SEEK_CUR);
    /* get the width of the bitmap */
    fread(&texture->width, sizeof(int), 1, file);
    printf("Width of Bitmap: %d\n", texture->width);
    /* get the height of the bitmap */
    fread(&texture->height, sizeof(int), 1, file);
    printf("Height of Bitmap: %d\n", texture->height);
    /* get the number of planes (must be set to 1) */
    fread(&biPlanes, sizeof(short int), 1, file);
    if (biPlanes != 1) {
        printf("Error: number of Planes not 1!\n");
        return 0;
    }
    /* get the number of bits per pixel */
    if (!fread(&biBitCount, sizeof(short int), 1, file)) {
        printf("Error reading file!\n");
        return 0;
    }
    printf("Bits per Pixel: %d\n", biBitCount);
    if (biBitCount != 24) {
        printf("Bits per Pixel not 24\n");
        return 0;
    }
    /* calculate the size of the image in bytes */
    biSizeImage = texture->width * texture->height * 3;
    printf("Size of the image data: %ld\n", biSizeImage);
    texture->data = malloc(biSizeImage);
    /* seek to the actual data */
    fseek(file, bfOffBits, SEEK_SET);
    if (!fread(texture->data, biSizeImage, 1, file)) {
        printf("Error loading file!\n");
        return 0;
    }
    /* swap red and blue (bgr -> rgb) */
    for (i = 0; i < biSizeImage; i += 3) {
        temp = texture->data[i];
        texture->data[i] = texture->data[i + 2];
        texture->data[i + 2] = temp;
    }
    return 1;
}

#ifdef WITH_SOUND
int loadWave(char* filename, waveFile* waveFile)
{
    FILE* file;
    /* allocate space for the wave header */
    waveFile->header = malloc(sizeof(waveHeader));
    /* make sure the file is there and open it read-only (binary) */
    if ((file = fopen(filename, "rb")) == NULL) {
        printf("File not found : %s\n", filename);
        return 0;
    }
    /* read the wave header */
    if (!fread(waveFile->header, sizeof(waveHeader), 1, file)) {
        printf("Error reading file!\n");
        return 0;
    }
    /* check if it is a riff wave file */
    if (waveFile->header->chunkID != RIFF ||
        waveFile->header->format != WAVE ||
        waveFile->header->subChunk1ID != FMT ||
        waveFile->header->subChunk2ID != DATA) {
        printf("Soundfile %s not in wave format!\n", filename);
        return 0;
    }
    /* we can only handle uncompressed, PCM encoded waves! */
    if (waveFile->header->audioFormat != 1) {
        printf("Soundfile not PCM encoded!\n");
        return 0;
    }
    /* we can only handle up to two channels (stereo) */
    if (waveFile->header->numberOfChannels > 2) {
        printf("Soundfile has more than 2 channels!\n");
        return 0;
    }
    waveFile->sampleData = malloc(waveFile->header->subChunk2Size);
    fseek(file, sizeof(waveHeader), SEEK_SET);
    if (!fread(waveFile->sampleData, waveFile->header->subChunk2Size, 1,
        file)) {
        printf("Error loading file!\n");
        return 0;
    }
    return 1;
}

void playSound(waveFile* sound) {
    if (write(audioDevice, sound->sampleData, sound->header->subChunk2Size) == -1) {
        perror("audio write");
    }
}

int initSound(int bitsPerSample, int numberOfChannels, int samplingRate)
{
    int format;
    int channels;
    int speed;
    
    channels = numberOfChannels;
    speed = samplingRate;
    printf("Sound Init:\nRequested: ");
    printf("Bits:%d, Channels:%d, SampleRate:%d\n", bitsPerSample, channels, speed);
    if ((audioDevice = open("/dev/dsp", O_WRONLY, 0)) == -1) {
        printf("Sound init failed\n");
        perror("/dev/dsp");
        exit(1);
    }
    if (bitsPerSample == 16) {
        format = AFMT_S16_LE;
        if (ioctl(audioDevice, SNDCTL_DSP_SETFMT, &format) == -1) {
            perror("SNDCTL_DSP_SETFMT");
            exit(1);
        }
    } else {
        format = AFMT_U8;
        if (ioctl(audioDevice, SNDCTL_DSP_SETFMT, &format) == -1) {
            perror("SNDCTL_DSP_SETFMT");
            exit(1);
        }
    }
    if (ioctl(audioDevice, SNDCTL_DSP_CHANNELS, &channels) == -1) {
        perror("SNDCTL_DSP_CHANNELS");
        exit(1);
    }
    if (ioctl(audioDevice, SNDCTL_DSP_SPEED, &speed) == -1) {
        perror("SNDCTL_DSP_SPEED");
        exit(1);
    }
    printf("Acquired: Bits:%d, Channels:%d, SampleRate:%d\n", format, channels, speed);
    return 0;
}
#endif

/* Load Bitmaps And Convert To Textures */
Bool loadGLTextures()
{
    Bool status;
    textureImage* texti;

    status = False;
    texti = malloc(sizeof(textureImage) * 2);
    if (loadBmp("Data/font.bmp", &texti[0]) &&
        loadBmp("Data/image.bmp", &texti[1])) {
        status = True;
        glGenTextures(2, &texture[0]);	/* create two textures */
            for (loop1 = 0; loop1 < 2; loop1++) {
            glBindTexture(GL_TEXTURE_2D, texture[loop1]);
            /* use linear filtering */
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            /* actually generate the texture */
            glTexImage2D(GL_TEXTURE_2D, 0, 3, texti[loop1].width,
                    texti[loop1].height, 0, GL_RGB,
                    GL_UNSIGNED_BYTE, texti[loop1].data);
        }
    }
    /* free the ram we used in our texture generation process */
    for (loop1 = 0; loop1 < 2; loop1++) {
        if (&texti[loop1]) {
            if (texti[loop1].data)
                free(texti[loop1].data);
        }
    }
    free(texti);
    return status;
}

void buildFont(void) {
    GLfloat cx, cy;         /* the character coordinates in our texture */
    base = glGenLists(256);
    glBindTexture(GL_TEXTURE_2D, texture[0]);
    for (loop1 = 0; loop1 < 256; loop1++)
    {
        cx = (float) (loop1 % 16) / 16.0f;
        cy = (float) (loop1 / 16) / 16.0f;
        glNewList(base + loop1, GL_COMPILE);
            glBegin(GL_QUADS);
                glTexCoord2f(cx, 1 - cy - 0.0625f);
                glVertex2i(0, 16);
                glTexCoord2f(cx + 0.0625f, 1 - cy - 0.0625f);
                glVertex2i(16, 16);
                glTexCoord2f(cx + 0.0625f, 1 - cy);
                glVertex2i(16, 0);
                glTexCoord2f(cx, 1 - cy);
                glVertex2i(0, 0);
            glEnd();
            glTranslated(15, 0, 0);
        glEndList();
    }
}

void killFont(void) {
    glDeleteLists(base, 256);
}

void printGLf(GLint x, GLint y, int set, const char* fmt, ...) {
    char text[256];
    va_list ap;
    if (fmt == NULL)
        return;
    va_start(ap, fmt);
    vsprintf(text, fmt, ap);
    va_end(ap);
    if (set > 1)
        set = 1;
    glEnable(GL_TEXTURE_2D);
    glLoadIdentity();
    glTranslatef(x, y, 0);
    glListBase(base - 32 + 128 * set);
    if (set == 0)
        glScalef(1.5f, 2.0f, 1.0f);
    glCallLists(strlen(text), GL_UNSIGNED_BYTE, text);
    glDisable(GL_TEXTURE_2D);
}

/* function called when our window is resized (should only happen in window mode) */
void resizeGLScene(unsigned int width, unsigned int height)
{
    if (height == 0)        /* Prevent A Divide By Zero If The Window Is Too Small */
        height = 1;
    glViewport(0, 0, width, height);    /* Reset The Current Viewport And Perspective Transformation */
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0.0f, width, height, 0.0f, -1.0f, 1.0f);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

/* general OpenGL initialization function */
int initGL(GLvoid)
{
    if (!loadGLTextures()) {
        return False;
    }
    buildFont();
    glShadeModel(GL_SMOOTH);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClearDepth(1.0f);
    glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    /* we use resizeGLScene once to set up our initial perspective */
    resizeGLScene(GLWin.width, GLWin.height);
    glFlush();
    return True;
}

/* Here goes our drawing code */
int drawGLScene(GLvoid)
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glBindTexture(GL_TEXTURE_2D, texture[0]);
    glTranslatef(0.0f, 0.0f, -5.0f);
    glColor3f(1.0f, 0.5f, 1.0f);
    printGLf(207, 24, 0, "Grid Crazy");
    glColor3f(1.0f, 1.0f, 0.0f);
    printGLf(20, 20, 1, "Level%2i", level2);
    printGLf(20, 40, 1, "Stage%2i", stage);
    if (gameOver) {
        glColor3ub(rand() % 256, rand() % 256, rand() % 256);
        printGLf(472, 20, 1, "GAME OVER");
        printGLf(456, 40, 1, "PRESS SPACE");
    }
    for (loop1 = 0; loop1 < lives - 1; loop1++) {
        glLoadIdentity();
        glTranslatef(490 + (loop1 * 40), 40.0f, 0.0f);
        glRotatef(-player.spin, 0.0f, 0.0f, 1.0f);
        glColor3f(0.0f, 1.0f, 0.0f);
        glBegin(GL_LINES);
            glVertex2d(-5, -5);
            glVertex2d(5, 5);
            glVertex2d(5, -5);
            glVertex2d(-5, 5);
        glEnd();
        glRotatef(-player.spin * 0.5f, 0.0f, 0.0f, 1.0f);
        glColor3f(0.0f, 0.75f, 0.0f);
        glBegin(GL_LINES);
            glVertex2d(-7, -7);
            glVertex2d(7, 7);
            glVertex2d(7, -7);
            glVertex2d(-7, 7);
        glEnd();
    }
    filled = True;
    glLineWidth(2.0f);
    glDisable(GL_LINE_SMOOTH);
    glLoadIdentity();
    for (loop1 = 0; loop1 < 11; loop1++) {
        for (loop2 = 0; loop2 < 11; loop2++) {
            glColor3f(0.0f, 0.5f, 1.0f);
            if (hlines[loop1][loop2]) {
                glColor3f(1.0f, 1.0f, 1.0f);
            }
            if (loop1 < 10) {
                if (!hlines[loop1][loop2]) {
                    filled = False;
                }
                glBegin(GL_LINES);
                    glVertex2d(20 + (loop1 * 60), 70 + (loop2 * 40));
                    glVertex2d(80 + (loop1 * 60), 70 + (loop2 * 40));
                glEnd();
            }
            glColor3f(0.0f, 0.5f, 1.0f);
            if (vlines[loop1][loop2]) {
                glColor3f(1.0f, 1.0f, 1.0f);
            }
            if (loop2 < 10) {
                if (!vlines[loop1][loop2]) {
                    filled = False;
                }
                glBegin(GL_LINES);
                    glVertex2d(20 + (loop1 * 60), 70 + (loop2 * 40));
                    glVertex2d(20 + (loop1 * 60), 110 + (loop2 * 40));
                glEnd();
            }
            glEnable(GL_TEXTURE_2D);
            glColor3f(1.0f, 1.0f, 1.0f);
            glBindTexture(GL_TEXTURE_2D, texture[1]);
            if (loop1 < 10 && loop2 < 10) {
                if(hlines[loop1][loop2] && hlines[loop1][loop2 + 1] &&
                   vlines[loop1][loop2] && vlines[loop1 + 1][loop2]) {
                    glBegin(GL_QUADS);
                        glTexCoord2f((float)(loop1 / 10.0f) + 0.1f, 1.0f -
                                     (float)(loop2 / 10.0f));
                        glVertex2d(79 + (loop1 * 60), 71 + (loop2 * 40));
                        glTexCoord2f((float)(loop1 / 10.0f), 1.0f -
                                     (float)(loop2 / 10.0f));
                        glVertex2d(21 + (loop1 * 60), 71 + (loop2 * 40));
                        glTexCoord2f((float)(loop1 / 10.0f), 0.9f -
                                     (float)(loop2 / 10.0f));
                        glVertex2d(21 + (loop1 * 60), 109 + (loop2 * 40));
                        glTexCoord2f((float)(loop1 / 10.0f) + 0.1f, 0.9f -
                                     (float)(loop2 / 10.0f));
                        glVertex2d(79 + (loop1 * 60), 109 + (loop2 * 40));
                    glEnd();
                }
            }
            glDisable(GL_TEXTURE_2D);
        }
    }
    glLineWidth(1.0f);
    if (antiAliasing)
        glEnable(GL_LINE_SMOOTH);
    if (hourglass.fx == 1) {
        glLoadIdentity();
        glTranslatef(20.0f + hourglass.x * 60, 70.0f + hourglass.y * 40, 0.0f);
        glRotatef(hourglass.spin, 0.0f, 0.0f, 1.0f);
        glColor3ub(rand() % 256, rand() % 256, rand() % 256);
        glBegin(GL_LINES);
            glVertex2d(-5, -5);
            glVertex2d(5, 5);
            glVertex2d(5, 5);
            glVertex2d(-5, 5);
            glVertex2d(-5, 5);
            glVertex2d(5, -5);
            glVertex2d(5, -5);
            glVertex2d(-5, -5);
        glEnd();
    }
    glLoadIdentity();
    glTranslatef(20.0f + player.fx, 70.0f + player.fy, 0.0f);
    glRotatef(player.spin, 0.0f, 0.0f, 1.0f);
    glColor3f(0.0f, 1.0f, 0.0f);
    glBegin(GL_LINES);
        glVertex2d(-5, -5);
        glVertex2d(5, 5);
        glVertex2d(-5, 5);
        glVertex2d(5, -5);
    glEnd();
    glRotatef(player.spin * 0.5f, 0.0f, 0.0f, 1.0f);
    glColor3f(0.0f, 0.75f, 0.0f);
    glBegin(GL_LINES);
        glVertex2d(-7, 0);
        glVertex2d(7, 0);
        glVertex2d(0, -7);
        glVertex2d(0, 7);
    glEnd();
    for (loop1 = 0; loop1 < (stage * level); loop1++) {
        glLoadIdentity();
        glTranslatef(enemy[loop1].fx + 20, enemy[loop1].fy + 70, 0.0f);
        glColor3f(1.0f, 0.5f, 0.5f);
        glBegin(GL_LINES);
            glVertex2d(0, -7);
            glVertex2d(-7, 0);
            glVertex2d(-7, 0);
            glVertex2d(0, 7);
            glVertex2d(0, 7);
            glVertex2d(7, 0);
            glVertex2d(7, 0);
            glVertex2d(0, -7);
        glEnd();
        glRotatef(enemy[loop1].spin, 0.0f, 0.0f, 1.0f);
        glColor3f(1.0f, 0.0f, 0.0f);
        glBegin(GL_LINES);
            glVertex2d(-7, -7);
            glVertex2d(7, 7);
            glVertex2d(7, -7);
            glVertex2d(-7, 7);
        glEnd();
    }
    glXSwapBuffers(GLWin.dpy, GLWin.win);
    frames++;
    t = getMilliSeconds();
    if (t - t0 >= 5000) {
        GLfloat sec = (t - t0) / 1000.0;
        GLfloat fps = frames / sec;
        printf("%g FPS\n", fps);
        t0 = t;
        frames = 0;
    }
    return True;
}

/* function to release/destroy our resources and restoring the old desktop */
GLvoid killGLWindow(GLvoid)
{
    if (GLWin.ctx) {
    if (!glXMakeCurrent(GLWin.dpy, None, NULL)) {
        printf("Could not release drawing context.\n");
    }
    glXDestroyContext(GLWin.dpy, GLWin.ctx);
    GLWin.ctx = NULL;
    }
    /* switch back to original desktop resolution if we were in fs */
    if (GLWin.fs) {
        XF86VidModeSwitchToMode(GLWin.dpy, GLWin.screen, &GLWin.deskMode);
        XF86VidModeSetViewPort(GLWin.dpy, GLWin.screen, 0, 0);
    }
    killFont();
    XCloseDisplay(GLWin.dpy);
}

/* this function creates our window and sets it up properly */
/* FIXME: bits is currently unused */
Bool createGLWindow(char *title, int width, int height, int bits,
               Bool fullscreenflag)
{
    XVisualInfo *vi;
    Colormap cmap;
    int dpyWidth, dpyHeight;
    int i;
    int glxMajorVersion, glxMinorVersion;
    int vidModeMajorVersion, vidModeMinorVersion;
    XF86VidModeModeInfo **modes;
    int modeNum;
    int bestMode;
    Atom wmDelete;
    Window winDummy;
    unsigned int borderDummy;

    GLWin.fs = fullscreenflag;
    /* set best mode to current */
    bestMode = 0;
    /* get a connection */
    GLWin.dpy = XOpenDisplay(0);
    GLWin.screen = DefaultScreen(GLWin.dpy);
    XF86VidModeQueryVersion(GLWin.dpy, &vidModeMajorVersion,
            &vidModeMinorVersion);
    printf("XF86VidModeExtension-Version %d.%d\n", vidModeMajorVersion,
       vidModeMinorVersion);
    XF86VidModeGetAllModeLines(GLWin.dpy, GLWin.screen, &modeNum, &modes);
    /* save desktop-resolution before switching modes */
    GLWin.deskMode = *modes[0];
    /* look for mode with requested resolution */
    for (i = 0; i < modeNum; i++) {
        if ((modes[i]->hdisplay == width)
                && (modes[i]->vdisplay == height)) {
            bestMode = i;
        }
    }
    /* get an appropriate visual */
    vi = glXChooseVisual(GLWin.dpy, GLWin.screen, attrListDbl);
    if (vi == NULL) {
        vi = glXChooseVisual(GLWin.dpy, GLWin.screen, attrListSgl);
        printf("Only Singlebuffered Visual!\n");
    } else {
        printf("Got Doublebuffered Visual!\n");
    }
    glXQueryVersion(GLWin.dpy, &glxMajorVersion, &glxMinorVersion);
    printf("glX-Version %d.%d\n", glxMajorVersion, glxMinorVersion);
    /* create a GLX context */
    GLWin.ctx = glXCreateContext(GLWin.dpy, vi, 0, GL_TRUE);
    /* create a color map */
    cmap = XCreateColormap(GLWin.dpy, RootWindow(GLWin.dpy, vi->screen),
               vi->visual, AllocNone);
    GLWin.attr.colormap = cmap;
    GLWin.attr.border_pixel = 0;

    if (GLWin.fs) {
        XF86VidModeSwitchToMode(GLWin.dpy, GLWin.screen, modes[bestMode]);
        XF86VidModeSetViewPort(GLWin.dpy, GLWin.screen, 0, 0);
        dpyWidth = modes[bestMode]->hdisplay;
        dpyHeight = modes[bestMode]->vdisplay;
        printf("Resolution %dx%d\n", dpyWidth, dpyHeight);
        XFree(modes);

        /* create a fullscreen window */
        GLWin.attr.override_redirect = True;
        GLWin.attr.event_mask = ExposureMask | KeyPressMask | ButtonPressMask |
                                KeyReleaseMask | StructureNotifyMask;
        GLWin.win = XCreateWindow(GLWin.dpy, RootWindow(GLWin.dpy, vi->screen),
                    0, 0, dpyWidth, dpyHeight, 0, vi->depth, InputOutput,
                    vi->visual, CWBorderPixel | CWColormap |
                    CWEventMask | CWOverrideRedirect, &GLWin.attr);
        XWarpPointer(GLWin.dpy, None, GLWin.win, 0, 0, 0, 0, 0, 0);
        XMapRaised(GLWin.dpy, GLWin.win);
        XGrabKeyboard(GLWin.dpy, GLWin.win, True, GrabModeAsync,
              GrabModeAsync, CurrentTime);
        XGrabPointer(GLWin.dpy, GLWin.win, True, ButtonPressMask,
             GrabModeAsync, GrabModeAsync, GLWin.win, None,
             CurrentTime);
    } else {
        /* create a window in window mode */
        GLWin.attr.event_mask = ExposureMask | KeyPressMask | ButtonPressMask |
                                KeyReleaseMask | StructureNotifyMask;
        GLWin.win = XCreateWindow(GLWin.dpy,
                    RootWindow(GLWin.dpy, vi->screen), 0,
                    0, width, height, 0, vi->depth,
                    InputOutput, vi->visual,
                    CWBorderPixel | CWColormap | CWEventMask,
                    &GLWin.attr);
        /* only set window title and handle wm_delete_events if in windowed mode */
        wmDelete = XInternAtom(GLWin.dpy, "WM_DELETE_WINDOW", True);
        XSetWMProtocols(GLWin.dpy, GLWin.win, &wmDelete, 1);
        XSetStandardProperties(GLWin.dpy, GLWin.win, title,
                   title, None, NULL, 0, NULL);
        XMapRaised(GLWin.dpy, GLWin.win);
    }
    /* connect the glx-context to the window */
    glXMakeCurrent(GLWin.dpy, GLWin.win, GLWin.ctx);
    XGetGeometry(GLWin.dpy, GLWin.win, &winDummy, &GLWin.x, &GLWin.y,
                 &GLWin.width, &GLWin.height, &borderDummy, &GLWin.depth);
    printf("Depth %d\n", GLWin.depth);
    if (glXIsDirect(GLWin.dpy, GLWin.ctx))
        printf("Congrats, you have Direct Rendering!\n");
    else
        printf("Sorry, no Direct Rendering possible!\n");
    initGL();
    return True;
}

void initKeys()
{
    printf("Initializing keys...\n");
    /* get keycode for escape-key */
    keyCodes[0] = XKeysymToKeycode(GLWin.dpy, XK_Escape);
    /* get keycode for F1 */
    keyCodes[1] = XKeysymToKeycode(GLWin.dpy, XK_F1);
    /* get keycode for 'a' */
    keyCodes[2] = XKeysymToKeycode(GLWin.dpy, XK_a);
    /* get keycode for Up-Arrow */
    keyCodes[3] = XKeysymToKeycode(GLWin.dpy, XK_Up);
    /* get keycode for Down-Arrow */
    keyCodes[4] = XKeysymToKeycode(GLWin.dpy, XK_Down);
    /* get keycode for Left-Arrow */
    keyCodes[5] = XKeysymToKeycode(GLWin.dpy, XK_Left);
    /* get keycode for Right-Arrow */
    keyCodes[6] = XKeysymToKeycode(GLWin.dpy, XK_Right);
    /* get keycode for spacebar */
    keyCodes[7] = XKeysymToKeycode(GLWin.dpy, XK_space);
}

void keyAction()
{
    if (keys[keyCodes[0]])
        done = True;
    if (keys[keyCodes[1]]) {
        killGLWindow();
        GLWin.fs = !GLWin.fs;
        createGLWindow(title, 640, 480, 24, GLWin.fs);
        keys[keyCodes[1]] = False;
    }
    if (keys[keyCodes[2]]) {
        antiAliasing = !antiAliasing;
        keys[keyCodes[2]] = False;
    }
    
}

int main(int argc, char **argv)
{
    XEvent event;
    unsigned int start;
    done = False;
    /* default to fullscreen */
    GLWin.fs = False;
    createGLWindow(title, 640, 480, 24, GLWin.fs);
    initKeys();
    resetObjects();
#ifdef WITH_SOUND
    dieWave = malloc(sizeof(waveFile));
    loadWave("Data/die.wav", dieWave);
    freezeWave = malloc(sizeof(waveFile));
    loadWave("Data/freeze.wav", freezeWave);
    completeWave = malloc(sizeof(waveFile));
    loadWave("Data/complete.wav", completeWave);
    hourglassWave = malloc(sizeof(waveFile));
    loadWave("Data/hourglass.wav", hourglassWave);
    /* we setup the sound device according to the format of our wave-file */
    initSound(dieWave->header->bitsPerSample,
        dieWave->header->numberOfChannels,
        dieWave->header->sampleRate);
#endif
    antiAliasing = True;
    gameOver = True;
    t0 = getMilliSeconds();
    /* wait for events */
    while (!done) {
        /* handle the events in the queue */
        while (XPending(GLWin.dpy) > 0) {
            XNextEvent(GLWin.dpy, &event);
            switch (event.type) {
                case Expose:
                    if (event.xexpose.count != 0)
                        break;
                    drawGLScene();
                    break;
                case ConfigureNotify:
                /* call resizeGLScene only if our window-size changed */
                    if ((event.xconfigure.width != GLWin.width) ||
                        (event.xconfigure.height != GLWin.height)) {
                        GLWin.width = event.xconfigure.width;
                        GLWin.height = event.xconfigure.height;
                        printf("Resize event\n");
                        resizeGLScene(event.xconfigure.width,
                                      event.xconfigure.height);
                    }
                    break;
                /* exit in case of a mouse button press */
                case ButtonPress:
                    done = True;
                    break;
                case KeyPress:
                    keys[event.xkey.keycode] = True;
                    break;
                case KeyRelease:
                    keys[event.xkey.keycode] = False;
                    break;
                case ClientMessage:
                    if (*XGetAtomName(GLWin.dpy,
                        event.xclient.message_type) ==
                        *"WM_PROTOCOLS") {
                        printf("Exiting sanely...\n");
                        done = True;
                    }
                    break;
                default:
                    break;
            }
        }
        start = getMilliSeconds();
        drawGLScene();
        while (getMilliSeconds() < start + steps[adjust] * 2) {
        }
        keyAction();
        if (!gameOver) {
            for (loop1 = 0; loop1 < (stage * level); loop1++) {
                if ((enemy[loop1].x < player.x) &&
                    (enemy[loop1].fy == enemy[loop1].y * 40)) {
                    enemy[loop1].x++;
                }
                if ((enemy[loop1].x > player.x) &&
                    (enemy[loop1].fy == enemy[loop1].y * 40)) {
                    enemy[loop1].x--;
                }
                if ((enemy[loop1].y < player.y) &&
                    (enemy[loop1].fx == enemy[loop1].x * 60)) {
                    enemy[loop1].y++;
                }
                if ((enemy[loop1].y > player.y) &&
                    (enemy[loop1].fx == enemy[loop1].x * 60)) {
                    enemy[loop1].y--;
                }
                if (delay > (3 - level) && hourglass.fx != 2) {
                    delay = 0;
                    for (loop2 = 0; loop2 < (stage * level); loop2++) {
                        if (enemy[loop2].fx < enemy[loop2].x * 60) {
                            enemy[loop2].fx += steps[adjust];
                            enemy[loop2].spin += steps[adjust];
                        }
                        if (enemy[loop2].fx > enemy[loop2].x * 60) {
                            enemy[loop2].fx -= steps[adjust];
                            enemy[loop2].spin -= steps[adjust];
                        }
                        if (enemy[loop2].fy < enemy[loop2].y * 40) {
                            enemy[loop2].fy += steps[adjust];
                            enemy[loop2].spin += steps[adjust];
                        }
                        if (enemy[loop2].fy > enemy[loop2].y * 40) {
                            enemy[loop2].fy -= steps[adjust];
                            enemy[loop2].spin -= steps[adjust];
                        }
                    }
                }
                if (enemy[loop1].fx == player.fx && enemy[loop1].fy == player.fy) {
                    lives--;
                    if (lives == 0)
                        gameOver = True;
                    resetObjects();
#ifdef WITH_SOUND
                    /* play die sound */
                    playSound(dieWave);
#endif
                }
            }
            if (keys[keyCodes[3]] && player.y > 0 && player.fx == (player.x * 60) &&
                player.fy == (player.y * 40)) {
                player.y--;
                vlines[player.x][player.y] = True;
            }
            if (keys[keyCodes[4]] && player.y < 10 && player.fx == (player.x * 60) &&
                player.fy == (player.y * 40)) {
                vlines[player.x][player.y] = True;
                player.y++;
            }
            if (keys[keyCodes[5]] && player.x > 0 && player.fx == (player.x * 60) &&
                player.fy == (player.y * 40)) {
                player.x--;
                hlines[player.x][player.y] = True;
            }
            if (keys[keyCodes[6]] && player.x < 10 && player.fx == (player.x * 60) &&
                player.fy == (player.y * 40)) {
                hlines[player.x][player.y] = True;
                player.x++;
            }
            if (player.fx < (player.x * 60))
                player.fx += steps[adjust];
            if (player.fx > player.x * 60)
                player.fx -= steps[adjust];
            if (player.fy < player.y * 40)
                player.fy += steps[adjust];
            if (player.fy > player.y * 40)
                player.fy -= steps[adjust];
        } else {
            if (keys[keyCodes[7]]) {
                keys[keyCodes[7]] = False;
                gameOver = False;
                filled = True;
                level = 1;
                level2 = 1;
                stage = 0;
                lives = 5;
            }
        }
        if (filled) {
#ifdef WITH_SOUND
            /* play complete sound */
            playSound(completeWave);
#endif
            stage++;
            if (stage > 3) {
                stage = 1;
                level++;
                level2++;
                if (level > 3) {
                    level = 3;
                    lives++;
                    if (lives > 5)
                        lives = 5;
                }
            }
            resetObjects();
            for (loop1 = 0; loop1 < 11; loop1++) {
                for (loop2 = 0; loop2 < 11; loop2++) {
                    if (loop1 < 10)
                        hlines[loop1][loop2] = False;
                    if (loop2 < 10)
                        vlines[loop1][loop2] = False;
                }
            }
        }
        if (player.fx == hourglass.x * 60 && player.fy == hourglass.y * 40
            && hourglass.fx == 1) {
#ifdef WITH_SOUND
                /* play freeze sound */
            playSound(freezeWave);
#endif
            hourglass.fx = 2;
            hourglass.fy = 0;
        }
        player.spin += 0.5f * steps[adjust];
        if (player.spin > 360.0f)
            player.spin -= 360.0f;
        hourglass.spin -= 0.25f * steps[adjust];
        if (hourglass.spin < -360.0f)
            hourglass.spin += 360.0f;
        hourglass.fy += steps[adjust];
        if (hourglass.fx == 0 && hourglass.fy > 6000 / level) {
#ifdef WITH_SOUND
            /* play hourglass sound */
            playSound(hourglassWave);
#endif
            hourglass.x = rand() % 10 + 1;
            hourglass.y = rand() % 11;
            hourglass.fx = 1;
            hourglass.fy = 0;
        }
        if (hourglass.fx == 1 && hourglass.fy > 6000 / level) {
            hourglass.fx = 0;
            hourglass.fy = 0;
        }
        if (hourglass.fx == 2 && hourglass.fy > 500 + 500 * level) {
            /* stop freeze sound (not implemented) */
            hourglass.fx = 0;
            hourglass.fy = 0;
        }
        delay++;
    }
    killGLWindow();
    return 0;
}
