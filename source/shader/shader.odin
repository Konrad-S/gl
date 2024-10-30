package shader

import "core:os"
import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"

main :: proc() {}

create_program :: proc(vertex_path, fragment_path : string) -> u32 {
	vertex_shader_from_file, okv := os.read_entire_file_from_filename(vertex_path)
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
    fragment_shader_from_file, okf := os.read_entire_file_from_filename(fragment_path)
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
    program := gl.CreateProgram()
    gl.AttachShader(program, vertex_shader)
    gl.AttachShader(program, fragment_shader)
    gl.LinkProgram(program)
    gl.GetProgramiv(program, gl.LINK_STATUS, &success)
    if success == 0 {
        fmt.println("Failed gl.GetProgramiv")
        length : i32
        data : [512]u8
        gl.GetProgramInfoLog(program, 512, &length, &data[0])
        text := strings.string_from_ptr(&data[0], cast(int)length)
        fmt.println(text)
    }
    gl.DeleteShader(vertex_shader)
    gl.DeleteShader(fragment_shader)
    return program
}

set_bool :: proc(program : u32, name : cstring, value : bool) {
	gl.Uniform1i(gl.GetUniformLocation(program, name), cast(i32)value)
}

set_int :: proc(program : u32, name : cstring, value : i32) {
    gl.Uniform1i(gl.GetUniformLocation(program, name), cast(i32)value)
}

set_float :: proc(program : u32, name : cstring, value : f32) {
    gl.Uniform1i(gl.GetUniformLocation(program, name), cast(i32)value)
}