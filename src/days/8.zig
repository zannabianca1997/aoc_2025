const std = @import("std");

const NodeData = struct { pos: [3]u64, circuit_id: u16 };

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();
    const input_name = args.next() orelse "./inputs/8.txt";

    var io: std.Io.Threaded = .init_single_threaded;

    var input_file = try std.fs.cwd().openFile(input_name, .{ .mode = .read_only });

    var read_buffer = std.mem.zeroes([4096]u8);
    var input_reader = input_file.reader(io.io(), &read_buffer);

    var reader = &input_reader.interface;

    var buffer: [20000000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // Parse triples of integers from input as we read
    var nodes = try std.ArrayList(NodeData).initCapacity(allocator, 100);
    defer nodes.deinit(allocator);

    while (reader.takeDelimiter('\n')) |line_or_null| {
        const line = std.mem.trimEnd(u8, line_or_null orelse break, "\n");
        if (line.len > 0) {
            var it = std.mem.tokenizeScalar(u8, line, ',');
            var triple: [3]u64 = undefined;

            for (0..3) |i| {
                const num_str = it.next() orelse return error.InvalidInput;
                triple[i] = try std.fmt.parseInt(u64, std.mem.trim(u8, num_str, " \t"), 10);
            }

            try nodes.append(allocator, .{ .pos = triple, .circuit_id = @intCast(nodes.items.len) });
        }
    } else |err| switch (err) {
        error.StreamTooLong, // line could not fit in buffer
        error.ReadFailed, // caller can check reader implementation for diagnostics
        => |e| return e,
    }

    const total_triples = nodes.items.len;

    // Allocate dists array with size total_triples squared
    const dists_size = total_triples * total_triples;
    var dists = try allocator.alloc(u64, dists_size);
    defer allocator.free(dists);

    var shortests = try std.ArrayList(u64).initCapacity(allocator, dists_size);

    // Calculate squared Euclidean distances between all pairs
    for (0..total_triples) |i| {
        dists[i * total_triples + i] = 0;
        for (i + 1..total_triples) |j| {
            const triple1 = nodes.items[i].pos;
            const triple2 = nodes.items[j].pos;

            // Calculate squared Euclidean distance
            const dx = @max(triple1[0], triple2[0]) - @min(triple1[0], triple2[0]);
            const dy = @max(triple1[1], triple2[1]) - @min(triple1[1], triple2[1]);
            const dz = @max(triple1[2], triple2[2]) - @min(triple1[2], triple2[2]);

            const dist_sq = dx * dx + dy * dy + dz * dz;
            dists[i * total_triples + j] = dist_sq;

            // Insert dist_sq maintaining the list sorted using bisection
            var insert_pos = shortests.items.len;
            var left: usize = 0;
            var right = shortests.items.len;

            while (left < right) {
                const mid = left + (right - left) / 2;
                if (dist_sq < shortests.items[mid]) {
                    right = mid;
                } else {
                    left = mid + 1;
                }
            }
            insert_pos = left;
            shortests.insertAssumeCapacity(insert_pos, dist_sq);
        }
    }

    // All nodes with a distance less or equal to this one are now connected
    var connections: usize = 1000;
    var connect_threshold = shortests.items[connections];
    for (0..total_triples) |i| {
        for (i + 1..total_triples) |j| {
            const c1 = nodes.items[i].circuit_id;
            const c2 = nodes.items[j].circuit_id;
            if (dists[i * total_triples + j] <= connect_threshold and c1 != c2) {
                // connection between two different circuits
                // merging them
                for (0..total_triples) |k| {
                    if (nodes.items[k].circuit_id == c2) {
                        nodes.items[k].circuit_id = c1;
                    }
                }
            }
        }
    }

    // Find the size of the three largest circuits
    var circuit_sizes = std.AutoHashMap(u16, usize).init(allocator);
    defer circuit_sizes.deinit();

    // Count nodes in each circuit
    for (nodes.items) |node| {
        const count = circuit_sizes.get(node.circuit_id) orelse 0;
        try circuit_sizes.put(node.circuit_id, count + 1);
    }

    var largest_circuits = std.mem.zeroes([3]usize);

    {
        var sizes = circuit_sizes.valueIterator();
        while (sizes.next()) |size_ptr| {
            const size: usize = size_ptr.*;

            if (size > largest_circuits[0]) {
                largest_circuits[2] = largest_circuits[1];
                largest_circuits[1] = largest_circuits[0];
                largest_circuits[0] = size;
            } else if (size > largest_circuits[1]) {
                largest_circuits[2] = largest_circuits[1];
                largest_circuits[1] = size;
            } else if (size > largest_circuits[2]) {
                largest_circuits[2] = size;
            }
        }
    }

    var part1: u64 = 1;
    for (largest_circuits) |value| {
        part1 *= value;
    }

    var n1 = NodeData{ .pos = .{ 0, 0, 0 }, .circuit_id = 0 };
    var n2 = NodeData{ .pos = .{ 0, 0, 0 }, .circuit_id = 0 };

    while (circuit_sizes.count() > 1) {
        connections += 1;
        connect_threshold = shortests.items[connections];

        var found = false;
        for (0..total_triples) |i| {
            for (i + 1..total_triples) |j| {
                if (dists[i * total_triples + j] == connect_threshold) {
                    n1 = nodes.items[i];
                    n2 = nodes.items[j];

                    if (n1.circuit_id != n2.circuit_id) {
                        // connection between two different circuits
                        // merging them
                        for (0..total_triples) |k| {
                            if (nodes.items[k].circuit_id == n2.circuit_id) {
                                nodes.items[k].circuit_id = n1.circuit_id;
                            }
                        }
                        const s1 = circuit_sizes.get(n1.circuit_id) orelse unreachable;
                        const s2 = (circuit_sizes.fetchRemove(n2.circuit_id) orelse unreachable).value;
                        circuit_sizes.putAssumeCapacity(n1.circuit_id, s1 + s2);
                    }

                    found = true;
                    break;
                }
            }
            if (found) {
                break;
            }
        }
    }

    const part2 = n1.pos[0] * n2.pos[0];

    std.debug.print("Part 1: {}\nPart 2: {}\n", .{ part1, part2 });
}
