const std = @import("std");
const rl = @import("raylib");

pub fn kbButton(button: i32) InputWrapper.ButtonType {
    return .{ .keyboard = button };
}

pub fn kbAxis(pos: i32, neg: i32) InputWrapper.AxisType {
    return .{ .keyboard = .{
        .positive = pos,
        .negative = neg,
    } };
}

pub fn gpButton(gamepad_num: i32, button: i32) InputWrapper.ButtonType {
    return .{ .gamepad = .{
        .gamepad_num = gamepad_num,
        .button = button,
    } };
}

pub fn gpAxis(gamepad_num: i32, axis: i32) InputWrapper.AxisType {
    return .{ .gamepad = .{
        .gamepad_name = gamepad_num,
        .axis = axis,
    } };
}

pub fn msButton(button: i32) InputWrapper.ButtonType {
    return .{ .mouse = button };
}

pub const InputWrapper = struct {
    pub const ButtonType = union(enum) {
        keyboard: i32,
        mouse: i32,
        gamepad: struct {
            gamepad_num: i32 = 0,
            button: i32,
        },

        fn fromString(str: []const u8, value0: i32, value1: i32) !ButtonType {
            if (str[0] == 'k') {
                return .{ .keyboard = value0 };
            } else if (str[0] == 'm') {
                return .{ .mouse = value0 };
            } else if (str[0] == 'g') {
                return .{ .gamepad = .{
                    .gamepad_num = value0,
                    .button = value1,
                } };
            }
            return error.CouldNotConvertFromString;
        }
    };

    pub const AxisType = union(enum) {
        keyboard: struct {
            positive: i32,
            negative: i32,
        },
        mouse_x,
        mouse_y,
        gamepad: struct {
            gamepad_num: i32 = 0,
            axis: i32,
        },

        fn fromString(str: []const u8, value0: i32, value1: i32) !AxisType {
            if (str[0] == 'k') {
                return .{ .keyboard = .{
                    .positive = value0,
                    .negative = value1,
                } };
            } else if (str[0] == 'g') {
                return .{ .gamepad = .{
                    .gamepad_num = value0,
                    .axis = value1,
                } };
            } else {
                if (str[str.len - 1] == 'x') {
                    return .mouse_x;
                } else if (str[str.len - 1] == 'y') {
                    return .mouse_y;
                }
            }
            return error.CouldNotConvertFromString;
        }
    };

    pub fn isButtonPressed(button: ButtonType) bool {
        return switch (button) {
            .keyboard => |kb| rl.IsKeyPressed(kb),
            .mouse => |ms| rl.IsMouseButtonPressed(ms),
            .gamepad => |gp| rl.IsGamepadButtonPressed(gp.gamepad_num, gp.button),
        };
    }

    pub fn isButtonDown(button: ButtonType) bool {
        return switch (button) {
            .keyboard => |kb| rl.IsKeyDown(kb),
            .mouse => |ms| rl.IsMouseButtonDown(ms),
            .gamepad => |gp| rl.IsGamepadButtonDown(gp.gamepad_num, gp.button),
        };
    }

    pub fn isButtonReleased(button: ButtonType) bool {
        return switch (button) {
            .keyboard => |kb| rl.IsKeyReleased(kb),
            .mouse => |ms| rl.IsMouseButtonReleased(ms),
            .gamepad => |gp| rl.IsGamepadButtonReleased(gp.gamepad_num, gp.button),
        };
    }

    pub fn getAxis(axis: AxisType) f32 {
        return switch (axis) {
            .keyboard => |kb| blk: {
                var val: f32 = 0.0;
                if (rl.IsKeyDown(kb.positive)) val += 1.0;
                if (rl.IsKeyDown(kb.negative)) val -= 1.0;
                break :blk val;
            },
            .mouse_x => rl.GetMouseDelta().x,
            .mouse_y => rl.GetMouseDelta().y,
            .gamepad => |gp| rl.GetGamepadAxisMovement(gp.gamepad_num, gp.axis),
        };
    }

    pub fn exportButtonBinding(writer: anytype, button: ButtonType) !void {
        const button_fmt: struct { i32, i32 } = switch (button) {
            .keyboard => |kb| .{ kb, 0 },
            .mouse => |ms| .{ ms, 0 },
            .gamepad => |gp| .{ gp.gamepad_num, gp.button },
        };
        try writer.print("{s}|{} {}|", .{ @tagName(button), button_fmt[0], button_fmt[1] });
    }

    pub fn exportAxisBinding(writer: anytype, axis: AxisType) !void {
        const axis_fmt: struct { i32, i32 } = switch (axis) {
            .keyboard => |kb| .{ kb.positive, kb.negative },
            .mouse_x => .{ 0, 0 },
            .mouse_y => .{ 0, 0 },
            .gamepad => |gp| .{ gp.gamepad_num, gp.axis },
        };
        try writer.print("{s}|{} {}|", .{ @tagName(axis), axis_fmt[0], axis_fmt[1] });
    }

    pub fn importButtonBinding(str: []const u8) !ButtonType {
        const tn_and_vals = try getEnumTagNameAndVals(str);
        return ButtonType.fromString(tn_and_vals[0], tn_and_vals[1], tn_and_vals[2]);
    }

    pub fn importAxisBinding(str: []const u8) !AxisType {
        const tn_and_vals = try getEnumTagNameAndVals(str);
        return AxisType.fromString(tn_and_vals[0], tn_and_vals[1], tn_and_vals[2]);
    }

    fn getEnumTagNameAndVals(str: []const u8) !struct { []const u8, i32, i32 } {
        const enum_type_end = std.mem.indexOfScalar(u8, str, '|') orelse return error.BadFormat;
        const value_splitter_idx = std.mem.indexOfScalar(u8, str[enum_type_end..], ' ') orelse return error.BadFormat;

        const value0 = try std.fmt.parseInt(i32, str[enum_type_end + 1 ..][0 .. value_splitter_idx - 1], 10);
        const value1 = try std.fmt.parseInt(i32, str[enum_type_end..][value_splitter_idx + 1 .. str.len - enum_type_end - 1], 10);

        return .{ str[0..enum_type_end], value0, value1 };
    }

    /// Binds axes and buttons added in `.setupMouse()`
    pub fn bindMouse(controller: usize, input: anytype) !void {
        try input.addAxisBinding(controller, .mouse_x, .mouse_x);
        try input.addAxisBinding(controller, .mouse_y, .mouse_y);
        try input.addButtonBinding(controller, .mouse_left, .{ .mouse = rl.MOUSE_BUTTON_LEFT });
        try input.addButtonBinding(controller, .mouse_right, .{ .mouse = rl.MOUSE_BUTTON_RIGHT });
        try input.addButtonBinding(controller, .mouse_middle, .{ .mouse = rl.MOUSE_BUTTON_MIDDLE });
        try input.addButtonBinding(controller, .mouse_side, .{ .mouse = rl.MOUSE_BUTTON_SIDE });
        try input.addButtonBinding(controller, .mouse_extra, .{ .mouse = rl.MOUSE_BUTTON_EXTRA });
        try input.addButtonBinding(controller, .mouse_forward, .{ .mouse = rl.MOUSE_BUTTON_FORWARD });
        try input.addButtonBinding(controller, .mouse_back, .{ .mouse = rl.MOUSE_BUTTON_BACK });
    }
};

pub const MouseButtons = enum {
    mouse_left,
    mouse_right,
    mouse_middle,
    mouse_side,
    mouse_extra,
    mouse_forward,
    mouse_back,
};
pub const MouseAxes = enum {
    mouse_x,
    mouse_y,
};
