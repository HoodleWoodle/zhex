const std = @import("std");
const tty = std.io.tty;
const Tuple = std.meta.Tuple;
const StreamSource = std.io.StreamSource;
const zhex = @import("zhex.zig");

fn parseArgs() Tuple(&.{ zhex.Options, []const u8 }) {
    var args = std.process.args();

    const options = zhex.Options{ .length = 256 };
    // TODO: IMPL: cli options

    const path = args.next() orelse unreachable;
    // TODO: IMPL: cli arguments

    return .{ options, path };
}

pub fn main() void {
    const stderr = std.io.getStdErr().writer();

    const args = parseArgs();
    const options = args[0];
    const path = args[1];

    var path_abs_buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const path_abs = std.fs.realpath(path, &path_abs_buffer) catch {
        std.fmt.format(stderr, "Invalid file path: '{s}'", .{path}) catch unreachable;
        std.process.exit(1);
    };
    var file = std.fs.openFileAbsolute(path_abs, .{}) catch {
        std.fmt.format(stderr, "Could not open file: '{s}'", .{path}) catch unreachable;
        std.process.exit(1);
    };
    defer file.close();

    var input = StreamSource{ .file = file };
    const stdout = std.io.getStdOut();
    const tty_config = tty.detectConfig(stdout);
    const writer = stdout.writer();
    zhex.run(options, &input, writer, tty_config) catch {
        std.fmt.format(stderr, "Could not run zhex with given options for file: '{s}'", .{path}) catch unreachable;
        std.process.exit(1);
    };
}
