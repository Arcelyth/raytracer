package raytracer

import "core:math"

Vec3 :: [3]f64

Sphere :: struct {
    center: Vec3, 
    radius: f64,
    color: Rgb,
    specular: f64,
    reflective: f64,
}

canvas_to_viewpoint :: proc(x, y: int) -> Vec3 {
    // viewpoint's width, height, distance
    vw, vh, d := 1., 1., 1.

    cx := f64(x) - f64(width) / 2.
    cy := f64(height) / 2. - f64(y)

    return Vec3 {
        cx * vw / f64(width),
        cy * vh / f64(height),
        d
    }
}

dot :: proc(a, b: Vec3) -> f64 {
    return a.x * b.x + a.y * b.y + a.z * b.z
}

length :: proc(v: Vec3) -> f64 {
    return math.sqrt(dot(v, v))
}

normalize :: proc(v: Vec3) -> Vec3 {
    l := length(v)
    return v / l
}
