const std = @import("std");
const fmt = std.fmt;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    //try stdout.print("Hello, {s}!\n", .{"world"});

    const msg = [_]i32{ 1, 2, 3 };

    try stdout.print("{}\n", .{msg[0..2].len});
}
