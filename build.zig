const std = @import("std");

pub fn build(b: *std.Build) void {
    // Get the directory handle with iteration permissions
    var days_dir_handle = std.fs.cwd().openDir("src/days", .{ .iterate = true }) catch |err| {
        std.log.warn("Failed to open src/days directory: {}\n", .{err});
        return;
    };
    defer days_dir_handle.close();

    // Iterate through all .zig files in the directory
    var iter = days_dir_handle.iterate();
    while (iter.next() catch |err| {
        std.log.warn("Failed to iterate directory: {}\n", .{err});
        return;
    }) |entry| {
        // Only process .zig files
        if (std.mem.endsWith(u8, entry.name, ".zig")) {
            // Extract the day number from filename (e.g., "1.zig" -> "day-1")
            const day_num = std.mem.trimRight(u8, entry.name, ".zig");
            const exe_name = std.fmt.allocPrint(b.allocator, "day-{s}", .{day_num}) catch {
                std.log.warn("Failed to allocate executable name for {s}\n", .{entry.name});
                continue;
            };

            const day_exe = b.addExecutable(.{
                .name = exe_name,
                .root_module = b.createModule(.{
                    .root_source_file = b.path(std.fmt.allocPrint(b.allocator, "src/days/{s}", .{entry.name}) catch {
                        std.log.warn("Failed to allocate path for {s}\n", .{entry.name});
                        continue;
                    }),
                    .target = b.graph.host,
                }),
            });

            b.installArtifact(day_exe);
        }
    }
}
