package raytracer

import "core:fmt"
import "core:math"

LightType :: union {
    Ambient,
    Point,
    Directional,
}

Ambient :: struct {}

Point :: struct {
    position: Vec3
}

Directional :: struct {
    direction: Vec3
}

Light :: struct {
    type: LightType,
    intensity: f64
}

Background := Rgb {0, 0, 0}

Scene :: struct {
    spheres: []Sphere,
    lights: []Light
}

scene := Scene {
    []Sphere {
        {
            {0., -1., 3.},
            1.,
            {255, 0, 0},
            500.,
            0.2
        },
        {
            {2., 0., 3.},
            1.,
            {0, 255, 0},
            500.,
            0.3,
        },
        {
            {-2., 0., 3.},
            1.,
            {0, 0, 255},
            50,
            0.4
        },
        {
            {0., -5001., 0.},
            5000.,
            {255, 255, 0},
            1000.,
            0.5
        },
    },
    []Light {
        {
            Ambient {},
            .2
        },
        {
            Point {{2., 1., 0.}},
            .6
        },
        {
            Directional {{1., 4., 4.}},
            .2
        }
    }
}

computing_light :: proc(p, n, v: Vec3, s: f64) -> f64 {
    intensity := 0.
    for light in scene.lights {
        #partial switch l in light.type {
        case Ambient: 
            intensity += light.intensity
        case :
            dir: Vec3
            t_max := 1.e10
            if point, ok := l.(Point); ok do dir, t_max = point.position - p, 1.
            if direct, ok := l.(Directional); ok do dir = direct.direction

            // shadow
            _, hit := closest_intersection(p, dir, 0.001, t_max)
            if hit != -1 {
                continue
            }

            // diffuse
            n_dot_l := dot(n, dir)
            if n_dot_l > 0 {
                intensity += light.intensity * n_dot_l / (length(n) * length(dir))
            }

            // specular 
            if s != -1 {
                r := 2. * n * dot(n, dir) - dir 
                r_dot_v := dot(r, v)
                if r_dot_v > 0 {
                    intensity += light.intensity * math.pow(r_dot_v / (length(r) * length(v)), s)
                }
            }
        }
    }
    return intensity
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

reflect_ray :: proc(r, n: Vec3) -> Vec3 {
    return 2 * n * dot(n, r) - r
}

trace_ray :: proc(o, d: Vec3, t_min, t_max: f64, recursion_depth: int) -> Rgb {
    closest_t, hit := closest_intersection(o, d, t_min, t_max)
    if hit == -1 do return Background

    closest_sphere := scene.spheres[hit]
    p := o + d * closest_t
    n := normalize(p - closest_sphere.center)  
    light := computing_light(p, n, -d, closest_sphere.specular)
    if light > 1. do light = 1.
    base := closest_sphere.color
    local_color := Rgb {
        byte(f64(base.r) * light),
        byte(f64(base.g) * light),
        byte(f64(base.b) * light),
    } 
    r := closest_sphere.reflective
    if recursion_depth <= 0 || r <= 0 {
        return local_color
    }

    rr := reflect_ray(-d, n)
    reflected_color := trace_ray(p, rr, 0.001, t_max, recursion_depth - 1)

    return Rgb {
        byte(f64(local_color.r) * (1 - r) + f64(reflected_color.r) * r), 
        byte(f64(local_color.g) * (1 - r) + f64(reflected_color.g) * r), 
        byte(f64(local_color.b) * (1 - r) + f64(reflected_color.b) * r), 
    }
}

main :: proc() {
    ps: pixels = make([dynamic]byte, width * height * 3)
    filename := "out.ppm"

    // camera
    o := Vec3 {0., 0., 0.}

    for y in 0..<height {
        for x in 0..<width {
            d := canvas_to_viewpoint(x, y)
            color := trace_ray(o, d, 1., 1.e10, 2)
            set_pixel(&ps, color, x, y)
        }
    }

    if ok := write_to_ppm(filename, ps); !ok do fmt.println("Failed to write to ppm.")
}
