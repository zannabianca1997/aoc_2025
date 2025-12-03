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

    const day_2 = b.addExecutable(.{
        .name = "day-2",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/days/2.zig"),
            .target = b.graph.host,
        }),
    });

    b.installArtifact(day_2);

    const day_3 = b.addExecutable(.{
        .name = "day-3",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/days/3.zig"),
            .target = b.graph.host,
        }),
    });

    b.installArtifact(day_3);
}
