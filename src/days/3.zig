const std = @import("std");

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();
    const input_name = args.next() orelse "./inputs/3.txt";

    var io: std.Io.Threaded = .init_single_threaded;

    var input_file = try std.fs.cwd().openFile(input_name, .{ .mode = .read_only });
    var read_buffer = std.mem.zeroes([4096]u8);
    var input_reader = input_file.reader(io.io(), &read_buffer);

    var reader = &input_reader.interface;

    var joltage: u64 = 0;

    while (reader.takeDelimiter('\n')) |line_or_null| {
        const line = std.mem.trimEnd(u8, line_or_null orelse break, "\n");

        const i = std.mem.findMax(u8, line[0 .. line.len - 1]);
        const j = std.mem.findMax(u8, line[i + 1 ..]) + i + 1;

        const bank_joltage = @as(u64, @intCast(line[i] - '0')) * 10 + @as(u64, @intCast(line[j] - '0'));

        joltage += bank_joltage;
    } else |err| switch (err) {
        error.StreamTooLong, // line could not fit in buffer
        error.ReadFailed, // caller can check reader implementation for diagnostics
        => |e| return e,
    }

    std.debug.print("Part 1: {}\n", .{joltage});

    joltage = 0;

    try input_reader.seekTo(0);
    reader = &input_reader.interface;

    while (reader.takeDelimiter('\n')) |line_or_null| {
        const line = std.mem.trimEnd(u8, line_or_null orelse break, "\n");

        var indices = std.mem.zeroes([12]usize);

        indices[0] = std.mem.findMax(u8, line[0 .. line.len - 11]);
        for (1..12) |i| {
            indices[i] = std.mem.findMax(u8, line[indices[i - 1] + 1 .. line.len - 11 + i]) + indices[i - 1] + 1;
        }

        var bank_joltage: u64 = 0;

        for (indices, 0..) |idx, i| {
            const mult = try std.math.powi(u64, 10, 11 - i);
            bank_joltage += mult * @as(u64, @intCast(line[idx] - '0'));
        }

        joltage += bank_joltage;
    } else |err| switch (err) {
        error.StreamTooLong, // line could not fit in buffer
        error.ReadFailed, // caller can check reader implementation for diagnostics
        => |e| return e,
    }

    std.debug.print("Part 2: {}\n", .{joltage});
}
