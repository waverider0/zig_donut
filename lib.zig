pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
    brightness: f32 = 0, // just including this here for convenience

    pub fn dot(self: Vec3, u: Vec3) f32 {
        return (self.x * u.x) + (self.y * u.y) + (self.z * u.z);
    }

    pub fn cross(self: Vec3, u: Vec3) Vec3 {
        return Vec3{
            .x = (self.y * u.z) - (self.z * u.y),
            .y = (self.z * u.x) - (self.x * u.z),
            .z = (self.x * u.y) - (self.y * u.x),
        };
    }

    pub fn mul(self: Vec3, m: Mat3x3) Vec3 {
        return Vec3{
            .x = (self.x * m.i.x) + (self.y * m.j.x) + (self.z * m.k.x),
            .y = (self.x * m.i.y) + (self.y * m.j.y) + (self.z * m.k.y),
            .z = (self.x * m.i.z) + (self.y * m.j.z) + (self.z * m.k.z),
        };
    }

    pub fn len(self: Vec3) f32 {
        return @sqrt((self.x * self.x) + (self.y * self.y) + (self.z * self.z));
    }

    pub fn normalize(self: Vec3) Vec3 {
        const length = self.len();
        return Vec3{
            .x = self.x / length,
            .y = self.y / length,
            .z = self.z / length,
        };
    }
};

pub const Mat3x3 = struct {
    // column major
    i: Vec3,
    j: Vec3,
    k: Vec3,
};
