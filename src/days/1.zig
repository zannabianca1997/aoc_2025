const std = @import("std");

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();
    const input_name = args.next() orelse "./inputs/1.txt";

    var io: std.Io.Threaded = .init_single_threaded;

    var input_file = try std.fs.cwd().openFile(input_name, .{ .mode = .read_only });
    var read_buffer = std.mem.zeroes([4096]u8);
    var input_reader = input_file.reader(io.io(), &read_buffer);

    var reader = &input_reader.interface;

    var total: i16 = 50;
    var count: u16 = 0;

    while (reader.takeDelimiterExclusive('\n')) |line| {
        _ = try reader.takeByte();

        const command = line[0];
        const amount = try std.fmt.parseInt(i16, line[1..], 10);

        switch (command) {
            'L' => total -= amount,
            'R' => total += amount,
            else => unreachable,
        }

        if (@mod(total, 100) == 0) {
            count += 1;
        }
    } else |err| switch (err) {
        error.EndOfStream => |_| {}, // stream ended not on a line break
        error.StreamTooLong, // line could not fit in buffer
        error.ReadFailed, // caller can check reader implementation for diagnostics
        => |e| return e,
    }

    std.debug.print("Part 1: {}\n", .{count});

    total = 50;
    count = 0;

    try input_reader.seekTo(0);
    reader = &input_reader.interface;

    while (reader.takeDelimiterExclusive('\n')) |line| {
        _ = try reader.takeByte();

        const command = line[0];
        var amount = try std.fmt.parseInt(i16, line[1..], 10);

        count += @intCast(@divTrunc(amount, 100));
        amount = @rem(amount, 100);

        for (0..@intCast(amount)) |_| {
            switch (command) {
                'L' => total -= 1,
                'R' => total += 1,
                else => unreachable,
            }

            if (@mod(total, 100) == 0) {
                count += 1;
            }
        }
    } else |err| switch (err) {
        error.EndOfStream => |_| {}, // stream ended not on a line break
        error.StreamTooLong, // line could not fit in buffer
        error.ReadFailed, // caller can check reader implementation for diagnostics
        => |e| return e,
    }

    std.debug.print("Part 2: {}\n", .{count});
}
