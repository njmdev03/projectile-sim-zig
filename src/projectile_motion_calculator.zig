pub const Vector2 = struct {
    x: f32,
    y: f32,
};

pub const EquationParams = struct {
    iV: Vector2,
    gravity: f32,
};

pub const CalculationError = error {
    ZeroGravityError,

};

pub fn velocityAtTime(p: *const EquationParams, time: f32) Vector2 {
    return .{
        .x = p.iV.x,
        .y = p.iV.y + (p.gravity * time)
    };
}

pub fn displacementAtTime(p: *const EquationParams, time: f32) Vector2 {
    return .{
        .x = p.iV.x * time,
        .y = p.iV.y * time + (0.5 * (p.gravity) * (time * time)),
    };
}

pub fn trajectoryAValue(p: *const EquationParams) f32 {
    return p.gravity / (2 * p.iV.x * p.iV.x);
}

pub fn trajectoryBValue(p: *const EquationParams) f32 {
    return p.iV.y / p.iV.x;
}

pub fn timeAtX(p: *const EquationParams, x: f32) f32 {
    return p.iV.x / x;
}

pub fn trajectoryOfX(p: *const EquationParams, x: f32) f32 {
    return x * (p.iV.y / p.iV.x) + (p.gravity * x * x) / (2 * p.iV.x * p.iV.x);
}

pub fn trajectoryOfY(p: *const EquationParams, y: f32) error{ZeroGravityError}![2]f32 {
    if (p.gravity == 0.0) {
        return error.ZeroGravityError;
    }

    const firstComp: f32 = @sqrt((2 * p.gravity * y) + (p.iV.y * p.iV.y));
    const secondComp: f32 = p.iV.y;

    const plusSolution: f32 = (p.iV.x * (firstComp + secondComp)) / p.gravity;
    const minusSolution: f32 = (p.iV.x * (firstComp - secondComp)) / p.gravity;

    return .{ plusSolution, minusSolution };
}

pub fn timeOfFlight(p: *const EquationParams) f32 {
    return - (2 * p.iV.y) / p.gravity;
}

pub fn maxHeight(p: *const EquationParams) f32 {
    return -(p.iV.y * p.iV.y) / (2 * p.gravity);
}

pub fn range(p: *const EquationParams) f32 {
    return -(p.iV.x * 2 * p.iV.y) / p.gravity;
}

pub fn controlPoint(p: *const EquationParams) Vector2 {
    // Use the second x intercept for now
    const xEnd: f32 = range(p);

    return .{
        .x = 0.5 * (xEnd),
        .y = 0.5 * (trajectoryBValue(p) * xEnd ),
    };

    // return .{
    //     .x = 0.5 * (xEnd),
    //     .y = -0.25 * ((trajectoryBValue(p) * trajectoryBValue(p)) / trajectoryAValue(p) ),
    // };
}