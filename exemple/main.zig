const std = @import("std");
const glfw = @import("mach-glfw");
const options = @import("options");

pub fn ComptimeCompare(comptime a: []const u8, b: []const u8) bool {
    if (a.len != b.len)
        return false;

    for (a, b) |valA, valB| {
        if (valA != valB)
            return false;
    }

    return true;
}

const nanovg = @cImport({
    @cInclude("glad.h");
    @cInclude("nanovg.h");
    if (ComptimeCompare(options.backend, "vtex")) {
        @cInclude("nanovg_vtex.h");
        @cInclude("nanovg_gl_utils.h");
    } else if (ComptimeCompare(options.backend, "gl")) {
        @cInclude("nanovg_gl.h");
        @cInclude("nanovg_gl_utils.h");
    } else if (ComptimeCompare(options.backend, "sw")) {
        @cInclude("nanovg_sw.h");
        @cInclude("nanovg_sw_utils.h");
    } else {
        @compileError("options.backend is not defined to a correct value");
    }
});

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(
        640,
        480,
        "Hello, mach-glfw!",
        null,
        null,
        .{
            .context_version_major = 3,
            .context_version_minor = 3,
            .opengl_forward_compat = true,
            .opengl_profile = .opengl_core_profile,
        },
    ) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);

    if (nanovg.gladLoadGLLoader(@as(nanovg.GLADloadproc, @ptrCast(&glfw.getProcAddress))) == 0) {
        std.log.err("failed to initialize GLAD", .{});
        std.process.exit(1);
    }

    const vgContext: *nanovg.NVGcontext = nanovg.nvglCreate(nanovg.NVG_SRGB) orelse {
        std.log.err("failed to create nanovg context", .{});
        std.process.exit(1);
    };

    defer nanovg.nvglDelete(vgContext);

    //glfw.swapInterval(0);

    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        const wSize = window.getSize();
        const fSize = window.getFramebufferSize();
        const pxRatio: f32 = @as(f32, @floatFromInt(fSize.width)) / @as(f32, @floatFromInt(wSize.width));

        nanovg.nvgluSetViewport(0, 0, @intCast(fSize.width), @intCast(fSize.height));

        nanovg.nvgluClear(nanovg.nvgRGBAf(0.3, 0.3, 0.32, 1.0));

        nanovg.nvgBeginFrame(vgContext, @floatFromInt(wSize.width), @floatFromInt(wSize.height), pxRatio);

        nanovg.nvgBeginPath(vgContext);

        nanovg.nvgRect(vgContext, 100, 100, 300, 150);
        nanovg.nvgFillColor(vgContext, nanovg.nvgRGBA(255, 0, 0, 192));
        nanovg.nvgFill(vgContext);
        nanovg.nvgClosePath(vgContext);

        nanovg.nvgBeginPath(vgContext);
        nanovg.nvgCircle(vgContext, 100, 400, 40);
        nanovg.nvgFillColor(vgContext, nanovg.nvgRGBA(255, 0, 0, 192));
        nanovg.nvgFill(vgContext);
        nanovg.nvgClosePath(vgContext);

        nanovg.nvgEndFrame(vgContext);

        window.swapBuffers();
        glfw.pollEvents();
    }
}
