const std = @import("std");

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();
    const input_name = args.next() orelse "./inputs/7.txt";

    var io: std.Io.Threaded = .init_single_threaded;

    var input_file = try std.fs.cwd().openFile(input_name, .{ .mode = .read_only });
    var read_buffer = std.mem.zeroes([4096]u8);
    var input_reader = input_file.reader(io.io(), &read_buffer);
    var reader = &input_reader.interface;

    var buffer: [256]usize = undefined;
    var timelines = std.ArrayList(usize).initBuffer(&buffer);

    // Read first line
    var ch = try reader.takeByte();
    var pos: usize = 0;
    while (ch != '\n') : ({
        ch = try reader.takeByte();
        pos += 1;
    }) {
        if (ch == 'S') {
            timelines.appendAssumeCapacity(1);
        } else {
            timelines.appendAssumeCapacity(0);
        }
    }

    var bufferNext: [256]usize = undefined;
    var timelinesNext = std.ArrayList(usize).initBuffer(&bufferNext);

    var splits: usize = 0;
    while (true) {
        timelinesNext.clearRetainingCapacity();
        timelinesNext.appendNTimesAssumeCapacity(0, timelines.items.len);

        pos = 0;
        ch = reader.takeByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };
        while (ch != '\n') : ({
            ch = try reader.takeByte();
            pos += 1;
        }) {
            if (ch == '^' and timelines.items[pos] > 0) {
                timelinesNext.items[pos - 1] += timelines.items[pos];
                timelinesNext.items[pos + 1] += timelines.items[pos];
                splits += 1;
            } else {
                timelinesNext.items[pos] += timelines.items[pos];
            }
        }

        std.mem.swap(std.ArrayList(usize), &timelines, &timelinesNext);
    }

    var total_timelines: u64 = 0;
    for (timelines.items) |value| {
        total_timelines += value;
    }

    std.debug.print("Part 1: {}\nPart 2: {}\n", .{ splits, total_timelines });
}
