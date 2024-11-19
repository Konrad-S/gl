package gl

import "core:fmt"
import "core:c"
import "core:strings"
import "core:os"
import "core:image/bmp"
import "core:math"
import "core:math/linalg"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "shader"

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
    camera_pos : [3]f32 = {0, 0, 3}

    last_time := cast(f32)glfw.GetTime()
    game := Game_State{ player_pos = {.2, .05}}

    for (!glfw.WindowShouldClose(window) && running) {
        delta_time : f32 = cast(f32)glfw.GetTime() - last_time
        last_time = cast(f32)glfw.GetTime()
        process_input(window, &camera_pos, delta_time)
        update()
        simulate(&game, delta_time)
        shader.set_vec2_float(shader_program, "player_pos", game.player_pos.x, game.player_pos.y)
        draw(shader_program, VAO, camera_pos)
        glfw.SwapBuffers(window)
        glfw.PollEvents()
    }
    gl.DeleteVertexArrays(1, &VAO)
    gl.DeleteProgram(shader_program)
    glfw.Terminate()
    exit()
}

Game_State :: struct {
    player_pos : [2]f32
}

simulate :: proc(game : ^Game_State, delta_time : f32) {
    game.player_pos.x += delta_time * .05
}

process_input :: proc(window : glfw.WindowHandle, camera_pos : ^[3]f32, delta_time : f32) {
    // todo : use key callback instead
    camera_speed : f32 : 5
    if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) {
        glfw.SetWindowShouldClose(window, true)
    }
    if (glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS) {
        camera_pos^ += CAMERA_FRONT * camera_speed * delta_time
    }
    if (glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS) {
        camera_pos^ -= CAMERA_FRONT * camera_speed * delta_time
    }
    if (glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS) {
        camera_pos^ += linalg.vector_normalize(linalg.vector_cross3(camera_pos^ + CAMERA_FRONT, CAMERA_UP)) * camera_speed * delta_time
    }
    if (glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS) {
        camera_pos^ -= linalg.vector_normalize(linalg.vector_cross3(camera_pos^ + CAMERA_FRONT, CAMERA_UP)) * camera_speed * delta_time
    }
}

init :: proc() -> (u32, u32) {
    shader_program := shader.create_program("shader/vertex_shader.txt", "shader/fragment_shader.txt")
    gl.UseProgram(shader_program)
    shader.set_vec2_float(shader_program, "offset", 0, 0)
    gl.Enable(gl.DEPTH_TEST)


    projection_matrix := linalg.matrix4_perspective_f32(cast(f32)linalg.to_radians(45.), SCR_WIDTH / SCR_HEIGHT, .1, 100)
    transform_location := gl.GetUniformLocation(shader_program, "projection")
    flatten := linalg.matrix_flatten(projection_matrix)
    raw := raw_data(flatten[:])
    gl.UniformMatrix4fv(transform_location, 1, gl.FALSE, raw)

    VERTEX_SIZE :: 5
    VERTEX_COUNT :: 36


    vertices : [VERTEX_SIZE * VERTEX_COUNT]f32 = {
        -0.5, -0.5, -0.5,  0.0, 0.0,
         0.5, -0.5, -0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5,  0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 0.0,

        -0.5, -0.5,  0.5,  0.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5,  0.5,  0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,

        -0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5,  0.5,  1.0, 0.0,

         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5,  0.5,  0.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,

        -0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  1.0, 1.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,

        -0.5,  0.5, -0.5,  0.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5, -0.5,  0.0, 1.0
    }

    indices : [6]u32 = {  // note that we start from 0!
        0, 1, 3,   // first triangle
        1, 2, 3,   // second triangle
    }

    texture : u32
    gl.GenTextures(1, &texture)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, texture)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.MIRRORED_REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    
    texture_data, ok := bmp.load_from_file("texture/fourth.bmp")
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, cast(i32)texture_data.width, cast(i32)texture_data.height, 0, gl.RGB, gl.UNSIGNED_BYTE, raw_data(texture_data.pixels.buf))
    gl.GenerateMipmap(gl.TEXTURE_2D)
    shader.set_int(shader_program, "texture1", 0)

    gl.GenTextures(1, &texture)
    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, texture)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.MIRROR_CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    
    texture_data, ok = bmp.load_from_file("texture/third.bmp")
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, cast(i32)texture_data.width, cast(i32)texture_data.height, 0, gl.RGB, gl.UNSIGNED_BYTE, raw_data(texture_data.pixels.buf))
    gl.GenerateMipmap(gl.TEXTURE_2D)
    shader.set_int(shader_program, "texture1", 1)


    VBO, VAO, EBO : u32

    gl.GenVertexArrays(1, &VAO)
    gl.GenBuffers(1, &VBO)
    gl.GenBuffers(1, &EBO)
    gl.BindVertexArray(VAO)

    gl.BindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW);

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices[0], gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, VERTEX_SIZE * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)

    gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, VERTEX_SIZE * size_of(f32), 3 * size_of(f32))
    gl.EnableVertexAttribArray(1)

    gl.BindBuffer(gl.ARRAY_BUFFER, 0)

    gl.BindVertexArray(0)

    return shader_program, VAO
}


update :: proc(){
    // Own update code here
}

CAMERA_FRONT : [3]f32 : {0, 0, -1}
CAMERA_UP    : [3]f32 : {0, 1,  0}

draw :: proc(shader_program, VAO : u32, camera_pos : [3]f32){
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.UseProgram(shader_program)
    gl.BindVertexArray(VAO)


    radius : f32 = 10.0
    cam_x := cast(f32)math.sin(glfw.GetTime()) * radius
    cam_y := cast(f32)math.cos(glfw.GetTime()) * radius


//    view_matrix := linalg.matrix4_look_at_f32({cam_x, 0, cam_y}, {0, 0, 0}, {0, 1, 0})'
    test := camera_pos + CAMERA_FRONT
    view_matrix := linalg.matrix4_look_at_f32(camera_pos, test, {0, 1, 0})

    shader.set_matrix4(shader_program, "view", view_matrix)


    cube_positions : [4][3]f32 = {
        { 0, 0, 0 },
        { 1, 1, 1 },
        { 2, 2, 2 },
        { 3, 3, 3 },
    }

    for position, i in cube_positions {
        translation_matrix := linalg.matrix4_translate_f32(position)
        rotation_matrix := linalg.matrix4_rotate_f32(cast(f32)glfw.GetTime() * cast(f32)(i%3.0), {1, 1, 1})

        combined_matrix : matrix[4, 4]f32 = translation_matrix * rotation_matrix

        transform_location_m := gl.GetUniformLocation(shader_program, "model")
        flatten_m := linalg.matrix_flatten(combined_matrix)
        raw_m := raw_data(flatten_m[:])
        gl.UniformMatrix4fv(transform_location_m, 1, gl.FALSE, raw_m)

        //gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
        gl.DrawArrays(gl.TRIANGLES, 0, 36)
    }
}

exit :: proc(){
    // Own termination code here
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
    // todo : store all actions in a buffer
    switch key {
    case glfw.KEY_ESCAPE:
        running = false
    case glfw.KEY_W:


    }
}

// Called when glfw window changes size
size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
    // Set the OpenGL viewport size
    gl.Viewport(0, 0, width, height)
}