const std = @import("std");
const lib = @import("lib.zig");

// coordinate system: x-right, y-up, z-forward

const pi: f32 = 3.14159265359;

const R: f32 = 1; // big circle
const r: f32 = 0.5; // small circle
const N: u8 = 100; // for sampling points

const lightsource = lib.Vec3{ .x = 0, .y = 2, .z = 0 };

const z_prime: f32 = 3.0; // focal length

// 100x100 pixels
const width: u8 = 100;
const height: u8 = 100;

const ascii_chars = [_]u8{ '.', ',', '-', ' ', '~', ':', ';', '=', '!', '*', '#', '$', '@' };

const ns_per_us = 1000;
const ns_per_ms = 1000 * ns_per_us;

fn update(theta_x: *f32, theta_y: *f32) !void {
    // rotation matrices (column major)

    const rot_x = lib.Mat3x3{
        .i = lib.Vec3{ .x = 1, .y = 0, .z = 0 },
        .j = lib.Vec3{ .x = 0, .y = @cos(theta_x.*), .z = -@sin(theta_x.*) },
        .k = lib.Vec3{ .x = 0, .y = @sin(theta_x.*), .z = @cos(theta_x.*) },
    };

    const rot_y = lib.Mat3x3{
        .i = lib.Vec3{ .x = @cos(theta_y.*), .y = 0, .z = @sin(theta_y.*) },
        .j = lib.Vec3{ .x = 0, .y = 1, .z = 0 },
        .k = lib.Vec3{ .x = -@sin(theta_y.*), .y = 0, .z = @cos(theta_y.*) },
    };

    theta_x.* = if (theta_x.* > 2 * pi) 0 else theta_x.* + 0.1;
    theta_y.* = if (theta_y.* > 2 * pi) 0 else theta_y.* + 0.15;

    // depth buffer will also serve as the bitmap

    var depth_buffer: [width][height]f32 = undefined;

    for (&depth_buffer) |*row| {
        @memset(row, std.math.inf(f32));
    }

    // compute torus (oversample points)

    for (1..N) |a| {
        const theta = @as(f32, @floatFromInt(a)) * (2 * pi) / N; // big circle

        for (1..N) |b| {
            const phi = @as(f32, @floatFromInt(b)) * (2 * pi) / N; // small circle

            const cos_theta = @cos(theta);
            const sin_theta = @sin(theta);
            const cos_phi = @cos(phi);
            const sin_phi = @sin(phi);

            // compute point and apply rotations

            const point = lib.Vec3{
                .x = (R + r * cos_phi) * cos_theta,
                .y = r * sin_phi,
                .z = (R + r * cos_phi) * sin_theta,
            };

            var rotated_point: lib.Vec3 = point.mul(rot_x).mul(rot_y);

            // compute lighting

            const t_theta = lib.Vec3{
                .x = -(R + r * cos_phi) * sin_theta, // dx/d_theta
                .y = 0, // dy/d_theta
                .z = (R + r * cos_phi) * cos_theta, // dz/d_theta
            };

            const t_phi = lib.Vec3{
                .x = -r * sin_phi * cos_theta, // dx/d_phi
                .y = r * cos_phi, // dy/d_phi
                .z = -r * sin_phi * sin_theta, // dz/d_phi
            };

            const normal =  t_theta.cross(t_phi).normalize();
            rotated_point.brightness = normal.dot(lightsource) / (normal.len() * lightsource.len()); // cosine similarity

            // perspective projection

            const z_translated = rotated_point.z + 10; // manually offset by 10 units

            // multiply by 50 to convert unit-space coordinates to pixel-space coordinates (scale the normalized coordinates to fit a 100x100 pixel grid with (50,50) as the center)
            const x: f32 = (z_prime * rotated_point.x / z_translated) * 50;
            const y: f32 = (z_prime * rotated_point.y / z_translated) * 50;

            // manually offset the pixels so the donut fits in the terminal
            const x_screen: usize = @intFromFloat(x + 25);
            const y_screen: usize = @intFromFloat(y + 75);

            // depth buffer

            if (x_screen >= 0 and x_screen < width and y_screen >= 0 and y_screen < height) {
                if (z_translated < depth_buffer[x_screen][y_screen]) {
                    depth_buffer[x_screen][y_screen] = rotated_point.brightness;
                }
            }
        }
    }

    // draw torus

    for (1..width) |x| {
        for (1..height) |y| {
            const value = (depth_buffer[x - 1][y - 1] + 1) * 6;
            if (value <= 12) {
                const index = @as(usize, @intFromFloat(@round(value)));
                const ascii = ascii_chars[index];
                try std.io.getStdOut().writer().print("\x1B[{d};{d}H", .{ height - y, x + 1 }); // move cursor
                try std.io.getStdOut().writer().print("{c}", .{ascii}); // print ascii ({c} is a "formatting specifier" which formats a byte into an ascii character)
            }
        }
    }

    std.time.sleep(50 * ns_per_ms); // sleep 50 ms
}

pub fn main() !void {
    // rotate around the x and y axes
    var theta_x: f32 = 0;
    var theta_y: f32 = 0;

    while (true) {
        try std.io.getStdOut().writer().writeAll("\x1B[2J\x1B[H"); // clear terminal
        try update(&theta_x, &theta_y);
    }
}
