const std = @import("std");
const zig_editor = @import("zig_editor");
const mibu = @import("mibu");
const color = mibu.color;

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    std.debug.print("{s}Hello World in purple!\n", .{color.print.bgRGB(97, 37, 160)});
    std.debug.print("{s}", .{color.print.reset});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var threaded: std.Io.Threaded = .init(allocator);

    const io = threaded.io();
    defer threaded.deinit();

    // var stdin_buffer: [1024]u8 = undefined;
    // var stdin_reader = std.fs.File.stdin().reader(io, &stdin_buffer);
    // const stdin = &stdin_reader.interface;

    const stdin = std.fs.File.stdin();
    var raw_term = try mibu.term.enableRawMode(stdin.handle);
    defer raw_term.disableRawMode() catch {};

    while (true) {
        // const next = try events.nextWithTimeout(stdin, 1000);
        const next = try mibu.events.next(io, stdin);
        switch (next) {
            .key => |k| {
                std.debug.print("{s}\n", .{k});
            },
            else => break,
        }
    }
    try zig_editor.bufferedPrint();
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
