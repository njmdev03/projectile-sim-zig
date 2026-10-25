const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");
const rl_imgui = @import("rl_imgui");
const cimgui = @import("cimgui");
const calc = @import("projectile_calc");

const DistanceUnit = enum {
    m,
    in,
    ft,
};

fn getDistanceUnitShortName(u: DistanceUnit) []u8 {
    switch (u) {
        DistanceUnit.m => {
            return "m";
        },
        DistanceUnit.in => {
            return "in";
        },
        DistanceUnit.ft => {
            return "ft";
        },
    }
}

fn getDistanceUnitLongName(u: DistanceUnit) []u8 {
    switch (u) {
        DistanceUnit.m => {
            return "Meters";
        },
        DistanceUnit.in => {
            return "Inches";
        },
        DistanceUnit.ft => {
            return "Feet";
        },
    }
}

const VelocityUnit = enum {
    mPerS,
    inPerS,
    ftPerS,
};

fn getVelocityUnitShortName(u: VelocityUnit) []u8 {
    switch (u) {
        VelocityUnit.mPerS => {
            return "m/s";
        },
        VelocityUnit.inPerS => {
            return "in/s";
        },
        VelocityUnit.ftPerS => {
            return "ft/s";
        },
    }
}

fn getVelocityUnitLongName(u: VelocityUnit) []u8 {
    switch (u) {
        VelocityUnit.mPerS => {
            return "Meters/Second";
        },
        VelocityUnit.inPerS => {
            return "Inches/Second";
        },
        VelocityUnit.ftPerS => {
            return "Feet/Second";
        },
    }
}

const AccelerationUnit = enum {
    mPerSS,
    inPerSS,
    ftPerSS,
};

fn getAccelerationUnitShortName(u: AccelerationUnit) []u8 {
    switch (u) {
        VelocityUnit.mPerS => {
            return "m/s\u{00B2}";
        },
        VelocityUnit.inPerS => {
            return "in/s\u{00B2}";
        },
        VelocityUnit.ftPerS => {
            return "ft/s\u{00B2}";
        },
    }
}

fn getAccelerationUnitLongName(u: AccelerationUnit) []u8 {
    switch (u) {
        VelocityUnit.mPerS => {
            return "Meters/Second\u{00B2}";
        },
        VelocityUnit.inPerS => {
            return "Inches/Second\u{00B2}";
        },
        VelocityUnit.ftPerS => {
            return "Feet/Second\u{00B2}";
        },
    }
}

const TimeUnit = enum {
    s,
};

fn getTimeUnitShortName(u: TimeUnit) []u8 {
    switch (u) {
        TimeUnit.s => {
            return "Seconds";
        },
    }
}

const Inputs = struct {
    initVelX: f32,
    initVelY: f32,
    velCartesianUpdated: bool,

    initVelMag: f32,
    initVelAngle: f32,
    velPolarUpdated: bool,

    gravity: f32,
    gravityUpdated: bool,

    time: f32,
    timeUpdated: bool,

    worldScale: f32,
    worldScaleUpdated: bool,

    tickSpacing: f32,
    tickSpacingUpdated: bool,

    distanceUnit: DistanceUnit,
    distanceUnitUpdated: bool,

    velocityUnit: VelocityUnit,
    velocityUnitUpdated: bool,

    accelerationUnit: AccelerationUnit,
    accelerationUnitUpdated: bool,

    timeUnit: TimeUnit,
    timeUnitUpdated: bool,

    lineColor: rl.Color,
    markupColor: rl.Color,
    axisColor: rl.Color,
    backgroundColor: rl.Color,
};

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1600;
    const screenHeight = 900;

    rl.setConfigFlags(.{ .window_resizable = true, .window_highdpi = true });

    rl.initWindow(screenWidth, screenHeight, "parabolic trajectory calculator");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    // ImGui setup
    rl_imgui.setup(true);
    defer rl_imgui.shutdown();
    //--------------------------------------------------------------------------------------

    var target = rl.Vector2{ .x = 0, .y = 0 };

    var camera = rl.Camera2D{
        .target = target,
        .offset = .{
            .x = @as(f32, screenWidth) / 2.0,
            .y = @as(f32, screenHeight) / 2.0,
        },
        .rotation = 0,
        .zoom = 1.0,
    };

    var inputs: Inputs = .{
        .initVelX = 10,
        .initVelY = 10,

        .velCartesianUpdated = false,

        .initVelAngle = std.math.degreesToRadians(60.0),
        .initVelMag = 20,
        // Set the polar to updated in order to calculate the components
        .velPolarUpdated = true,

        .gravity = -9.81,
        .gravityUpdated = false,

        .time = 0,
        .timeUpdated = false,

        .worldScale = 20,
        .worldScaleUpdated = false,

        .tickSpacing = 1,
        .tickSpacingUpdated = false,

        .distanceUnit = DistanceUnit.m,
        .distanceUnitUpdated = false,

        .velocityUnit = VelocityUnit.mPerS,
        .velocityUnitUpdated = false,

        .accelerationUnit = AccelerationUnit.mPerSS,
        .accelerationUnitUpdated = false,

        .timeUnit = TimeUnit.s,
        .timeUnitUpdated = false,

        .lineColor = .dark_blue,
        .markupColor = .dark_green,
        .axisColor = .black,
        .backgroundColor = .white,
    };

    // I hate myself
    var first: bool = true;

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        const dt = rl.getFrameTime();

        // TODO Settings for senses
        const keySpeed: f32 = 200.0;
        const mouseSense: f32 = 1.0;

        var mouseOffset: rl.Vector2 = .{ .x = 0, .y = 0 };

        if (rl.isMouseButtonDown(.right)){
            // if (!rl.isCursorHidden()) {
            //     rl.disableCursor();
            // }

            mouseOffset = rl.getMouseDelta().scale(-mouseSense);
        }
        // else if (rl.isMouseButtonUp(.right)) {
        //     // if (rl.isCursorHidden()) {
        //     //     rl.enableCursor();
        //     // }
        // }

        var keyOffset: rl.Vector2 = .{ .x = 0, .y = 0 };
        if (rl.isKeyDown(.w)) keyOffset.y -= keySpeed * dt;
        if (rl.isKeyDown(.s)) keyOffset.y += keySpeed * dt;
        if (rl.isKeyDown(.a)) keyOffset.x -= keySpeed * dt;
        if (rl.isKeyDown(.d)) keyOffset.x += keySpeed * dt;

        target = target.add(keyOffset).add(mouseOffset);

        // Follow the player and adjust zoom.
        camera.target = target;
        camera.zoom = @max(
            0.25,
            camera.zoom + rl.getMouseWheelMove() * 0.1,
        );
        //----------------------------------------------------------------------------------

        // Prep inputs from last frame
        if (inputs.velCartesianUpdated) {
            inputs.initVelMag = @sqrt(inputs.initVelX * inputs.initVelX + inputs.initVelY * inputs.initVelY);
            inputs.initVelAngle = std.math.atan2(inputs.initVelY, inputs.initVelX);
        } else if (inputs.velPolarUpdated) {
            inputs.initVelX = inputs.initVelMag * @cos(inputs.initVelAngle);
            inputs.initVelY = inputs.initVelMag * @sin(inputs.initVelAngle);
        }

        inputs.velCartesianUpdated = false;
        inputs.velPolarUpdated = false;
        inputs.gravityUpdated = false;

        const calcParams = calc.EquationParams {
            .iV = .{ .x = inputs.initVelX, .y = inputs.initVelY, },
            .gravity = inputs.gravity,
        };

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(inputs.backgroundColor);

        {
            // Draw behind the world
            //----------------------------------------------------------------------------------
            //----------------------------------------------------------------------------------
        }

        {
            rl.beginMode2D(camera);
            defer rl.endMode2D();
            // Draw the world
            //----------------------------------------------------------------------------------
            const range = calc.range(&calcParams);
            const height = calc.maxHeight(&calcParams);

            if (first) {
                inputs.worldScale = @min(
                    (screenWidth / range) * 0.9,
                    (screenHeight / height) * 0.9
                );
            }

            const widthExtent = range * inputs.worldScale;
            const heightExtent = height * inputs.worldScale;

            if (first) {
                target.x = widthExtent / 2;
                target.y = -heightExtent / 2;

                inputs.time = calc.timeOfFlight(&calcParams) / 2;
            }

            rl.drawLineEx(.{ .x = 0, .y = 0 }, .{ .x = 0, .y = -heightExtent }, 4.0, inputs.axisColor);

            rl.drawLineEx(.{ .x = 0, .y = 0 }, .{ .x = widthExtent, .y = 0 }, 4.0, inputs.axisColor);

            const tickDelta = inputs.tickSpacing * inputs.worldScale;

            //TODO Make sure the axis are always an even number of ticks long (rounding up)

            const heightTicks = @as(usize, @trunc(@abs((heightExtent / tickDelta) + 1.0)));

            // TODO: Settings for tick size (rendered pixel length)

            for (0..heightTicks) |i| {
                const incr: f32 = @floatFromInt(i);
                rl.drawLineEx(.{ .x = -12.0, .y = -tickDelta * incr }, .{ .x = 0, .y = -tickDelta * incr }, 4.0, inputs.axisColor);
            }

            const widthTicks = @as(usize, @trunc(@abs((widthExtent / tickDelta) + 1.0)));

            for (0..widthTicks) |i| {
                const incr: f32 = @floatFromInt(i);
                rl.drawLineEx(.{ .x = tickDelta * incr, .y = 12.0 }, .{ .x = tickDelta * incr, .y = 0 }, 4.0, inputs.axisColor);
            }

            const launchPoint: rl.Vector2 = .{
                .x = 0,
                .y = 0,
            };

            const calcControl = calc.controlPoint(&calcParams);

            const controlPoint: rl.Vector2 = .{
                .x = calcControl.x * inputs.worldScale,
                .y = -calcControl.y * inputs.worldScale,
            };

            const landingPoint: rl.Vector2 = .{
                .x = range * inputs.worldScale,
                .y = 0,
            };

            rl.drawSplineBezierQuadratic(&[3]rl.Vector2 {
                launchPoint,
                controlPoint,
                landingPoint
            }, 6, inputs.lineColor);

            const timeRefPoint = calc.displacementAtTime(&calcParams, inputs.time);

            rl.drawCircle(@trunc(timeRefPoint.x * inputs.worldScale), @trunc(-timeRefPoint.y * inputs.worldScale), 8.0, inputs.markupColor);
            //----------------------------------------------------------------------------------
        }

        {
            // Draw in front of the world
            //----------------------------------------------------------------------------------
            // rl.drawText("This text is in front of the world", 0, 120, 20, .dark_purple);
            rl_imgui.begin();
            defer rl_imgui.end();

            drawControls(&inputs, &calcParams);
            //----------------------------------------------------------------------------------
        }

        //----------------------------------------------------------------------------------

        first = false;
    }
}

fn drawControls(inputs: *Inputs, params: *const calc.EquationParams) void {
    var open = true;
    defer cimgui.end();
    if (cimgui.begin("Controls", &open, @enumFromInt(0))) {
        if (cimgui.collapsingHeader("Parameters", 0)) {
            cimgui.separatorText("Initial Velocity (Polar form)");
            const rUpdated = cimgui.dragFloat("Magnitude", &inputs.initVelMag);
            const thetaUpdated = cimgui.sliderAngleEx("Angle", &inputs.initVelAngle, 0, 90, "%.0f deg", 0);
            cimgui.spacing();

            cimgui.separatorText("Initial Velocity (Cartesian form)");
            const xUpdated = cimgui.dragFloat("X", &inputs.initVelX);
            const yUpdated = cimgui.dragFloat("Y", &inputs.initVelY);
            cimgui.spacing();

            if (rUpdated or thetaUpdated) {
                inputs.velPolarUpdated = true;
                inputs.velCartesianUpdated = false;
            } else if (xUpdated or yUpdated) {
                inputs.velPolarUpdated = false;
                inputs.velCartesianUpdated = true;
            }

            cimgui.separatorText("World Config");
            inputs.gravityUpdated = cimgui.dragFloat("Gravity", &inputs.gravity);
        }

        if (cimgui.collapsingHeader("Results", 0)) {
            cimgui.labelText("Time of flight", "%f", calc.timeOfFlight(params));
            cimgui.labelText("Range", "%f", calc.range(params));
            cimgui.labelText("Max height", "%f", calc.maxHeight(params));
            cimgui.spacing();

            inputs.timeUpdated = cimgui.sliderFloat("Time", &inputs.time, 0.0, calc.timeOfFlight(params));
            cimgui.spacing();

            // const velStr = std.fmt.allocPrintSentinel(alloc, "Velocity @ {d}", .{inputs.time}, 0)
            //     catch @panic("OOM");
            // defer alloc.free(velStr);
            //
            // cimgui.separatorText(velStr);

            var velBuf: [64:0]u8 = undefined;
            const velStr = std.fmt.bufPrintSentinel(
                &velBuf,
                "Velocity @ {d}",
                .{inputs.time},
                0,
            ) catch unreachable;

            cimgui.separatorText(velStr);

            const velocity = calc.velocityAtTime(params, inputs.time);
            cimgui.labelText("X", "%f", velocity.x);
            cimgui.labelText("Y", "%f", velocity.y);

            // const dissStr = std.fmt.allocPrintSentinel(alloc, "Displacement @ {d}", .{inputs.time}, 0)
            //     catch @panic("OOM");
            // defer alloc.free(dissStr);

            // cimgui.separatorText(dissStr);

            var dissBuf: [64:0]u8 = undefined;
            const dissStr = std.fmt.bufPrintSentinel(
                &dissBuf,
                "Displacement @ {d}",
                .{inputs.time},
                0,
            ) catch unreachable;

            cimgui.separatorText(dissStr);

            const dissplacement = calc.displacementAtTime(params, inputs.time);
            cimgui.labelText("X", "%f", dissplacement.x);
            cimgui.labelText("Y", "%f", dissplacement.y);
        }

        if (cimgui.collapsingHeader("Settings", 0)) {
            inputs.worldScaleUpdated = cimgui.dragFloat("World Scale", &inputs.worldScale);

            if (cimgui.collapsingHeader("Styling", 0)) {
                inputs.tickSpacingUpdated = cimgui.dragFloat("Tick Spacing", &inputs.tickSpacing);

                _ = colorPicker("Background", &inputs.backgroundColor, @enumFromInt(0));
                _ = colorPicker("Trajectory", &inputs.lineColor, @enumFromInt(0));
                _ = colorPicker("Markup", &inputs.markupColor, @enumFromInt(0));
                _ = colorPicker("Axis", &inputs.axisColor, @enumFromInt(0));
            }
        }

        if (builtin.mode == .debug) {
            if (cimgui.collapsingHeader("Debug", 0)) {
                _ = cimgui.collapsingHeader("Units", 0);
            }
        }
    }
}

fn colorPicker(label: cimgui.TerminatedString, color: *rl.Color, flags: cimgui.ImGuiColorEditFlags) bool {
    const r: f32 = @as(f32, @floatFromInt(color.r)) / 255.0;
    const g: f32 = @as(f32, @floatFromInt(color.g)) / 255.0;
    const b: f32 = @as(f32, @floatFromInt(color.b)) / 255.0;

    var colorArray = [3]f32{r, g, b};

    const ret = cimgui.colorEdit3(label, &colorArray, flags);

    const interColor = rl.colorFromNormalized(.{
        .x = colorArray[0],
        .y = colorArray[1],
        .z = colorArray[2],
        .w = 1.0,
    });

    color.r = interColor.r;
    color.g = interColor.g;
    color.b = interColor.b;
    color.a = 255;

    return ret;
}