const std = @import("std");

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();
    const input_name = args.next() orelse "./inputs/4.txt";

    var io: std.Io.Threaded = .init_single_threaded;

    var input_file = try std.fs.cwd().openFile(input_name, .{ .mode = .read_only });
    var read_buffer = std.mem.zeroes([4096]u8);
    var input_reader = input_file.reader(io.io(), &read_buffer);

    var reader = &input_reader.interface;

    var buffer: [8327498]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var grid: std.ArrayList(std.ArrayList(u8)) = .empty;

    while (reader.takeDelimiter('\n')) |line_or_null| {
        const line = std.mem.trimEnd(u8, line_or_null orelse break, "\n");

        var row: std.ArrayList(u8) = try .initCapacity(allocator, line.len);

        try row.appendSlice(allocator, line);
        try grid.append(allocator, row);
    } else |err| switch (err) {
        error.StreamTooLong, // line could not fit in buffer
        error.ReadFailed, // caller can check reader implementation for diagnostics
        => |e| return e,
    }

    var accessible: u64 = 0;

    for (grid.items, 0..) |row, i| {
        for (row.items, 0..) |cell, j| {
            if (cell == '@') {
                var neighbours: u8 = 0;

                if (i > 0) {
                    if (j > 0) {
                        if (grid.items[i - 1].items[j - 1] == '@') {
                            neighbours += 1;
                        }
                    }
                    if (grid.items[i - 1].items[j] == '@') {
                        neighbours += 1;
                    }
                    if (j < row.items.len - 1) {
                        if (grid.items[i - 1].items[j + 1] == '@') {
                            neighbours += 1;
                        }
                    }
                }
                if (j > 0) {
                    if (grid.items[i].items[j - 1] == '@') {
                        neighbours += 1;
                    }
                }
                if (j < row.items.len - 1) {
                    if (grid.items[i].items[j + 1] == '@') {
                        neighbours += 1;
                    }
                }
                if (i < grid.items.len - 1) {
                    if (j > 0) {
                        if (grid.items[i + 1].items[j - 1] == '@') {
                            neighbours += 1;
                        }
                    }
                    if (grid.items[i + 1].items[j] == '@') {
                        neighbours += 1;
                    }
                    if (j < row.items.len - 1) {
                        if (grid.items[i + 1].items[j + 1] == '@') {
                            neighbours += 1;
                        }
                    }
                }

                if (neighbours < 4) {
                    accessible += 1;
                }
            }
        }
    }

    std.debug.print("Part 1: {}\n", .{accessible});

    var removable: u64 = 0;
    var removed_any: bool = true;

    while (removed_any) {
        removed_any = false;

        for (grid.items, 0..) |row, i| {
            for (row.items, 0..) |cell, j| {
                if (cell == '@') {
                    var neighbours: u8 = 0;

                    if (i > 0) {
                        if (j > 0) {
                            if (grid.items[i - 1].items[j - 1] == '@') {
                                neighbours += 1;
                            }
                        }
                        if (grid.items[i - 1].items[j] == '@') {
                            neighbours += 1;
                        }
                        if (j < row.items.len - 1) {
                            if (grid.items[i - 1].items[j + 1] == '@') {
                                neighbours += 1;
                            }
                        }
                    }
                    if (j > 0) {
                        if (grid.items[i].items[j - 1] == '@') {
                            neighbours += 1;
                        }
                    }
                    if (j < row.items.len - 1) {
                        if (grid.items[i].items[j + 1] == '@') {
                            neighbours += 1;
                        }
                    }
                    if (i < grid.items.len - 1) {
                        if (j > 0) {
                            if (grid.items[i + 1].items[j - 1] == '@') {
                                neighbours += 1;
                            }
                        }
                        if (grid.items[i + 1].items[j] == '@') {
                            neighbours += 1;
                        }
                        if (j < row.items.len - 1) {
                            if (grid.items[i + 1].items[j + 1] == '@') {
                                neighbours += 1;
                            }
                        }
                    }

                    if (neighbours < 4) {
                        removable += 1;
                        removed_any = true;
                        row.items[j] = '.';
                    }
                }
            }
        }
    }

    std.debug.print("Part 2: {}\n", .{removable});
}
