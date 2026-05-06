package raytracer

import "core:bytes"
import "core:fmt"
import "core:os"

pixels :: [dynamic]byte

Rgb :: struct {
    r, g, b: byte
}

width, height := 1024, 1024

write_to_ppm :: proc(filename: string, ps: pixels) -> bool {
    out: bytes.Buffer
    defer bytes.buffer_destroy(&out)

    bytes.buffer_write_string(&out, "P6\n")
    bytes.buffer_write_string(&out, fmt.tprintf("{} {}\n", width, height))
    bytes.buffer_write_string(&out, "255\n")

    bytes.buffer_write(&out, ps[:])

    if ok := os.write_entire_file(filename, bytes.buffer_to_bytes(&out)); !ok do return false
    return true
}

set_pixel :: proc(ps: ^pixels, rgb: Rgb, x, y: int) {
    index := (y * width + x) * 3
    ps[index] = rgb.r 
    ps[index + 1] = rgb.g
    ps[index + 2] = rgb.b
}
