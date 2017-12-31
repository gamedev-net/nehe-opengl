using System;
using System.Windows.Forms;
using System.Runtime.InteropServices;		// DllImport

namespace Lesson2
{
	/// <summary>
	/// Summary description for OpenGLForm.
	/// </summary>
	public class OpenGLForm : Form
	{
		#region Member Variables

		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;

		private static uint						_hwnd	= 0;
		private static uint						_hDC	= 0;
		private static uint						_hRC	= 0;

		private bool							_appActive = true;
		private bool							_done = true;
		private bool							_fullScreen = false;

		/* Accessors */
		public bool FullScreen
		{
			get
			{
				return _fullScreen;
			}
			set
			{
				_fullScreen = value;
			}
		}

		public bool Done
		{
			get
			{
				return _done;
			}
			set
			{
				_done = value;
			}
		}

		#endregion
		#region Win32 Interop

		// Constant values were found in the "WinUser.h" header file.
		public const int WM_ACTIVATEAPP			= 0x001C;
		public const int WA_ACTIVE				= 1;
		public const int WA_CLICKACTIVE			= 2;
		public const int CDS_FULLSCREEN			= 0x00000004;	// Flag for ChangeDisplaySettings
		public const int DISP_CHANGE_SUCCESSFUL	= 0;			// Return value for ChangeDisplaySettings

		// Constant values were found in the "WinGDI.h" header file.
		public const int CCHDEVICENAME			= 32;			// size of a device name string
		public const int CCHFORMNAME			= 32;			// size of a form name string
		public const int DM_BITSPERPEL			= 0x40000;
		public const int DM_PELSWIDTH			= 0x80000;
		public const int DM_PELSHEIGHT			= 0x100000;
		public const int BITSPIXEL				= 12;			// number of bits per pixel
		public const uint  PFD_DOUBLEBUFFER		= 0x00000001;	// PIXELFORMATDESCRIPTOR flag
		public const uint  PFD_DRAW_TO_WINDOW	= 0x00000004;	// PIXELFORMATDESCRIPTOR flag
		public const uint  PFD_SUPPORT_OPENGL	= 0x00000020;	// PIXELFORMATDESCRIPTOR flag
		public const uint  PFD_TYPE_RGBA        = 0;			// pixel type
		public const uint  PFD_MAIN_PLANE       = 0;			// layer type

		[StructLayout(LayoutKind.Sequential)] 
			public struct PIXELFORMATDESCRIPTOR 
		{
			public ushort  nSize;
			public ushort  nVersion;
			public uint    dwFlags;
			public byte    iPixelType;
			public byte    cColorBits;
			public byte    cRedBits;
			public byte    cRedShift;
			public byte    cGreenBits;
			public byte    cGreenShift;
			public byte    cBlueBits;
			public byte    cBlueShift;
			public byte    cAlphaBits;
			public byte    cAlphaShift;
			public byte    cAccumBits;
			public byte    cAccumRedBits;
			public byte    cAccumGreenBits;
			public byte    cAccumBlueBits;
			public byte    cAccumAlphaBits;
			public byte    cDepthBits;
			public byte    cStencilBits;
			public byte    cAuxBuffers;
			public byte    iLayerType;
			public byte    bReserved;
			public uint    dwLayerMask;
			public uint    dwVisibleMask;
			public uint    dwDamageMask;
		}

		// by marking the structure with CharSet.Auto, the structure will get marshaled as Unicode characters
		// on Unicode platforms, if not the name fields would always get marshaled as arrays of ANSI characters
		[StructLayout(LayoutKind.Sequential, CharSet=CharSet.Auto)]
			public class DEVMODE 
		{
			[MarshalAs(UnmanagedType.ByValArray, SizeConst=CCHDEVICENAME)]
			public char[]			dmDeviceName;
			public short			dmSpecVersion; 
			public short			dmDriverVersion; 
			public short			dmSize; 
			public short			dmDriverExtra; 
			public int				dmFields; 
			public DEVMODE_UNION	u;
			public short			dmColor;
			public short			dmDuplex;
			public short			dmYResolution;
			public short			dmTTOption;
			public short			dmCollate;
			[MarshalAs(UnmanagedType.ByValArray, SizeConst=CCHFORMNAME)]
			public char[]			dmFormName;
			public short			dmLogPixels;
			public int				dmBitsPerPel;
			public int				dmPelsWidth;
			public int				dmPelsHeight;
			public int				dmDisplayFlagsOrdmNup;		// union of dmDisplayFlags and dmNup
			public int				dmDisplayFrequency;
			public int				dmICMMethod;
			public int				dmICMIntent;
			public int				dmMediaType;
			public int				dmDitherType;
			public int				dmReserved1;
			public int				dmReserved2;
			public int				dmPanningWidth;
			public int				dmPanningHeight;
		}

		// modeling a union in C#, each possible struct data type starts at FieldOffset 0
		[StructLayout(LayoutKind.Explicit)] 
			public struct DEVMODE_UNION 
		{ 
			[FieldOffset(0)]
			public short dmOrientation;
			[FieldOffset(2)]
			public short dmPaperSize;
			[FieldOffset(4)]
			public short dmPaperLength;
			[FieldOffset(6)]
			public short dmPaperWidth;
			[FieldOffset(8)]
			public short dmScale;
			[FieldOffset(10)]
			public short dmCopies;
			[FieldOffset(12)]
			public short dmDefaultSource;
			[FieldOffset(14)]
			public short dmPrintQuality;

			[FieldOffset(0)]
			public int dmPosition_x;
			[FieldOffset(4)]
			public int dmPosition_y;

			[FieldOffset(0)]
			public int dmDisplayOrientation;

			[FieldOffset(0)]
			public int dmDisplayFixedOutput;
		}

		#endregion
		#region DLLImport

		[DllImport("kernel32")]
		public static extern uint GetLastError();
		[DllImport("user32")]
		public static extern uint GetDC(uint hwnd);
		[DllImport("user32")]
		public static extern int ReleaseDC(uint hWnd, uint hDC);
		[DllImport("user32", CharSet=CharSet.Auto)]
		public static extern int ChangeDisplaySettings([MarshalAs(UnmanagedType.LPStruct)] DEVMODE lpDevMode, uint dwflags);
		[DllImport("user32")]
		public static extern int ShowCursor(bool bShow);

		[DllImport("gdi32")]
		public static extern int ChoosePixelFormat(uint hdc, ref PIXELFORMATDESCRIPTOR ppfd);
		[DllImport("gdi32")]
		public static extern int SetPixelFormat(uint hdc, int iPixelFormat, ref PIXELFORMATDESCRIPTOR ppfd);
		[DllImport("gdi32")]
		public static extern int GetDeviceCaps(uint hdc, int nIndex);

		[DllImport("opengl32")]
		public static extern uint wglCreateContext(uint hdc);
		[DllImport("opengl32")]
		public static extern bool wglDeleteContext(uint hrc);
		[DllImport("opengl32")]
		public static extern uint wglSwapBuffers(uint hdc);
		[DllImport("opengl32")]
		public static extern bool wglMakeCurrent(uint hdc, uint hglrc);

		[DllImport("opengl32")] 
		public static extern void glViewport(int x, int y, int width, int height);
		[DllImport("opengl32")] 
		public static extern void glMatrixMode(uint mode);
		[DllImport("opengl32")] 
		public static extern void glLoadIdentity();
		[DllImport("opengl32")] 
		public static extern void glEnable(uint cap);
		[DllImport("opengl32")] 
		public static extern void glDisable(uint cap);
		[DllImport("opengl32")] 
		public static extern void glBegin(uint mode);
		[DllImport("opengl32")] 
		public static extern void glEnd();
		[DllImport("opengl32")]
		public static extern void glClear(uint mask);
		[DllImport("opengl32")] 
		public static extern void glShadeModel(uint mode);
		[DllImport("opengl32")] 
		public static extern void glClearColor(float red, float green, float blue, float alpha);
		[DllImport("opengl32")] 
		public static extern void glClearDepth(double depth);
		[DllImport("opengl32")] 
		public static extern void glDepthFunc(uint func);
		[DllImport("opengl32")] 
		public static extern void glHint(uint target, uint mode);
		[DllImport("opengl32")]
		public static extern void glTranslatef(float x, float y, float z);
		[DllImport("opengl32")]
		public static extern void glVertex3f(float x, float y, float z);

		[DllImport("glu32")] 
		public static extern void gluPerspective(double fovy, double aspect, double near, double far);

		#endregion
		#region OpenGL defines

		/* MatrixMode */
		public const uint	GL_MODELVIEW						= 0x1700;
		public const uint	GL_PROJECTION						= 0x1701;

		/* ShadingModel */
		public const uint	GL_SMOOTH							= 0x1D01;

		/* GetTarget */
		public const uint	GL_DEPTH_TEST						= 0x0B71;
		public const uint	GL_PERSPECTIVE_CORRECTION_HINT		= 0x0C50;

		/* AlphaFunction */
		public const uint	GL_LEQUAL							= 0x0203;

		/* AttribMask */
		public const uint	GL_DEPTH_BUFFER_BIT					= 0x00000100;
		public const uint	GL_COLOR_BUFFER_BIT					= 0x00004000;

		/* HintMode */
		public const uint	GL_NICEST							= 0x1102;

		/* BeginMode */
		public const uint	GL_TRIANGLES						= 0x0004;
		public const uint	GL_QUADS							= 0x0007;

		#endregion	
		#region OpenGLSetup

		private bool SetupPixelFormat(ref uint hdc)
		{
			PIXELFORMATDESCRIPTOR	pfd	= new PIXELFORMATDESCRIPTOR();

			ushort	pfdSize = (ushort)Marshal.SizeOf(typeof(PIXELFORMATDESCRIPTOR));		// sizeof(PIXELFORMATDESCRIPTOR)

			pfd.nSize = pfdSize;							 								// size of pfd
			pfd.nVersion = 1;																// version number
			pfd.dwFlags = (PFD_SUPPORT_OPENGL |  PFD_DRAW_TO_WINDOW | PFD_DOUBLEBUFFER);	// flags
			pfd.iPixelType = (byte)PFD_TYPE_RGBA;											// RGBA type
			pfd.cColorBits = (byte)GetDeviceCaps(hdc, BITSPIXEL);							// color depth
			pfd.cRedBits = 0;																// color bits ignored
			pfd.cRedShift = 0;
			pfd.cGreenBits = 0;
			pfd.cGreenShift = 0;
			pfd.cBlueBits = 0;
			pfd.cBlueShift = 0;
			pfd.cAlphaBits = 0;																// no alpha buffer
			pfd.cAlphaShift = 0;															// shift bit ignored
			pfd.cAccumBits = 0;																// no accumulation buffer 
			pfd.cAccumRedBits = 0;															// accum bits ignored
			pfd.cAccumGreenBits = 0;
			pfd.cAccumBlueBits = 0;
			pfd.cAccumAlphaBits = 0;
			pfd.cDepthBits = 32;															// 32-bit z-buffer
			pfd.cStencilBits = 0;															// no stencil buffer
			pfd.cAuxBuffers = 0;															// no auxiliary buffer
			pfd.iLayerType = (byte)PFD_MAIN_PLANE;											// main layer
			pfd.bReserved = 0;																// reserved
			pfd.dwLayerMask = 0;															// layer masks ignored
			pfd.dwVisibleMask = 0;
			pfd.dwDamageMask = 0;

			int pixelformat = ChoosePixelFormat(hdc, ref pfd);
			if (pixelformat == 0)															// Did Windows Find A Matching Pixel Format?
			{
				MessageBox.Show("Can't Find A Suitable PixelFormat.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
				return false;
			}

			if (SetPixelFormat(hdc, pixelformat, ref pfd) == 0)								// Are We Able To Set The Pixel Format?
			{
				MessageBox.Show("Can't Set The PixelFormat.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
				return false;
			}
			return true;
		}

		private bool InitGL()											// All Setup For OpenGL Goes Here
		{
			glShadeModel(GL_SMOOTH);									// Enable Smooth Shading
			glClearColor(0.0f, 0.0f, 0.0f, 0.5f);						// Black Background
			glClearDepth(1.0f);											// Depth Buffer Setup
			glEnable(GL_DEPTH_TEST);									// Enables Depth Testing
			glDepthFunc(GL_LEQUAL);										// The Type Of Depth Testing To Do
			glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);			// Really Nice Perspective Calculations
			return true;												// Initialization Went OK
		}

		public bool SetupRenderingContext()
		{
			if (!CreateGLWindow())
			{
				return false;							// initialization failed, quit
			}

			_hwnd = (uint)((this.Handle).ToInt32());
			_hDC = GetDC(_hwnd);
			if (_hDC == 0)
			{
				MessageBox.Show("Can't Create A GL Device Context", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
				return false;
			}

			// not doing the following wglSwapBuffers() on the DC will result in a failure to subsequently create the RC
			wglSwapBuffers(_hDC);

			if (!SetupPixelFormat(ref _hDC))
			{
				return false;
			}

			// create the rendering context and make it current
			_hRC = wglCreateContext(_hDC);
			if (_hRC == 0)								// Are We Able To Get A Rendering Context?
			{
				MessageBox.Show("Can't Create A GL Rendering Context.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
				return false;
			}
			if (!wglMakeCurrent(_hDC, _hRC))			// Try To Activate The Rendering Context
			{
				MessageBox.Show("Can't Activate The GL Rendering Context.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
				return false;
			}

			OpenGLForm_Resize(this, new EventArgs());	// Set up the perspective GL screen

			return InitGL();							// Initialize Our Newly Created GL Window
		}

		#endregion
		#region FormSetup

		private bool CreateGLWindow()
		{
			Resize += new EventHandler(OpenGLForm_Resize);

			if (FullScreen)																// Attempt Fullscreen Mode?
			{
				TopMost = true;
				WindowState = System.Windows.Forms.FormWindowState.Maximized;
				FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
				
				// The cursor is displayed only if the display count is greater than or equal to 0
				do
				{
				}while (ShowCursor(false) >= 0);

				DEVMODE dmScreenSettings = new DEVMODE();								// Device Mode
				dmScreenSettings.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));		// Size Of The Devmode Structure
				dmScreenSettings.dmPelsWidth	= 640;									// Selected Screen Width
				dmScreenSettings.dmPelsHeight	= 480;									// Selected Screen Height
				dmScreenSettings.dmBitsPerPel	= 16;									// Selected Bits Per Pixel
				dmScreenSettings.dmFields		= DM_PELSWIDTH | DM_PELSHEIGHT | DM_BITSPERPEL;

				// Try To Set Selected Mode And Get Results.  NOTE: CDS_FULLSCREEN Gets Rid Of Start Bar.
				if (ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN)!= DISP_CHANGE_SUCCESSFUL)
				{
					// If The Mode Fails, Offer Two Options.  Quit Or Use Windowed Mode.
					if (MessageBox.Show("The Requested Fullscreen Mode Is Not Supported By\nYour Video Card. Use Windowed Mode Instead?",
						"Error", MessageBoxButtons.YesNo, MessageBoxIcon.Error) == DialogResult.Yes)
					{
						FullScreen = false;		// Windowed Mode Selected.  Fullscreen = FALSE
					}
					else
					{
						// Pop Up A Message Box Letting User Know The Program Is Closing.
						MessageBox.Show("Program Will Now Close.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Stop);
						return false;		// setup failed, finished
					}
				}
			}

			if (!FullScreen)
			{
				TopMost = false;
				WindowState = System.Windows.Forms.FormWindowState.Normal;
				FormBorderStyle = System.Windows.Forms.FormBorderStyle.Sizable;

				// The cursor is displayed only if the display count is greater than or equal to 0
				do
				{
				}while (ShowCursor(true) < 0);
			}

			return true;
		}

		#endregion
		#region Constructor/Destructor

		public OpenGLForm()
		{
			//
			// Required for Windows Form Designer support
			//
			InitializeComponent();
		}

		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		protected override void Dispose(bool disposing)
		{
			if (disposing)
			{
				if (components != null) 
				{
					components.Dispose();
				}

				if (_hRC != 0)										// Do We Have A Rendering Context?
				{
					if (!wglMakeCurrent(0, 0))						// Are We Able To Release The DC And RC Contexts?
					{
						MessageBox.Show("Release Of DC And RC Failed.", "Shutdown Error", MessageBoxButtons.OK, MessageBoxIcon.Information);
					}

					if (!wglDeleteContext(_hRC))					// Are We Able To Delete The RC?
					{
						MessageBox.Show("Release Rendering Context Failed.", "Shutdown Error", MessageBoxButtons.OK, MessageBoxIcon.Information);
					}
				}
				if (_hDC != 0 && ReleaseDC(_hwnd, _hDC) == 0)		// Are We Able To Release The DC
				{
					MessageBox.Show("Release Device Context Failed.", "Shutdown Error", MessageBoxButtons.OK, MessageBoxIcon.Information);
				}
			}
			base.Dispose(disposing);
		}

		#endregion
		#region Windows Form Designer generated code

		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{
			// 
			// OpenGLForm
			// 
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(632, 453);
			this.KeyPreview = true;
			this.Name = "OpenGLForm";
			this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
			this.Text = "\"NeHe\'s First Polygon Tutorial\"";
			this.KeyUp += new System.Windows.Forms.KeyEventHandler(this.OpenGLForm_KeyUp);

		}

		#endregion
		#region Events

		protected override void WndProc(ref System.Windows.Forms.Message m) 
		{
			// Listen for operating system messages.
			switch (m.Msg)
			{
				// The WM_ACTIVATEAPP message occurs when the application
				// becomes the active application or becomes inactive.
				case WM_ACTIVATEAPP:
				{
					// The WParam value identifies what is occurring.
					_appActive = ((int)m.WParam == WA_ACTIVE || (int)m.WParam == WA_CLICKACTIVE);

					// Invalidate to get new scene painted.
					Invalidate();
					break;
				}
				default:
				{
					break;
				}
			}
			base.WndProc(ref m);
		}

		/*!
			This will stop the display from flickering on Paint event
		*/
		protected override void OnPaintBackground(PaintEventArgs e)
		{
		}

		protected override void OnPaint(PaintEventArgs e)
		{
			// make sure the app is active
			if (_appActive)
			{
				DrawGLScene();							// Draw The Scene
				wglSwapBuffers(_hDC);					// Swap Buffers (Double Buffering)
				Invalidate();							// force another paint event
			}
		}

		private void OpenGLForm_KeyUp(object sender, System.Windows.Forms.KeyEventArgs e)
		{
			switch (e.KeyCode)
			{
				case Keys.Escape:
				{
					Close();
					break;
				}
				case Keys.F1:
				{
					if (FullScreen)							// Are We In Fullscreen Mode?
					{
						ChangeDisplaySettings(null, 0);			// If So Switch Back To The Desktop
					}
					FullScreen = !FullScreen;
					Done = false;
					Close();									// raise Close event to kill the current form, the form will get re-created in Main
					break;
				}
				default:
				{
					break;
				}
			}
		}

		private void OpenGLForm_Resize(object sender, EventArgs e)		// Resize And Initialize The GL Window
		{
			int width = ClientRectangle.Width;
			int height = ClientRectangle.Height;

			if (height == 0)											// Prevent A Divide By Zero By
			{
				height = 1;												// Making Height Equal One
			}

			glViewport(0, 0, width, height);							// Reset The Current Viewport

			glMatrixMode(GL_PROJECTION);								// Select The Projection Matrix
			glLoadIdentity();											// Reset The Projection Matrix

			// Calculate The Aspect Ratio Of The Window
			gluPerspective(45.0f, (double)width / (double)height, 0.1f, 100.0f);

			glMatrixMode(GL_MODELVIEW);									// Select The Modelview Matrix
			glLoadIdentity();											// Reset The Modelview Matrix
		}

		#endregion

		/// <summary>
		/// The main entry point for the application.
		/// </summary>
		[STAThread]
		static void Main() 
		{
			bool	fullScreen = false;

			// Ask The User Which Screen Mode They Prefer
			if (MessageBox.Show("Would You Like To Run In Fullscreen Mode?", "Start FullScreen?",
				MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
			{
				fullScreen = true;
			}

			while (true)
			{
				OpenGLForm form = new OpenGLForm();				// create the form

				form.FullScreen = fullScreen;					// set the user display property option

				if (!form.SetupRenderingContext())				// setup form and OpenGL
				{
					break;										// initialization failed, quit
				}

				Application.Run(form);

				if (form.Done)									// Was There A Quit Received?
				{
					break;
				}
				fullScreen = form.FullScreen;					// switching between full screen and windowed, persist full screen option between forms
			}
		}

		public bool DrawGLScene()								// Here's Where We Do All The Drawing
		{
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear Screen And Depth Buffer
			glLoadIdentity();									// Reset The Current Modelview Matrix
			glTranslatef(-1.5f,0.0f,-6.0f);						// Move Left 1.5 Units And Into The Screen 6.0
			glBegin(GL_TRIANGLES);								// Drawing Using Triangles
				glVertex3f( 0.0f, 1.0f, 0.0f);					// Top
				glVertex3f(-1.0f,-1.0f, 0.0f);					// Bottom Left
				glVertex3f( 1.0f,-1.0f, 0.0f);					// Bottom Right
			glEnd();											// Finished Drawing The Triangle
			glTranslatef(3.0f,0.0f,0.0f);						// Move Right 3 Units
			glBegin(GL_QUADS);									// Draw A Quad
				glVertex3f(-1.0f, 1.0f, 0.0f);					// Top Left
				glVertex3f( 1.0f, 1.0f, 0.0f);					// Top Right
				glVertex3f( 1.0f,-1.0f, 0.0f);					// Bottom Right
				glVertex3f(-1.0f,-1.0f, 0.0f);					// Bottom Left
			glEnd();											// Done Drawing The Quad
			return true;										// Keep Going
		}
	}
}
