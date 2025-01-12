const std = @import("std");
const fmt = std.fmt;
const expect = std.testing.expect;
const fs = std.fs;

const WalkInfo = struct {
    count: u64 = 0,
    size: u64 = 0,
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const allocator = std.heap.page_allocator;

    var dir = try fs.openDirAbsolute("c:/Work/de4", .{ .iterate = true });
    defer dir.close();

    var result: WalkInfo = .{};
    try walk(allocator, &result, dir);

    try stdout.print("{} {}\n", .{ result.count, result.size / 1024 / 1024 });
}

fn walk(alloc: std.mem.Allocator, result: *WalkInfo, dir: fs.Dir) !void {
    //const stdout = std.io.getStdOut().writer();
    var iter = dir.iterate();
    while (try iter.next()) |file| {
        //try stdout.print("{s}\n", .{file.name});
        result.count += 1;
        if (file.kind == .directory) {
            var subDir = try dir.openDir(file.name, .{ .iterate = true });
            defer subDir.close();
            try walk(alloc, result, subDir);
        } else {
            const stat = try dir.statFile(file.name);
            result.size += stat.size;
        }
    }
}
