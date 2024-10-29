package shader

import "core:os"
import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"

main :: proc() {}

id : u32

create_program :: proc() {
	vertex_shader_from_file, okv := os.read_entire_file_from_filename("shader/vertex_shader.txt")
    if !okv do fmt.println("Failed to read shader file")
    vertex_cstring := cstring(&vertex_shader_from_file[0])
    vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vertex_shader, 1, &vertex_cstring, nil);
    gl.CompileShader(vertex_shader);
    success : i32
    gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success)
    if success == 0 {
        fmt.println("Failed gl.GetShaderiv for vertex shader")
        length : i32
        data : [512]u8
        gl.GetShaderInfoLog(vertex_shader, 512, &length, &data[0])
        text := strings.string_from_ptr(&data[0], cast(int)length)
        fmt.println(text)
    }
    fragment_shader_from_file, okf := os.read_entire_file_from_filename("shader/fragment_shader.txt")
    if !okf do fmt.println("Failed to read shader file")
    fragment_cstring := cstring(&fragment_shader_from_file[0])
    fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER);
    gl.ShaderSource(fragment_shader, 1, &fragment_cstring, nil);
    gl.CompileShader(fragment_shader);
    gl.GetShaderiv(fragment_shader, gl.COMPILE_STATUS, &success)
    if success == 0 {
        fmt.println("Failed gl.GetShaderiv for fragment shader")
        length : i32
        data : [512]u8
        gl.GetShaderInfoLog(fragment_shader, 512, &length, &data[0])
        text := strings.string_from_ptr(&data[0], cast(int)length)
        fmt.println(text)
    }
    id = gl.CreateProgram()
    gl.AttachShader(id, vertex_shader)
    gl.AttachShader(id, fragment_shader)
    gl.LinkProgram(id)
    gl.GetProgramiv(id, gl.LINK_STATUS, &success)
    if success == 0 {
        fmt.println("Failed gl.GetProgramiv")
        length : i32
        data : [512]u8
        gl.GetProgramInfoLog(id, 512, &length, &data[0])
        text := strings.string_from_ptr(&data[0], cast(int)length)
        fmt.println(text)
    }
    gl.DeleteShader(vertex_shader)
    gl.DeleteShader(fragment_shader)
}

set_bool :: proc(name : cstring, value : bool) {
	gl.Uniform1i(gl.GetUniformLocation(id, name), cast(i32)value)
} 