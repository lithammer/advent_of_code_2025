const std = @import("std");

const Dial = struct {
    position: i16,
    counter: i16,

    fn rotate(self: *Dial, direction: Direction, distance: i16) void {
        self.counter += switch (direction) {
            .Left => @divTrunc(distance - self.position + 100, 100) - @intFromBool(self.position == 0),
            .Right => @divTrunc(distance + self.position, 100),
        };

        self.position = switch (direction) {
            .Left => @mod(self.position - distance, 100),
            .Right => @mod(self.position + distance, 100),
        };
    }

    const default: Dial = .{
        .position = 50,
        .counter = 0,
    };
};

const Direction = enum {
    Left,
    Right,
};

const Rotation = struct {
    direction: Direction,
    distance: i16,
};

const ParseDirectionError = error{
    InvalidCharacter,
};

const ParseError = ParseDirectionError || std.fmt.ParseIntError;

const RotationIterator = struct {
    const Self = @This();

    rotations: std.mem.TokenIterator(u8, std.mem.DelimiterType.scalar),

    fn next(self: *Self) !?Rotation {
        const value = self.rotations.next() orelse return null;
        const direction: Direction = switch (value[0]) {
            'L' => .Left,
            'R' => .Right,
            else => return ParseError.InvalidCharacter,
        };
        const distance = try std.fmt.parseInt(i16, value[1..], 10);
        return .{
            .direction = direction,
            .distance = distance,
        };
    }

    fn fromSlice(s: []const u8) Self {
        return .{
            .rotations = std.mem.tokenizeScalar(u8, s, '\n'),
        };
    }
};

fn part1(input: []const u8) !i16 {
    var n: i16 = 0;

    var dial: Dial = .default;

    var iter = RotationIterator.fromSlice(input);
    while (try iter.next()) |rotation| {
        dial.rotate(rotation.direction, rotation.distance);
        if (dial.position == 0) {
            n += 1;
        }
    }

    return n;
}

fn part2(input: []const u8) !i32 {
    var dial: Dial = .default;

    var iter = RotationIterator.fromSlice(input);
    while (try iter.next()) |rotation| {
        dial.rotate(rotation.direction, rotation.distance);
    }

    return dial.counter;
}

pub fn main() !void {
    var buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_writer.interface;

    const input = @embedFile("input.txt");

    try stdout.print("part1: {d}\n", .{try part1(input)});
    try stdout.print("part2: {d}\n", .{try part2(input)});
    try stdout.flush();
}

test "Dial rotation" {
    var dial = Dial{ .position = 5, .counter = 0 };
    dial.rotate(.Left, 10);
    try std.testing.expectEqual(95, dial.position);
    dial.rotate(.Right, 5);
    try std.testing.expectEqual(0, dial.position);
}

test "parseLine() left and right" {
    const input =
        \\L68
        \\L30
        \\R48
    ;
    var iter = RotationIterator.fromSlice(input);
    const expected = [_]Rotation{
        .{ .direction = .Left, .distance = 68 },
        .{ .direction = .Left, .distance = 30 },
        .{ .direction = .Right, .distance = 48 },
    };

    for (expected) |exp| {
        const rot = try iter.next();
        try std.testing.expectEqualDeep(exp, rot);
    }
    try std.testing.expectEqual(null, try iter.next());
}

test "part1() example" {
    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;
    const result = try part1(input);
    try std.testing.expectEqual(3, result);
}

test "part2() example" {
    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;
    const result = try part2(input);
    try std.testing.expectEqual(6, result);
}
