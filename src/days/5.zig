const std = @import("std");

const Range = struct {
    start: u64,
    end: u64,
};

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();
    const input_name = args.next() orelse "./inputs/5.txt";

    var io: std.Io.Threaded = .init_single_threaded;

    var input_file = try std.fs.cwd().openFile(input_name, .{ .mode = .read_only });
    var read_buffer = std.mem.zeroes([4096]u8);
    var input_reader = input_file.reader(io.io(), &read_buffer);

    var reader = &input_reader.interface;

    var buffer: [1000000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var ranges: std.ArrayList(Range) = .empty;
    var available_ids: std.ArrayList(u64) = .empty;

    var parsing_ranges = true;

    while (reader.takeDelimiter('\n')) |line_or_null| {
        const line = std.mem.trimEnd(u8, line_or_null orelse break, "\n");

        if (line.len == 0) {
            parsing_ranges = false;
            continue;
        }

        if (parsing_ranges) {
            if (std.mem.indexOfScalar(u8, line, '-')) |dash_pos| {
                const start_str = line[0..dash_pos];
                const end_str = line[dash_pos + 1 ..];

                const start = try std.fmt.parseInt(u64, start_str, 10);
                const end = try std.fmt.parseInt(u64, end_str, 10);

                try ranges.append(allocator, Range{ .start = start, .end = end });
            }
        } else {
            const id = try std.fmt.parseInt(u64, line, 10);
            try available_ids.append(allocator, id);
        }
    } else |err| switch (err) {
        error.StreamTooLong, // line could not fit in buffer
        error.ReadFailed, // caller can check reader implementation for diagnostics
        => |e| return e,
    }

    var fresh_count: u64 = 0;

    for (available_ids.items) |id| {
        for (ranges.items) |range| {
            if (id >= range.start and id <= range.end) {
                fresh_count += 1;
                break;
            }
        }
    }

    std.debug.print("Part 1: {}\n", .{fresh_count});

    var sorted_ranges = try allocator.alloc(Range, ranges.items.len);
    defer allocator.free(sorted_ranges);

    for (ranges.items, 0..) |range, i| {
        sorted_ranges[i] = range;
    }

    // Sort ranges
    for (0..sorted_ranges.len - 1) |i| {
        for (0..sorted_ranges.len - i - 1) |j| {
            if (sorted_ranges[j].start > sorted_ranges[j + 1].start) {
                const temp = sorted_ranges[j];
                sorted_ranges[j] = sorted_ranges[j + 1];
                sorted_ranges[j + 1] = temp;
            }
        }
    }

    // Merge overlapping ranges
    var merged_ranges: std.ArrayList(Range) = .empty;
    try merged_ranges.append(allocator, sorted_ranges[0]);

    for (sorted_ranges[1..]) |range| {
        const last_merged = &merged_ranges.items[merged_ranges.items.len - 1];
        if (range.start <= last_merged.end + 1) {
            if (range.end > last_merged.end) {
                last_merged.end = range.end;
            }
        } else {
            try merged_ranges.append(allocator, range);
        }
    }

    var total_fresh_ids: u64 = 0;
    for (merged_ranges.items) |range| {
        total_fresh_ids += (range.end - range.start + 1);
    }

    std.debug.print("Part 2: {}\n", .{total_fresh_ids});
}
