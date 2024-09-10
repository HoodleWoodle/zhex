const std = @import("std");
const tty = std.io.tty;
const Endian = std.builtin.Endian;
const StreamSource = std.io.StreamSource;
const zhex = @import("zhex.zig");

fn testIO(comptime options: zhex.Options, comptime input: []const u8, comptime output_expected: []const u8) !void {
    var input_stream = StreamSource{ .const_buffer = std.io.fixedBufferStream(input) };
    var output_data: [output_expected.len]u8 = undefined;
    var output_stream = std.io.fixedBufferStream(&output_data);
    try zhex.run(options, &input_stream, output_stream.writer(), tty.Config.no_color);

    try std.testing.expectEqualStrings(output_expected, &output_data);
}

test "2 byte input" {
    const options = zhex.Options{};
    const input = [_]u8{ 'H', 'i' };
    const output_expected =
        \\┌────────┬─────────────────────────┬─────────────────────────┬────────┬────────┐
        \\│00000000│ 48 69                   │                         │Hi      │        │
        \\└────────┴─────────────────────────┴─────────────────────────┴────────┴────────┘
        \\
    ;

    try testIO(options, &input, output_expected);
}

const input_default = blk: {
    var data: [256]u8 = undefined;
    for (&data, 0..) |*ptr, i| {
        ptr.* = i;
    }
    break :blk data;
};

test "no options" {
    const options = zhex.Options{};
    const output_expected =
        \\┌────────┬─────────────────────────┬─────────────────────────┬────────┬────────┐
        \\│00000000│ 00 01 02 03 04 05 06 07 │ 08 09 0a 0b 0c 0d 0e 0f │••••••••│••••••••│
        \\│00000010│ 10 11 12 13 14 15 16 17 │ 18 19 1a 1b 1c 1d 1e 1f │••••••••│••••••••│
        \\│00000020│ 20 21 22 23 24 25 26 27 │ 28 29 2a 2b 2c 2d 2e 2f │ !"#$%&'│()*+,-./│
        \\│00000030│ 30 31 32 33 34 35 36 37 │ 38 39 3a 3b 3c 3d 3e 3f │01234567│89:;<=>?│
        \\│00000040│ 40 41 42 43 44 45 46 47 │ 48 49 4a 4b 4c 4d 4e 4f │@ABCDEFG│HIJKLMNO│
        \\│00000050│ 50 51 52 53 54 55 56 57 │ 58 59 5a 5b 5c 5d 5e 5f │PQRSTUVW│XYZ[\]^_│
        \\│00000060│ 60 61 62 63 64 65 66 67 │ 68 69 6a 6b 6c 6d 6e 6f │`abcdefg│hijklmno│
        \\│00000070│ 70 71 72 73 74 75 76 77 │ 78 79 7a 7b 7c 7d 7e 7f │pqrstuvw│xyz{|}~•│
        \\│00000080│ 80 81 82 83 84 85 86 87 │ 88 89 8a 8b 8c 8d 8e 8f │••••••••│••••••••│
        \\│00000090│ 90 91 92 93 94 95 96 97 │ 98 99 9a 9b 9c 9d 9e 9f │••••••••│••••••••│
        \\│000000a0│ a0 a1 a2 a3 a4 a5 a6 a7 │ a8 a9 aa ab ac ad ae af │••••••••│••••••••│
        \\│000000b0│ b0 b1 b2 b3 b4 b5 b6 b7 │ b8 b9 ba bb bc bd be bf │••••••••│••••••••│
        \\│000000c0│ c0 c1 c2 c3 c4 c5 c6 c7 │ c8 c9 ca cb cc cd ce cf │••••••••│••••••••│
        \\│000000d0│ d0 d1 d2 d3 d4 d5 d6 d7 │ d8 d9 da db dc dd de df │••••••••│••••••••│
        \\│000000e0│ e0 e1 e2 e3 e4 e5 e6 e7 │ e8 e9 ea eb ec ed ee ef │••••••••│••••••••│
        \\│000000f0│ f0 f1 f2 f3 f4 f5 f6 f7 │ f8 f9 fa fb fc fd fe ff │••••••••│••••••••│
        \\└────────┴─────────────────────────┴─────────────────────────┴────────┴────────┘
        \\
    ;

    try testIO(options, &input_default, output_expected);
}

test "length == 0" {
    const options = zhex.Options{ .length = 0 };
    const output_expected = "";

    try testIO(options, &input_default, output_expected);
}

test "length > input.len" {
    const options = zhex.Options{ .length = 512 };
    const output_expected =
        \\┌────────┬─────────────────────────┬─────────────────────────┬────────┬────────┐
        \\│00000000│ 00 01 02 03 04 05 06 07 │ 08 09 0a 0b 0c 0d 0e 0f │••••••••│••••••••│
        \\│00000010│ 10 11 12 13 14 15 16 17 │ 18 19 1a 1b 1c 1d 1e 1f │••••••••│••••••••│
        \\│00000020│ 20 21 22 23 24 25 26 27 │ 28 29 2a 2b 2c 2d 2e 2f │ !"#$%&'│()*+,-./│
        \\│00000030│ 30 31 32 33 34 35 36 37 │ 38 39 3a 3b 3c 3d 3e 3f │01234567│89:;<=>?│
        \\│00000040│ 40 41 42 43 44 45 46 47 │ 48 49 4a 4b 4c 4d 4e 4f │@ABCDEFG│HIJKLMNO│
        \\│00000050│ 50 51 52 53 54 55 56 57 │ 58 59 5a 5b 5c 5d 5e 5f │PQRSTUVW│XYZ[\]^_│
        \\│00000060│ 60 61 62 63 64 65 66 67 │ 68 69 6a 6b 6c 6d 6e 6f │`abcdefg│hijklmno│
        \\│00000070│ 70 71 72 73 74 75 76 77 │ 78 79 7a 7b 7c 7d 7e 7f │pqrstuvw│xyz{|}~•│
        \\│00000080│ 80 81 82 83 84 85 86 87 │ 88 89 8a 8b 8c 8d 8e 8f │••••••••│••••••••│
        \\│00000090│ 90 91 92 93 94 95 96 97 │ 98 99 9a 9b 9c 9d 9e 9f │••••••••│••••••••│
        \\│000000a0│ a0 a1 a2 a3 a4 a5 a6 a7 │ a8 a9 aa ab ac ad ae af │••••••••│••••••••│
        \\│000000b0│ b0 b1 b2 b3 b4 b5 b6 b7 │ b8 b9 ba bb bc bd be bf │••••••••│••••••••│
        \\│000000c0│ c0 c1 c2 c3 c4 c5 c6 c7 │ c8 c9 ca cb cc cd ce cf │••••••••│••••••••│
        \\│000000d0│ d0 d1 d2 d3 d4 d5 d6 d7 │ d8 d9 da db dc dd de df │••••••••│••••••••│
        \\│000000e0│ e0 e1 e2 e3 e4 e5 e6 e7 │ e8 e9 ea eb ec ed ee ef │••••••••│••••••••│
        \\│000000f0│ f0 f1 f2 f3 f4 f5 f6 f7 │ f8 f9 fa fb fc fd fe ff │••••••••│••••••••│
        \\└────────┴─────────────────────────┴─────────────────────────┴────────┴────────┘
        \\
    ;

    try testIO(options, &input_default, output_expected);
}

test "offset > input.len" {
    const options = zhex.Options{ .offset = 512 };
    const output_expected = "";

    try testIO(options, &input_default, output_expected);
}

test "offset < -input.len" {
    const options = zhex.Options{ .offset = -512 };
    const output_expected =
        \\┌────────┬─────────────────────────┬─────────────────────────┬────────┬────────┐
        \\│00000000│ 00 01 02 03 04 05 06 07 │ 08 09 0a 0b 0c 0d 0e 0f │••••••••│••••••••│
        \\│00000010│ 10 11 12 13 14 15 16 17 │ 18 19 1a 1b 1c 1d 1e 1f │••••••••│••••••••│
        \\│00000020│ 20 21 22 23 24 25 26 27 │ 28 29 2a 2b 2c 2d 2e 2f │ !"#$%&'│()*+,-./│
        \\│00000030│ 30 31 32 33 34 35 36 37 │ 38 39 3a 3b 3c 3d 3e 3f │01234567│89:;<=>?│
        \\│00000040│ 40 41 42 43 44 45 46 47 │ 48 49 4a 4b 4c 4d 4e 4f │@ABCDEFG│HIJKLMNO│
        \\│00000050│ 50 51 52 53 54 55 56 57 │ 58 59 5a 5b 5c 5d 5e 5f │PQRSTUVW│XYZ[\]^_│
        \\│00000060│ 60 61 62 63 64 65 66 67 │ 68 69 6a 6b 6c 6d 6e 6f │`abcdefg│hijklmno│
        \\│00000070│ 70 71 72 73 74 75 76 77 │ 78 79 7a 7b 7c 7d 7e 7f │pqrstuvw│xyz{|}~•│
        \\│00000080│ 80 81 82 83 84 85 86 87 │ 88 89 8a 8b 8c 8d 8e 8f │••••••••│••••••••│
        \\│00000090│ 90 91 92 93 94 95 96 97 │ 98 99 9a 9b 9c 9d 9e 9f │••••••••│••••••••│
        \\│000000a0│ a0 a1 a2 a3 a4 a5 a6 a7 │ a8 a9 aa ab ac ad ae af │••••••••│••••••••│
        \\│000000b0│ b0 b1 b2 b3 b4 b5 b6 b7 │ b8 b9 ba bb bc bd be bf │••••••••│••••••••│
        \\│000000c0│ c0 c1 c2 c3 c4 c5 c6 c7 │ c8 c9 ca cb cc cd ce cf │••••••••│••••••••│
        \\│000000d0│ d0 d1 d2 d3 d4 d5 d6 d7 │ d8 d9 da db dc dd de df │••••••••│••••••••│
        \\│000000e0│ e0 e1 e2 e3 e4 e5 e6 e7 │ e8 e9 ea eb ec ed ee ef │••••••••│••••••••│
        \\│000000f0│ f0 f1 f2 f3 f4 f5 f6 f7 │ f8 f9 fa fb fc fd fe ff │••••••••│••••••••│
        \\└────────┴─────────────────────────┴─────────────────────────┴────────┴────────┘
        \\
    ;

    try testIO(options, &input_default, output_expected);
}

test "offset == 216" {
    const options = zhex.Options{ .offset = 216 };
    const output_expected =
        \\┌────────┬─────────────────────────┬─────────────────────────┬────────┬────────┐
        \\│000000d8│ d8 d9 da db dc dd de df │ e0 e1 e2 e3 e4 e5 e6 e7 │••••••••│••••••••│
        \\│000000e8│ e8 e9 ea eb ec ed ee ef │ f0 f1 f2 f3 f4 f5 f6 f7 │••••••••│••••••••│
        \\│000000f8│ f8 f9 fa fb fc fd fe ff │                         │••••••••│        │
        \\└────────┴─────────────────────────┴─────────────────────────┴────────┴────────┘
        \\
    ;

    try testIO(options, &input_default, output_expected);
}

test "offset == -24" {
    const options = zhex.Options{ .offset = -24 };
    const output_expected =
        \\┌────────┬─────────────────────────┬─────────────────────────┬────────┬────────┐
        \\│000000e8│ e8 e9 ea eb ec ed ee ef │ f0 f1 f2 f3 f4 f5 f6 f7 │••••••••│••••••••│
        \\│000000f8│ f8 f9 fa fb fc fd fe ff │                         │••••••••│        │
        \\└────────┴─────────────────────────┴─────────────────────────┴────────┴────────┘
        \\
    ;

    try testIO(options, &input_default, output_expected);
}

test "BlockSize.bs_4 [length = 64]" {
    const options = zhex.Options{
        .block_size = zhex.BlockSize.bs_4,
        // --------------------------------
        .length = 64,
    };
    const output_expected =
        \\┌────────┬─────────────┬─────────────┬────┬────┐
        \\│00000000│ 00 01 02 03 │ 04 05 06 07 │••••│••••│
        \\│00000008│ 08 09 0a 0b │ 0c 0d 0e 0f │••••│••••│
        \\│00000010│ 10 11 12 13 │ 14 15 16 17 │••••│••••│
        \\│00000018│ 18 19 1a 1b │ 1c 1d 1e 1f │••••│••••│
        \\│00000020│ 20 21 22 23 │ 24 25 26 27 │ !"#│$%&'│
        \\│00000028│ 28 29 2a 2b │ 2c 2d 2e 2f │()*+│,-./│
        \\│00000030│ 30 31 32 33 │ 34 35 36 37 │0123│4567│
        \\│00000038│ 38 39 3a 3b │ 3c 3d 3e 3f │89:;│<=>?│
        \\└────────┴─────────────┴─────────────┴────┴────┘
        \\
    ;

    try testIO(options, &input_default, output_expected);
}

test "BlockSize.bs_32 [length = 64]" {
    const options = zhex.Options{
        .block_size = zhex.BlockSize.bs_32,
        // --------------------------------
        .length = 64,
    };
    const output_expected =
        \\┌────────┬─────────────────────────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────┬────────────────────────────────┬────────────────────────────────┐
        \\│00000000│ 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f │ 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f 30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f │••••••••••••••••••••••••••••••••│ !"#$%&'()*+,-./0123456789:;<=>?│
        \\└────────┴─────────────────────────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────┴────────────────────────────────┴────────────────────────────────┘
        \\
    ;

    try testIO(options, &input_default, output_expected);
}

test "blocks_per_line == 1 [length = 64]" {
    const options = zhex.Options{ .blocks_per_line = 1, .length = 64 };
    const output_expected =
        \\┌────────┬─────────────────────────┬────────┐
        \\│00000000│ 00 01 02 03 04 05 06 07 │••••••••│
        \\│00000008│ 08 09 0a 0b 0c 0d 0e 0f │••••••••│
        \\│00000010│ 10 11 12 13 14 15 16 17 │••••••••│
        \\│00000018│ 18 19 1a 1b 1c 1d 1e 1f │••••••••│
        \\│00000020│ 20 21 22 23 24 25 26 27 │ !"#$%&'│
        \\│00000028│ 28 29 2a 2b 2c 2d 2e 2f │()*+,-./│
        \\│00000030│ 30 31 32 33 34 35 36 37 │01234567│
        \\│00000038│ 38 39 3a 3b 3c 3d 3e 3f │89:;<=>?│
        \\└────────┴─────────────────────────┴────────┘
        \\
    ;

    try testIO(options, &input_default, output_expected);
}

test "ValueSize.vs_8 [length = 64, BlockSize.bs_1]" {
    const options = zhex.Options{
        .value_size = zhex.ValueSize.vs_8,
        // --------------------------------
        .length = 64,
        .block_size = zhex.BlockSize.bs_1,
    };
    const output_expected =
        \\┌────────┬──────────────────┬──────────────────┬────────┬────────┐
        \\│00000000│ 0001020304050607 │ 08090a0b0c0d0e0f │••••••••│••••••••│
        \\│00000010│ 1011121314151617 │ 18191a1b1c1d1e1f │••••••••│••••••••│
        \\│00000020│ 2021222324252627 │ 28292a2b2c2d2e2f │ !"#$%&'│()*+,-./│
        \\│00000030│ 3031323334353637 │ 38393a3b3c3d3e3f │01234567│89:;<=>?│
        \\└────────┴──────────────────┴──────────────────┴────────┴────────┘
        \\
    ;

    try testIO(options, &input_default, output_expected);
}

test "ValueSize.vs_4, Endian.little [length = 64, BlockSize.bs_2]" {
    const options = zhex.Options{
        .value_size = zhex.ValueSize.vs_4,
        .endianess = Endian.little,
        // --------------------------------
        .length = 64,
        .block_size = zhex.BlockSize.bs_2,
    };
    const output_expected =
        \\┌────────┬───────────────────┬───────────────────┬────────┬────────┐
        \\│00000000│ 03020100 07060504 │ 0b0a0908 0f0e0d0c │••••••••│••••••••│
        \\│00000010│ 13121110 17161514 │ 1b1a1918 1f1e1d1c │••••••••│••••••••│
        \\│00000020│ 23222120 27262524 │ 2b2a2928 2f2e2d2c │ !"#$%&'│()*+,-./│
        \\│00000030│ 33323130 37363534 │ 3b3a3938 3f3e3d3c │01234567│89:;<=>?│
        \\└────────┴───────────────────┴───────────────────┴────────┴────────┘
        \\
    ;

    try testIO(options, &input_default, output_expected);
}

test "ValueSize.vs_8, no_borders [length = 64, BlockSize.bs_2, Endian.little]" {
    const options = zhex.Options{
        .value_size = zhex.ValueSize.vs_4,
        .no_borders = true,
        // --------------------------------
        .length = 64,
        .block_size = zhex.BlockSize.bs_2,
        .endianess = Endian.little,
    };
    const output_expected =
        \\00000000  03020100 07060504   0b0a0908 0f0e0d0c  •••••••• ••••••••
        \\00000010  13121110 17161514   1b1a1918 1f1e1d1c  •••••••• ••••••••
        \\00000020  23222120 27262524   2b2a2928 2f2e2d2c   !"#$%&' ()*+,-./
        \\00000030  33323130 37363534   3b3a3938 3f3e3d3c  01234567 89:;<=>?
        \\
    ;

    try testIO(options, &input_default, output_expected);
}

test "no_borders [length = 64]" {
    const options = zhex.Options{
        .no_borders = true,
        // --------------------------------
        .length = 64,
    };
    const output_expected =
        \\00000000  00 01 02 03 04 05 06 07   08 09 0a 0b 0c 0d 0e 0f  •••••••• ••••••••
        \\00000010  10 11 12 13 14 15 16 17   18 19 1a 1b 1c 1d 1e 1f  •••••••• ••••••••
        \\00000020  20 21 22 23 24 25 26 27   28 29 2a 2b 2c 2d 2e 2f   !"#$%&' ()*+,-./
        \\00000030  30 31 32 33 34 35 36 37   38 39 3a 3b 3c 3d 3e 3f  01234567 89:;<=>?
        \\
    ;

    try testIO(options, &input_default, output_expected);
}

test "no_borders, no_position, no_characters [length = 64]" {
    const options = zhex.Options{
        .no_borders = true,
        .no_position = true,
        .no_characters = true,
        // --------------------------------
        .length = 64,
    };
    const output_expected =
        \\00 01 02 03 04 05 06 07   08 09 0a 0b 0c 0d 0e 0f
        \\10 11 12 13 14 15 16 17   18 19 1a 1b 1c 1d 1e 1f
        \\20 21 22 23 24 25 26 27   28 29 2a 2b 2c 2d 2e 2f
        \\30 31 32 33 34 35 36 37   38 39 3a 3b 3c 3d 3e 3f
        \\
    ;

    try testIO(options, &input_default, output_expected);
}

test "BlockSize.bs_2, blocks_per_line == 4, ValueSize.vs_2" {
    const options = zhex.Options{
        .block_size = zhex.BlockSize.bs_2,
        .blocks_per_line = 4,
        .value_size = zhex.ValueSize.vs_2,
    };
    const output_expected =
        \\┌────────┬───────────┬───────────┬───────────┬───────────┬────┬────┬────┬────┐
        \\│00000000│ 0001 0203 │ 0405 0607 │ 0809 0a0b │ 0c0d 0e0f │••••│••••│••••│••••│
        \\│00000010│ 1011 1213 │ 1415 1617 │ 1819 1a1b │ 1c1d 1e1f │••••│••••│••••│••••│
        \\│00000020│ 2021 2223 │ 2425 2627 │ 2829 2a2b │ 2c2d 2e2f │ !"#│$%&'│()*+│,-./│
        \\│00000030│ 3031 3233 │ 3435 3637 │ 3839 3a3b │ 3c3d 3e3f │0123│4567│89:;│<=>?│
        \\│00000040│ 4041 4243 │ 4445 4647 │ 4849 4a4b │ 4c4d 4e4f │@ABC│DEFG│HIJK│LMNO│
        \\│00000050│ 5051 5253 │ 5455 5657 │ 5859 5a5b │ 5c5d 5e5f │PQRS│TUVW│XYZ[│\]^_│
        \\│00000060│ 6061 6263 │ 6465 6667 │ 6869 6a6b │ 6c6d 6e6f │`abc│defg│hijk│lmno│
        \\│00000070│ 7071 7273 │ 7475 7677 │ 7879 7a7b │ 7c7d 7e7f │pqrs│tuvw│xyz{│|}~•│
        \\│00000080│ 8081 8283 │ 8485 8687 │ 8889 8a8b │ 8c8d 8e8f │••••│••••│••••│••••│
        \\│00000090│ 9091 9293 │ 9495 9697 │ 9899 9a9b │ 9c9d 9e9f │••••│••••│••••│••••│
        \\│000000a0│ a0a1 a2a3 │ a4a5 a6a7 │ a8a9 aaab │ acad aeaf │••••│••••│••••│••••│
        \\│000000b0│ b0b1 b2b3 │ b4b5 b6b7 │ b8b9 babb │ bcbd bebf │••••│••••│••••│••••│
        \\│000000c0│ c0c1 c2c3 │ c4c5 c6c7 │ c8c9 cacb │ cccd cecf │••••│••••│••••│••••│
        \\│000000d0│ d0d1 d2d3 │ d4d5 d6d7 │ d8d9 dadb │ dcdd dedf │••••│••••│••••│••••│
        \\│000000e0│ e0e1 e2e3 │ e4e5 e6e7 │ e8e9 eaeb │ eced eeef │••••│••••│••••│••••│
        \\│000000f0│ f0f1 f2f3 │ f4f5 f6f7 │ f8f9 fafb │ fcfd feff │••••│••••│••••│••••│
        \\└────────┴───────────┴───────────┴───────────┴───────────┴────┴────┴────┴────┘
        \\
    ;

    try testIO(options, &input_default, output_expected);
}

test "incomplete value" {
    const options = zhex.Options{
        .length = 7,
        .offset = 33,
        .block_size = zhex.BlockSize.bs_2,
        .blocks_per_line = 1,
        .value_size = zhex.ValueSize.vs_4,
    };
    const output_expected =
        \\┌────────┬───────────────────┬────────┐
        \\│00000021│ 21222324 252627?? │!"#$%&' │
        \\└────────┴───────────────────┴────────┘
        \\
    ;

    try testIO(options, &input_default, output_expected);
}
