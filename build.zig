const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const nanovgxcSource = b.dependency("nanovgxc", .{});

    var cFlags = std.ArrayList([]const u8).init(b.allocator);
    defer cFlags.deinit();

    var systemLibs = std.ArrayList([]const u8).init(b.allocator);
    defer systemLibs.deinit();

    const buildExemple = b.option(bool, "exemple", "build exemple. default: false") orelse false;

    const backend = b.option([]const u8, "backend", "either \"vtex\", \"gl\" or \"sw\". see nanovgXC readme. default: gl") orelse "gl";
    const glEs = b.option(bool, "gles", "use gles instead of gl. default: false") orelse false;

    try cFlags.appendSlice(&.{
        "-D_USE_MATH_DEFINES",
        "-DUNICODE",
        "-DNOMINMAX",
        "-Wall",
        "-Wshadow",
        "-Wno-unused-function",
    });

    // Make Nanovg path for nanovgxcPatcher.c

    var nanovgPath = std.ArrayList(u8).init(b.allocator);
    defer nanovgPath.deinit();

    try nanovgPath.appendSlice("-DNANOVG_PATH=\"");
    try nanovgPath.appendSlice(nanovgxcSource.path("").getPath(b));
    try nanovgPath.appendSlice("/src/nanovg.c\"");

    for (nanovgPath.items) |*char| {
        if (char.* == '\\')
            char.* = '/';
    }

    try cFlags.append(nanovgPath.items);

    // Pass backend to nanovgxcPatcher.c

    var backendC = std.ArrayList(u8).init(b.allocator);
    defer backendC.deinit();

    if (!std.mem.eql(u8, "vtex", backend) and !std.mem.eql(u8, "gl", backend) and !std.mem.eql(u8, "sw", backend)) {
        std.log.warn("backend : {s}", .{backend});
        @panic("Invalid backend build option");
    }

    try backendC.appendSlice("-DNANOVG_BACKEND_");
    try backendC.appendSlice(backend);

    try cFlags.append(backendC.items);

    // Pass gles to nanovgxcPatcher.c

    var glEsC = std.ArrayList(u8).init(b.allocator);
    defer glEsC.deinit();

    try glEsC.appendSlice("-DNANOVG_USE_OPENGL=");
    try glEsC.appendSlice(if (glEs) "1" else "0");

    try cFlags.append(glEsC.items);

    if (target.result.os.tag == .windows) {
        try systemLibs.appendSlice(&.{
            "glu32",
            "opengl32",
            "gdi32",
            "user32",
            "shell32",
            "winmm",
            "ole32",
            "oleaut32",
            "advapi32",
            "setupapi",
            "imm32",
            "version",
        });
    } else {
        try systemLibs.appendSlice(&.{
            "pthread",
            "dl",
            "m",
            "GL",
        });
    }

    const lib = b.addStaticLibrary(.{
        .name = "nanovgxc",
        .target = target,
        .optimize = optimize,
    });

    lib.linkLibC();

    lib.addIncludePath(nanovgxcSource.path("example/stb/"));
    lib.addIncludePath(nanovgxcSource.path("src/"));
    lib.addIncludePath(nanovgxcSource.path("glad/"));

    lib.addCSourceFiles(.{
        .root = nanovgxcSource.path(""),
        .files = &.{
            "glad/glad.c",
        },
        .flags = cFlags.items,
    });

    lib.addCSourceFiles(.{
        .files = &.{
            "c/nanovgxcPatcher.c",
            "c/fontStashImplementation.c",
            "c/symbolDefiner.c",
        },
        .flags = cFlags.items,
    });

    lib.installHeadersDirectoryOptions(.{
        .source_dir = nanovgxcSource.path("src/"),
        .install_dir = .header,
        .install_subdir = "",
        .include_extensions = &.{".h"},
    });

    lib.installHeadersDirectoryOptions(.{
        .source_dir = nanovgxcSource.path("glad/"),
        .install_dir = .header,
        .install_subdir = "",
        .include_extensions = &.{".h"},
    });

    lib.installHeadersDirectoryOptions(.{
        .source_dir = nanovgxcSource.path("example/stb/"),
        .install_dir = .header,
        .install_subdir = "",
        .include_extensions = &.{".h"},
    });

    for (systemLibs.items) |libName| {
        lib.linkSystemLibrary(libName);
    }

    b.installArtifact(lib);

    if (buildExemple) {
        const glfw = b.lazyDependency("glfw", .{
            .target = target,
            .optimize = optimize,
        }) orelse return;

        const exe = b.addExecutable(.{
            .name = "nanovgxc-build-zig",
            .root_source_file = .{ .path = "exemple/main.zig" },
            .target = target,
            .optimize = optimize,
        });

        exe.linkLibrary(lib);

        const exeOptions = b.addOptions();
        exeOptions.addOption([]const u8, "backend", backend);

        const exeOptionsModule = exeOptions.createModule();

        exe.root_module.addImport("options", exeOptionsModule);
        exe.root_module.addImport("mach-glfw", glfw.module("mach-glfw"));

        b.installArtifact(exe);
    }
}
