const std = @import("std");
const tty = std.io.tty;
const Endian = std.builtin.Endian;
const StreamSource = std.io.StreamSource;

const BYTES_PER_LINE_MAX = std.math.maxInt(u5) * @intFromEnum(BlockSize.bs_32) * @intFromEnum(ValueSize.vs_8); // Options.blocks_per_line => u5

pub const ValueSize = enum(u64) { vs_1 = 1, vs_2 = 2, vs_4 = 4, vs_8 = 8 };
pub const BlockSize = enum(u64) { bs_1 = 1, bs_2 = 2, bs_4 = 4, bs_8 = 8, bs_16 = 16, bs_32 = 32 };
pub const Options = struct {
    length: u64 = std.math.maxInt(u64),
    offset: i64 = 0,
    block_size: BlockSize = BlockSize.bs_8,
    blocks_per_line: u5 = 2,
    value_size: ValueSize = ValueSize.vs_1,
    endianess: Endian = Endian.big, // same as Intel 4004
    no_borders: bool = false,
    no_position: bool = false,
    no_characters: bool = false,
    no_color: bool = false,
};

fn writeBorder(options: Options, writer: anytype, top: bool) !void {
    if (options.no_borders) {
        return;
    }

    const values_in_block = @intFromEnum(options.block_size);
    const bytes_in_value = @intFromEnum(options.value_size);
    const bytes_in_block = bytes_in_value * values_in_block;

    _ = try writer.write(if (top) "┌" else "└");
    if (!options.no_position) {
        _ = try writer.write("────────");
        _ = try writer.write(if (top) "┬" else "┴");
    }

    {
        var block: u64 = 0;
        while (block < options.blocks_per_line) : (block += 1) {
            if (block != 0) {
                _ = try writer.write(if (top) "┬" else "┴");
            }

            if (!options.no_position or !options.no_borders) {
                _ = try writer.write("─");
            }

            var i: u64 = 0;
            while (i < values_in_block) : (i += 1) {
                if (i != 0) {
                    _ = try writer.write("─");
                }
                _ = switch (options.value_size) {
                    .vs_1 => try writer.write("──" ** 1),
                    .vs_2 => try writer.write("──" ** 2),
                    .vs_4 => try writer.write("──" ** 4),
                    .vs_8 => try writer.write("──" ** 8),
                };
            }

            _ = try writer.write("─");
        }
    }

    if (!options.no_characters) {
        var block: u64 = 0;
        while (block < options.blocks_per_line) : (block += 1) {
            _ = try writer.write(if (top) "┬" else "┴");

            var i: u64 = 0;
            while (i < bytes_in_block) : (i += 1) {
                _ = try writer.write("─");
            }
        }
    }

    _ = try writer.write(if (top) "┐" else "┘");
    _ = try writer.write("\n");
}

fn writeBorderSep(options: Options, writer: anytype, is_first_or_last_in_line: bool) !void {
    if (!options.no_borders) {
        _ = try writer.write("│");
    } else if (!is_first_or_last_in_line) {
        _ = try writer.write(" ");
    }
}

fn writePosition(options: Options, writer: anytype, position: u64) !void {
    _ = options;
    try std.fmt.format(writer, "{x:0>8}", .{position});
}

fn writeValues(options: Options, writer: anytype, tty_config: tty.Config, buffer: []const u8, is_first_in_line: bool, is_last_in_line: bool) !void {
    const values_in_block = @intFromEnum(options.block_size);
    const bytes_in_value = @intFromEnum(options.value_size);

    var stream = std.io.fixedBufferStream(buffer);
    const reader = stream.reader();

    if (!(is_first_in_line and options.no_borders)) {
        _ = try writer.write(" ");
    }

    var i: u64 = 0;
    while (i < values_in_block) : (i += 1) {
        if (i != 0) {
            _ = try writer.write(" ");
        }
        if (i * bytes_in_value < buffer.len) {
            try switch (options.value_size) {
                .vs_1 => writeValue(options, reader, writer, tty_config, u8),
                .vs_2 => writeValue(options, reader, writer, tty_config, u16),
                .vs_4 => writeValue(options, reader, writer, tty_config, u32),
                .vs_8 => writeValue(options, reader, writer, tty_config, u64),
            };
        } else {
            _ = try switch (options.value_size) {
                .vs_1 => writer.write("  " ** 1),
                .vs_2 => writer.write("  " ** 2),
                .vs_4 => writer.write("  " ** 4),
                .vs_8 => writer.write("  " ** 8),
            };
        }
    }

    if (!(is_last_in_line and options.no_borders and options.no_characters)) {
        _ = try writer.write(" ");
    }
}

fn writeCharacters(options: Options, writer: anytype, tty_config: tty.Config, buffer: []const u8) !void {
    const values_in_block = @intFromEnum(options.block_size);
    const bytes_in_value = @intFromEnum(options.value_size);
    const bytes_in_block = bytes_in_value * values_in_block;

    var i: u64 = 0;
    while (i < bytes_in_block) : (i += 1) {
        if (i < buffer.len) {
            if (buffer[i] >= ' ' and buffer[i] <= '~') {
                _ = try writer.writeByte(buffer[i]);
            } else {
                try writeCharacterDim(options, writer, tty_config, "•"); // ×
            }
        } else {
            _ = try writer.write(" ");
        }
    }
}

fn writeCharacterDim(options: Options, writer: anytype, tty_config: tty.Config, bytes: []const u8) !void {
    if (!options.no_color) {
        try tty.Config.setColor(tty_config, writer, tty.Color.dim);
    }
    _ = try writer.write(bytes);
    if (!options.no_color) {
        try tty.Config.setColor(tty_config, writer, tty.Color.reset);
    }
}

fn writeValue(options: Options, reader: anytype, writer: anytype, tty_config: tty.Config, comptime T: type) !void {
    const buffer_max = @sizeOf(T);
    var buffer: [buffer_max]u8 = [_]u8{0x00} ** buffer_max;
    const bytes_read = try reader.readAtLeast(&buffer, buffer_max);
    var value: T = buffer[0];
    // read a value that may or may not be incomplete
    if (T != u8) {
        var i: u64 = 1;
        while (i < bytes_read) : (i += 1) {
            if (options.endianess == Endian.big) {
                value = (value << 8) | buffer[i];
            } else {
                const shift = std.math.lossyCast(std.math.Log2Int(T), i * 8);
                value = (@as(T, buffer[i]) << shift) | value;
            }
        }
    }

    if (!options.no_color and value == 0) {
        try tty.Config.setColor(tty_config, writer, tty.Color.dim);
    }

    if (options.endianess == Endian.big) {
        try formatValue(writer, bytes_read, value);
    }

    const bytes_in_value = @intFromEnum(options.value_size);

    var i: u64 = 0;
    while (i < (bytes_in_value - bytes_read)) : (i += 1) {
        _ = try writer.write("??");
    }

    if (options.endianess == Endian.little) {
        try formatValue(writer, bytes_read, value);
    }

    if (!options.no_color and value == 0) {
        try tty.Config.setColor(tty_config, writer, tty.Color.reset);
    }
}

// there is no runtime formatting yet (as far as I know at least)
fn formatValue(writer: anytype, bytes_read: usize, value: anytype) !void {
    try switch (bytes_read) {
        1 => std.fmt.format(writer, "{x:0>2}", .{value}),
        2 => std.fmt.format(writer, "{x:0>4}", .{value}),
        3 => std.fmt.format(writer, "{x:0>6}", .{value}),
        4 => std.fmt.format(writer, "{x:0>8}", .{value}),
        5 => std.fmt.format(writer, "{x:0>10}", .{value}),
        6 => std.fmt.format(writer, "{x:0>12}", .{value}),
        7 => std.fmt.format(writer, "{x:0>14}", .{value}),
        8 => std.fmt.format(writer, "{x:0>16}", .{value}),
        else => unreachable,
    };
}

fn getSubBuffer(options: Options, buffer: *[BYTES_PER_LINE_MAX]u8, bytes_in_buffer: usize, block_idx: u64) []u8 {
    const values_in_block = @intFromEnum(options.block_size);
    const bytes_in_value = @intFromEnum(options.value_size);
    const bytes_in_block = bytes_in_value * values_in_block;
    const from = block_idx * bytes_in_block;
    const to = from + values_in_block * bytes_in_block;

    if (from > bytes_in_buffer) {
        return buffer[0..0];
    }

    if (to > bytes_in_buffer) {
        return buffer[from..bytes_in_buffer];
    }

    return buffer[from..to];
}

// options.offset already applied to reader
// return number of bytes written (not yet supported with std.fmt.format)
fn write(options: Options, reader: anytype, writer: anytype, tty_config: tty.Config, offset: u64) !void {
    if (options.length == 0) {
        return;
    }

    const values_in_block = @intFromEnum(options.block_size);
    const values_in_line = values_in_block * options.blocks_per_line;
    const bytes_in_value = @intFromEnum(options.value_size);
    const bytes_in_line = bytes_in_value * values_in_line;

    var buffer: [BYTES_PER_LINE_MAX]u8 = undefined;
    var sub_buffer: []const u8 = undefined;

    var byte_counter: u64 = 0;
    var bytes_in_buffer: u64 = 0;

    try writeBorder(options, writer, true);

    while (byte_counter < options.length) : (byte_counter += bytes_in_buffer) {
        const bytes_left = options.length - byte_counter;
        const length = if (bytes_left < bytes_in_line) bytes_left else bytes_in_line;
        bytes_in_buffer = try reader.readAll(buffer[0..length]);

        try writeBorderSep(options, writer, true);
        if (!options.no_position) {
            try writePosition(options, writer, offset + byte_counter);
            try writeBorderSep(options, writer, false);
        }
        sub_buffer = getSubBuffer(options, &buffer, bytes_in_buffer, 0);
        try writeValues(options, writer, tty_config, sub_buffer, options.no_position, false);
        {
            var i: u64 = 1;
            while (i < options.blocks_per_line) : (i += 1) {
                try writeBorderSep(options, writer, false);
                sub_buffer = getSubBuffer(options, &buffer, bytes_in_buffer, i);
                const is_last_in_line = i == options.blocks_per_line - 1;
                try writeValues(options, writer, tty_config, sub_buffer, false, is_last_in_line);
            }
        }
        if (!options.no_characters) {
            try writeBorderSep(options, writer, false);
            sub_buffer = getSubBuffer(options, &buffer, bytes_in_buffer, 0);
            try writeCharacters(options, writer, tty_config, sub_buffer);
            {
                var i: u64 = 1;
                while (i < options.blocks_per_line) : (i += 1) {
                    try writeBorderSep(options, writer, false);
                    sub_buffer = getSubBuffer(options, &buffer, bytes_in_buffer, i);
                    try writeCharacters(options, writer, tty_config, sub_buffer);
                }
            }
        }
        try writeBorderSep(options, writer, true);
        _ = try writer.write("\n");
    }

    try writeBorder(options, writer, false);
}

pub fn run(options: Options, input: *StreamSource, writer: anytype, tty_config: tty.Config) !void {
    const input_size = try input.getEndPos();
    if (input_size == 0) {
        return;
    }

    var offset = if (options.offset < 0) blk: {
        const offset_from_end = @abs(options.offset);
        if (offset_from_end < input_size)
            break :blk input_size - offset_from_end;
        break :blk 0;
    } else @as(u64, @bitCast(options.offset));

    var options_modified = options;
    if (offset >= input_size) {
        offset = input_size;
        options_modified.length = 0;
    } else if (input_size - offset < options.length) {
        options_modified.length = input_size - offset;
    }

    try input.seekTo(offset);

    var buffered_reader = std.io.bufferedReader(input.reader());
    var buffered_writer = std.io.bufferedWriter(writer);
    try write(options_modified, buffered_reader.reader(), buffered_writer.writer(), tty_config, offset);
    try buffered_writer.flush();
}
