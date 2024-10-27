package main

import "core:fmt"
import "core:c"
import "core:strings"
import "core:os"

import gl "vendor:OpenGL"
import "vendor:glfw"

PROGRAMNAME :: "Program"
GL_MAJOR_VERSION : c.int : 3
GL_MINOR_VERSION :: 3
running : b32 = true
SCR_WIDTH :: 800
SCR_HEIGHT :: 600

main :: proc() {
    if(glfw.Init() != true){
        // Print Line
        fmt.println("Failed to initialize GLFW")
        // Return early
        return
    }
    glfw.WindowHint(glfw.RESIZABLE, 1)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION) 
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    defer glfw.Terminate()

    window := glfw.CreateWindow(SCR_WIDTH, SCR_HEIGHT, PROGRAMNAME, nil, nil)
    defer glfw.DestroyWindow(window)
    if window == nil {
        fmt.println("Unable to create window")
        return
    }
    glfw.MakeContextCurrent(window)
    //glfw.SwapInterval(1) todo: needed?
    //glfw.SetKeyCallback(window, key_callback) todo: needed?
    glfw.SetFramebufferSizeCallback(window, size_callback)
    gl.load_up_to(int(GL_MAJOR_VERSION), GL_MINOR_VERSION, glfw.gl_set_proc_address) // I assume this does the same thing GLAD would do?
    shader_program, VAO := init()
    for (!glfw.WindowShouldClose(window) && running) {
        process_input(window)
        update()
        draw(shader_program, VAO)
        glfw.SwapBuffers(window)
        glfw.PollEvents()
    }
    exit()
}

process_input :: proc(window : glfw.WindowHandle) {
    if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) {
        glfw.SetWindowShouldClose(window, true)
    }
}

init :: proc() -> (u32, u32) {
    vertex_shader_from_file, okv := os.read_entire_file_from_filename("shaders/vertex_shader.txt")
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

    fragment_shader_from_file, okf := os.read_entire_file_from_filename("shaders/fragment_shader.txt")
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

    shader_program := gl.CreateProgram()
    gl.AttachShader(shader_program, vertex_shader)
    gl.AttachShader(shader_program, fragment_shader)
    gl.LinkProgram(shader_program)
    gl.GetProgramiv(shader_program, gl.LINK_STATUS, &success)
    if success == 0 {
        fmt.println("Failed gl.GetProgramiv")
        length : i32
        data : [512]u8
        gl.GetProgramInfoLog(shader_program, 512, &length, &data[0])
        text := strings.string_from_ptr(&data[0], cast(int)length)
        fmt.println(text)
    }

    gl.DeleteShader(vertex_shader)
    gl.DeleteShader(fragment_shader)

    vertices : [18]f32 = {
        // positions         // colors
         0.5, -0.5, 0.0,  1.0, 0.0, 0.0,   // bottom right
        -0.5, -0.5, 0.0,  0.0, 1.0, 0.0,   // bottom left
         0.0,  0.5, 0.0,  0.0, 0.0, 1.0    // top 
    }

    VBO, VAO : u32

    gl.GenVertexArrays(1, &VAO)
    gl.GenBuffers(1, &VBO)
    gl.BindVertexArray(VAO)

    gl.BindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)

    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 3 * size_of(f32))
    gl.EnableVertexAttribArray(1)

    gl.BindBuffer(gl.ARRAY_BUFFER, 0)

    gl.BindVertexArray(0)

    return shader_program, VAO
}


update :: proc(){
    // Own update code here
}

draw :: proc(shader_program, VAO : u32){
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT)
    gl.UseProgram(shader_program)
    gl.BindVertexArray(VAO)
    gl.DrawArrays(gl.TRIANGLES, 0, 3)

}

exit :: proc(){
    // Own termination code here
}

// Called when glfw keystate changes
key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
    // Exit program on escape pressed
    if key == glfw.KEY_ESCAPE {
        running = false
    }
}

// Called when glfw window changes size
size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
    // Set the OpenGL viewport size
    gl.Viewport(0, 0, width, height)
}