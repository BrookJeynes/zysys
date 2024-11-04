const std = @import("std");

const release_targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .macos },
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build targets for release.
    const build_all = b.option(bool, "all-targets", "Build all targets in ReleaseSafe mode.") orelse false;
    if (build_all) {
        try build_targets(b);
        return;
    }

    const ziggy_dep = b.dependency("ziggy", .{
        .target = target,
        .optimize = optimize,
    });
    const ziggy = ziggy_dep.module("ziggy");

    const exe = b.addExecutable(.{
        .name = "zysys",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("ziggy", ziggy);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn build_targets(b: *std.Build) !void {
    for (release_targets) |t| {
        const target = b.resolveTargetQuery(t);

        const ziggy_dep = b.dependency("ziggy", .{
            .target = target,
            .optimize = .ReleaseSafe,
        });
        const ziggy = ziggy_dep.module("ziggy");

        const exe = b.addExecutable(.{
            .name = "zysys",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = .ReleaseSafe,
        });
        exe.root_module.addImport("ziggy", ziggy);
        b.installArtifact(exe);

        const target_output = b.addInstallArtifact(exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = try t.zigTriple(b.allocator),
                },
            },
        });

        b.getInstallStep().dependOn(&target_output.step);
    }
}