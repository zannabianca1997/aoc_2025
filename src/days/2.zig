const std = @import("std");

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();
    const input_name = args.next() orelse "./inputs/2.txt";

    var io: std.Io.Threaded = .init_single_threaded;

    var input_file = try std.fs.cwd().openFile(input_name, .{ .mode = .read_only });
    var read_buffer = std.mem.zeroes([4096]u8);
    var input_reader = input_file.reader(io.io(), &read_buffer);

    var reader = &input_reader.interface;

    var invalid_sum: u64 = 0;

    while (reader.takeDelimiter(',')) |range_or_null| {
        const range = range_or_null orelse break;

        var endpoints = std.mem.splitScalar(u8, range, '-');
        const start = try std.fmt.parseInt(u64, endpoints.next() orelse unreachable, 10);
        const end = try std.fmt.parseInt(u64, std.mem.trimEnd(u8, endpoints.rest(), "\n"), 10);

        var digits: u64 = 1;
        while (true) : (digits += 1) {
            const base = (try std.math.powi(u64, 10, digits)) + 1;
            if (base > end) break;

            const min_mult = @divExact(base - 1, 10);
            const max_mult = base - 2;

            const start_mult = @max(@divFloor(start - 1, base) + 1, min_mult);
            const end_mult = @min(@divFloor(end, base), max_mult) + 1;

            if (start_mult >= end_mult) break;

            for (start_mult..end_mult) |mult| {
                const id = base * mult;

                invalid_sum += id;
            }
        }
    } else |err| switch (err) {
        error.StreamTooLong, // line could not fit in buffer
        error.ReadFailed, // caller can check reader implementation for diagnostics
        => |e| return e,
    }

    std.debug.print("Part 1: {}\n", .{invalid_sum});

    invalid_sum = 0;

    try input_reader.seekTo(0);
    reader = &input_reader.interface;

    while (reader.takeDelimiter(',')) |range_or_null| {
        const range = range_or_null orelse break;

        var endpoints = std.mem.splitScalar(u8, range, '-');
        const start = try std.fmt.parseInt(u64, endpoints.next() orelse unreachable, 10);
        const end = try std.fmt.parseInt(u64, std.mem.trimEnd(u8, endpoints.rest(), "\n"), 10);

        std.debug.print("{}-{}: ", .{ start, end });

        var digits: u64 = 1;
        while (true) : (digits += 1) {
            var repeats: u64 = 2;
            while (true) : (repeats += 1) {
                // checks that repeats is prime
                if (!isPrime(repeats)) {
                    repeats += 1;
                    continue;
                }

                var base: u64 = 0;
                for (0..repeats) |r| {
                    base += (try std.math.powi(u64, 10, digits * r));
                }

                if (base >= end) break;

                const min_mult = try std.math.powi(u64, 10, digits - 1);
                const max_mult = min_mult * 10 - 1;

                const start_mult = @max(@divFloor(start - 1, base) + 1, min_mult);
                const end_mult = @min(@divFloor(end, base), max_mult) + 1;

                if (start_mult >= end_mult) break;

                for (start_mult..end_mult) |mult| {
                    const id = base * mult;

                    std.debug.print("{} ", .{id});
                    invalid_sum += id;
                }
            }
            if (repeats == 2) break;
        }

        std.debug.print("\n", .{});
    } else |err| switch (err) {
        error.StreamTooLong, // line could not fit in buffer
        error.ReadFailed, // caller can check reader implementation for diagnostics
        => |e| return e,
    }

    std.debug.print("Part 2: {}\n", .{invalid_sum});
}

fn isPrime(int: u64) bool {
    var i: u64 = 2;
    var is_prime = true;
    while (i < int) : (i += 1) {
        if (int % i == 0) {
            is_prime = false;
            break;
        }
    }
    return is_prime;
}
