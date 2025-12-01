const std = @import("std");

pub fn build(b: *std.Build) void {
    const day_1 = b.addExecutable(.{
        .name = "day-1",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/days/1.zig"),
            .target = b.graph.host,
        }),
    });

    b.installArtifact(day_1);

    const run_exe = b.addRunArtifact(day_1);

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
