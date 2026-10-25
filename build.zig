const std = @import("std");
const builtin = @import("builtin");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const graphics_dep = b.dependency("zig_graphics_bindings", .{
        .target = target,
        .optimize = optimize,
    });
    const rl_imgui = graphics_dep.module("rl_imgui");
    const rl_imgui_artifact = graphics_dep.artifact("rl_imgui");
    const cimgui = graphics_dep.module("cimgui");
    const cimgui_artifact = graphics_dep.artifact("cimgui");

    const calc_mod = b.createModule(.{
        .root_source_file = b.path("src/projectile_motion_calculator.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("raylib", raylib);
    exe_mod.addImport("rl_imgui", rl_imgui);
    exe_mod.addImport("cimgui", cimgui);
    exe_mod.addImport("projectile_calc", calc_mod);

    const run_step = b.step("run", "Run the app");

    //web exports are completely separate
    if (target.query.os_tag == .emscripten) {
        const emsdk = rlz.emsdk;
        const wasm = b.addLibrary(.{
            .name = "projectile_sim_zig",
            .root_module = exe_mod,
        });

        const install_dir: std.Build.InstallDir = .{ .custom = "web" };
        // const html_filename = b.fmt("{s}.html", .{wasm.name});
        const js_filename = b.fmt("{s}.js", .{wasm.name});
        const emcc_flags = emsdk.emccDefaultFlags(b.allocator, .{
            .optimize = optimize,
        });

        var emcc_settings = emsdk.emccDefaultSettings(b.allocator, .{
            .optimize = optimize,
        });
        try emcc_settings.put("MODULARIZE", "1");
        try emcc_settings.put("EXPORT_NAME", "createApp");
        try emcc_settings.put("EXPORT_ES6", "1");

        const emcc_step = try emsdk.emccStep(b, &.{}, &.{ raylib_artifact, cimgui_artifact, rl_imgui_artifact, wasm }, .{
            .optimize = optimize,
            .flags = emcc_flags,
            .settings = emcc_settings,
            // .shell_file_path = raylib_dep.builder.dependency("raylib", .{}).path("src/shell.html"),
            .install_dir = install_dir,
            // .preload_paths = &.{.{ .src_path = b.path("resources"), .virtual_path = "resources" }},
            .out_file_name = js_filename,
        });
        // emcc.py can not be spawned directly on Windows, use emcc.bat instead
        if (builtin.os.tag == .windows) {
            for (emcc_step.dependencies.items) |dep| {
                const run = dep.cast(std.Build.Step.Run) orelse continue;
                run.argv.items[0].lazy_path.lazy_path = try emsdk.path(b, "upstream/emscripten/emcc.bat");
            }
        }
        b.getInstallStep().dependOn(emcc_step);

        // const emrun_step = try emsdk.emrunStep(
        //     b,
        //     b.graph.path(.install_prefix, b.fmt("web/{s}", .{js_filename})),
        //     &.{},
        // );

        // emrun_step.dependOn(emcc_step);
        // run_step.dependOn(emrun_step);
    } else {
        const exe = b.addExecutable(.{
            .name = "projectile_sim_zig",
            .root_module = exe_mod,
        });
        exe.root_module.linkLibrary(rl_imgui_artifact);
        exe.root_module.linkLibrary(cimgui_artifact);
        // exe.root_module.linkLibrary(implot_artifact);

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        run_step.dependOn(&run_cmd.step);
    }
}