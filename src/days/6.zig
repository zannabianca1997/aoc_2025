const std = @import("std");

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();
    const input_name = args.next() orelse "./inputs/6.txt";

    var io: std.Io.Threaded = .init_single_threaded;

    var input_file = try std.fs.cwd().openFile(input_name, .{ .mode = .read_only });

    var read_buffer = std.mem.zeroes([4096]u8);
    var input_reader = input_file.reader(io.io(), &read_buffer);

    var reader = &input_reader.interface;

    var buffer: [1000000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var lines: std.ArrayList([]const u8) = .empty;

    while (reader.takeDelimiter('\n')) |line_or_null| {
        const line = std.mem.trimEnd(u8, line_or_null orelse break, "\n");
        if (line.len > 0) {
            const line_copy = try allocator.dupe(u8, line);
            try lines.append(allocator, line_copy);
        }
    } else |err| switch (err) {
        error.StreamTooLong, // line could not fit in buffer
        error.ReadFailed, // caller can check reader implementation for diagnostics
        => |e| return e,
    }

    const all_operands = lines.items[0 .. lines.items.len - 1];
    const all_operators = lines.items[lines.items.len - 1];

    var slice_start: usize = 0;

    var total_p1: u64 = 0;
    var total_p2: u64 = 0;

    for (0..all_operators.len + 1) |col| {
        var is_sep = true;
        if (col < all_operators.len) {
            is_sep = all_operators[col] == ' ';
            for (all_operands) |op| {
                is_sep = is_sep and op[col] == ' ';
            }
        }
        if (!is_sep) continue;

        const op = all_operators[slice_start];
        const is_mult = switch (op) {
            '+' => false,
            '*' => true,
            else => {
                std.debug.panic("Invalid op {c}", .{op});
            },
        };

        var operands = try std.ArrayList([]const u8).initCapacity(allocator, all_operands.len);
        defer operands.deinit(allocator);
        for (all_operands) |line| {
            operands.appendAssumeCapacity(line[slice_start..col]);
        }

        // Part 1
        var res: u64 = if (is_mult) 1 else 0;
        for (operands.items) |operand_s| {
            const operand = try std.fmt.parseInt(u64, std.mem.trim(u8, operand_s, " "), 10);
            if (is_mult) {
                res *= operand;
            } else {
                res += operand;
            }
        }
        total_p1 += res;

        // Part 2

        // Transpose operands: create new matrix where rows become columns
        var transposed = try std.ArrayList(std.ArrayList(u8)).initCapacity(allocator, operands.items[0].len);
        defer {
            for (transposed.items) |*row| {
                row.deinit(allocator);
            }
            transposed.deinit(allocator);
        }

        // Initialize transposed matrix
        for (0..operands.items[0].len) |_| {
            const row = try std.ArrayList(u8).initCapacity(allocator, operands.items.len);
            transposed.appendAssumeCapacity(row);
        }

        // Fill transposed matrix
        for (operands.items) |operand| {
            for (operand, 0..) |char, col_idx| {
                transposed.items[col_idx].appendAssumeCapacity(char);
            }
        }

        // Part 2 calculation
        var res_p2: u64 = if (is_mult) 1 else 0;
        for (transposed.items) |transposed_operand| {
            const operand_str = std.mem.trim(u8, transposed_operand.items, " ");
            if (operand_str.len == 0) continue;

            const operand = try std.fmt.parseInt(u64, operand_str, 10);
            if (is_mult) {
                res_p2 *= operand;
            } else {
                res_p2 += operand;
            }
        }
        total_p2 += res_p2;

        slice_start = col + 1;
    }

    std.debug.print("Part 1: {}\nPart 2: {}\n", .{ total_p1, total_p2 });
}
