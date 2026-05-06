package raytracer

import "core:fmt"
import "core:math"

Background := Rgb {0, 0, 0}

Scene :: struct {
    spheres: []Sphere
}

scene := Scene {
    []Sphere {
        {
            {0., -1., 3.},
            1.,
            {255, 0, 0}
        },
        {
            {2., 0., 3.},
            1.,
            {0, 255, 0}
        },
        {
            {-2., 0., 3.},
            1.,
            {0, 0, 255}
        },
    }
}

intersect_ray_sphere :: proc(o, d: Vec3, sphere: Sphere, t_max: f64) -> (f64, f64) {
    co := o - sphere.center

    // t^2<d, d> + 2t<o, d> + <o, o> - r^2 = 0
    // a^2 + bt + c = 0
    a := dot(d, d)
    b := 2. * dot(co, d)
    c := dot(co, co) - sphere.radius * sphere.radius

    res := b * b - 4. * a * c
    if res < 0 do return t_max, t_max
    
    sqrt_d := math.sqrt(res)

    t1 := (-b + sqrt_d) / (2. * a)
    t2 := (-b - sqrt_d) / (2. * a)
    return t1, t2
}

closest_intersection :: proc(o, d: Vec3, t_min, t_max: f64) -> (f64, int) {
    closest_t := t_max
    hit := -1

    for i in 0..<len(scene.spheres) {
        t1, t2 := intersect_ray_sphere(o, d, scene.spheres[i], t_max)

        if t1 >= t_min && t1 <= t_max && t1 < closest_t do closest_t, hit = t1, i
        if t2 >= t_min && t2 <= t_max && t2 < closest_t do closest_t, hit = t2, i
    }
    return closest_t, hit
}

trace_ray :: proc(o, d: Vec3, t_min, t_max: f64) -> Rgb {
    closest_t, hit := closest_intersection(o, d, t_min, t_max)
    if hit == -1 do return Background

    closest_sphere := scene.spheres[hit]
    base := closest_sphere.color
    return base 
}

main :: proc() {
    ps: pixels = make([dynamic]byte, width * height * 3)
    filename := "out.ppm"

    // camera
    o := Vec3 {0., 0., 0.}

    for y in 0..<height {
        for x in 0..<width {
            d := canvas_to_viewpoint(x, y)
            color := trace_ray(o, d, 1., 1.e10)
            set_pixel(&ps, color, x, y)
        }
    }

    if ok := write_to_ppm(filename, ps); !ok do fmt.println("Failed to write to ppm.")
}
