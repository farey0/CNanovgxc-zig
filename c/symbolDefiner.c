#include "glad.h"

#include "nanovg.h"

#if NANOVG_USE_OPENGL == 1
#define NANOVG_GLES3_IMPLEMENTATION
#else
#define NANOVG_GL3_IMPLEMENTATION
#endif

#if defined(NANOVG_BACKEND_vtex)

#include "nanovg_vtex.h"
#include "nanovg_gl_utils.h"

#elif defined(NANOVG_BACKEND_gl)

#include "nanovg_gl.h"
#include "nanovg_gl_utils.h"

#elif defined(NANOVG_BACKEND_sw)

#define NANOVG_SW_IMPLEMENTATION

#if NANOVG_USE_OPENGL == 1
#define NVGSWU_GLES3
#else
#define NVGSWU_GL3
#endif

#include "nanovg_sw.h"
#include "nanovg_sw_utils.h"

#endif
