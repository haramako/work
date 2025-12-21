const builtin = @import("builtin");
const std = @import("std");
const fmt = std.fmt;
const expect = std.testing.expect;
const fs = std.fs;

const WalkInfo = struct {
    count: u64 = 0,
    size: u64 = 0,
};

const Io = @This();
pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var dir = try fs.openDirAbsolute("c:/Work/de4/de4", .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var result: WalkInfo = .{};
    while (try walker.next()) |entry| {
        result.count += 1;
        //std.debug.print("{s}\n", .{entry.path});
        if (entry.kind != .directory) {
            const stat = try dir.statFile(entry.path);
            result.size += stat.size;
        }
    }

    std.debug.print("{} {}\n", .{ result.count, result.size / (1024 * 1024) });
}
