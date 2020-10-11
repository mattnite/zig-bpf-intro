const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});

    const bpf = std.build.Pkg{
        .name = "bpf",
        .path = "libs/bpf/exports.zig",
    };

    const obj = b.addObject("probe", "src/probe.zig");
    obj.setTarget(std.zig.CrossTarget{
        .cpu_arch = switch ((target.cpu_arch orelse builtin.arch).endian()) {
            .Big => .bpfeb,
            .Little => .bpfel,
        },
        .os_tag = .freestanding,
    });
    obj.setBuildMode(.ReleaseFast);
    obj.addPackage(bpf);
    obj.setOutputDir("src");

    const mode = b.standardReleaseOptions();
    const main = b.addExecutable("main", "src/main.zig");
    main.setTarget(target);
    main.setBuildMode(mode);
    main.addPackage(bpf);
    main.linkLibC();
    main.install();
    main.step.dependOn(&obj.step);

    const run_main = main.run();
    run_main.step.dependOn(b.getInstallStep());

    const run = b.step("run", "Run main");
    run.dependOn(&run_main.step);
}
