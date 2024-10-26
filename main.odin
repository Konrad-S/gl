// GLFW and OpenGL example with very verbose comments and links to documentation for learning
// By Soren Saket

// semi-colons ; are not requied in odin
// 

// Every Odin script belongs to a package 
// Define the package with the package [packageName] statement
// The main package name is reserved for the program entry point package
// You cannot have two different packages in the same directory
// If you want to create another package create a new directory and name the package the same as the directory
// You can then import the package with the import keyword
// https://odin-lang.org/docs/overview/#packages
package main

// Import statement
// https://odin-lang.org/docs/overview/#packages

// Odin by default has two library collections. Core and Vendor
// Core contains the default library all implemented in the Odin language
// Vendor contains bindings for common useful packages aimed at game and software development
// https://odin-lang.org/docs/overview/#import-statement

// fmt contains formatted I/O procedures.
// https://pkg.odin-lang.org/core/fmt/
import "core:fmt"
// C interoperation compatibility
import "core:c"

import "core:strings"


// Here we import OpenGL and rename it to gl for short
import gl "vendor:OpenGL"
// We use GLFW for cross platform window creation and input handling
import "vendor:glfw"


// Odin has type type inference
// variableName := value
// variableName : type = value
// You can set constants with ::

PROGRAMNAME :: "Program"

// GL_VERSION define the version of OpenGL to use. Here we use 4.6 which is the newest version
// You might need to lower this to 3.3 depending on how old your graphics card is.
// Constant with explicit type for example
GL_MAJOR_VERSION : c.int : 3
// Constant with type inference
GL_MINOR_VERSION :: 3

// Our own boolean storing if the application is running
// We use b32 for allignment and easy compatibility with the glfw.WindowShouldClose procedure
// See https://odin-lang.org/docs/overview/#basic-types for more information on the types in Odin
running : b32 = true

// The main function is the entry point for the application
// In Odin functions/methods are more precisely named procedures
// procedureName :: proc() -> returnType
// https://odin-lang.org/docs/overview/#procedures
main :: proc() {
    // Set Window Hints
    // https://www.glfw.org/docs/3.3/window_guide.html#window_hints
    // https://www.glfw.org/docs/3.3/group__window.html#ga7d9c8c62384b1e2821c4dc48952d2033
    glfw.WindowHint(glfw.RESIZABLE, 1)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR,GL_MAJOR_VERSION) 
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR,GL_MINOR_VERSION)
    glfw.WindowHint(glfw.OPENGL_PROFILE,glfw.OPENGL_CORE_PROFILE)
    
    // Initialize glfw
    // GLFW_TRUE if successful, or GLFW_FALSE if an error occurred.
    // GLFW_TRUE = 1
    // GLFW_FALSE = 0
    // https://www.glfw.org/docs/latest/group__init.html#ga317aac130a235ab08c6db0834907d85e
    if(glfw.Init() != true){
        // Print Line
        fmt.println("Failed to initialize GLFW")
        // Return early
        return
    }
    // the defer keyword makes the procedure run when the calling procedure exits scope
    // Deferes are executed in reverse order. So the window will get destoryed first
    // They can also just be called manually later instead without defer. This way of doing it ensures are terminated.
    // https://odin-lang.org/docs/overview/#defer-statement
    // https://www.glfw.org/docs/3.1/group__init.html#gaaae48c0a18607ea4a4ba951d939f0901
    defer glfw.Terminate()

    // Create the window
    // Return WindowHandle rawPtr
    // https://www.glfw.org/docs/3.3/group__window.html#ga3555a418df92ad53f917597fe2f64aeb
    window := glfw.CreateWindow(512, 512, PROGRAMNAME, nil, nil)
    // https://www.glfw.org/docs/latest/group__window.html#gacdf43e51376051d2c091662e9fe3d7b2
    defer glfw.DestroyWindow(window)

    // If the window pointer is invalid
    if window == nil {
        fmt.println("Unable to create window")
        return
    }
    
    //
    // https://www.glfw.org/docs/3.3/group__context.html#ga1c04dc242268f827290fe40aa1c91157
    glfw.MakeContextCurrent(window)
    
    // Enable vsync
    // https://www.glfw.org/docs/3.3/group__context.html#ga6d4e0cdf151b5e579bd67f13202994ed
    glfw.SwapInterval(1)

    // This function sets the key callback of the specified window, which is called when a key is pressed, repeated or released.
    // https://www.glfw.org/docs/3.3/group__input.html#ga1caf18159767e761185e49a3be019f8d
    glfw.SetKeyCallback(window, key_callback)

    // This function sets the framebuffer resize callback of the specified window, which is called when the framebuffer of the specified window is resized.
    // https://www.glfw.org/docs/3.3/group__window.html#gab3fb7c3366577daef18c0023e2a8591f
    glfw.SetFramebufferSizeCallback(window, size_callback)

    // Set OpenGL Context bindings using the helper function
    // See Odin Vendor source for specifc implementation details
    // https://github.com/odin-lang/Odin/tree/master/vendor/OpenGL
    // https://www.glfw.org/docs/3.3/group__context.html#ga35f1837e6f666781842483937612f163

    // casting the c.int to int
    // This is needed because the GL_MAJOR_VERSION has an explicit type of c.int
    gl.load_up_to(int(GL_MAJOR_VERSION), GL_MINOR_VERSION, glfw.gl_set_proc_address) 
    
    init()
    

    // There is only one kind of loop in Odin called for
    // https://odin-lang.org/docs/overview/#for-statement
    for (!glfw.WindowShouldClose(window) && running) {
        // Process waiting events in queue
        // https://www.glfw.org/docs/3.3/group__window.html#ga37bd57223967b4211d60ca1a0bf3c832
        glfw.PollEvents()
        
        update()
        draw()

        // This function swaps the front and back buffers of the specified window.
        // See https://en.wikipedia.org/wiki/Multiple_buffering to learn more about Multiple buffering
        // https://www.glfw.org/docs/3.0/group__context.html#ga15a5a1ee5b3c2ca6b15ca209a12efd14
        glfw.SwapBuffers((window))
    }

    exit()
    
}

VAO : u32

init :: proc(){
    // Own initialization code there

    vertex_buffer, vertex_shader, fragment_shader, program, EBO : u32
    mvp_location, vpos_location, vcol_location : i32

    vertex_shader = gl.CreateShader(gl.VERTEX_SHADER);
    shader_builder : strings.Builder
    defer strings.builder_destroy(&shader_builder)
    strings.write_string(&shader_builder, vertex_shader_text)
    vertex_shader_cstring := strings.to_cstring(&shader_builder)
    gl.ShaderSource(vertex_shader, 1, &vertex_shader_cstring, nil);
    gl.CompileShader(vertex_shader);
    success : i32
    gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success)
    if success == 0 do fmt.println("Failed gl.GetShaderiv")
    strings.builder_reset(&shader_builder)

    fragment_shader = gl.CreateShader(gl.FRAGMENT_SHADER);
    strings.write_string(&shader_builder, fragment_shader_text)
    fragment_shader_cstring := strings.to_cstring(&shader_builder)
    gl.ShaderSource(fragment_shader, 1, &fragment_shader_cstring, nil);
    gl.CompileShader(fragment_shader);
    gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success)
    if success == 0 do fmt.println("Failed gl.GetShaderiv")


    shader_program = gl.CreateProgram()
    gl.AttachShader(shader_program, vertex_shader)
    gl.AttachShader(shader_program, fragment_shader)
    gl.LinkProgram(shader_program)
    gl.GetProgramiv(shader_program, gl.LINK_STATUS, &success)
    if success == 0 do fmt.println("Failed gl.GetProgramiv")
    gl.DeleteShader(vertex_shader)
    gl.DeleteShader(fragment_shader)



    gl.GenVertexArrays(1, &VAO)
    gl.GenBuffers(1, &vertex_buffer)
    gl.GenBuffers(1, &EBO)
    gl.BindVertexArray(VAO)

    gl.BindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW);

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)

    gl.BindBuffer(gl.ARRAY_BUFFER, 0)

    gl.BindVertexArray(0)
}   
shader_program : u32

Vertice :: struct {
    x, y, z : f32
}

vertices : [12]f32 = {
         0.5,  0.5, 0.0,  // top right
         0.5, -0.5, 0.0,  // bottom right
        -0.5, -0.5, 0.0,  // bottom left
        -0.5,  0.5, 0.0   // top left 
}

indices : [6]u32 = {
    0, 1, 3,
    1, 2, 3
}



vertex_shader_text : string = "#version 330 core\nlayout (location = 0) in vec3 aPos;\nvoid main()\n{\n   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n}" 
fragment_shader_text : string = "#version 330 core\n    out vec4 FragColor;\n    void main()\n    {\n       FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);\n    }\n"

update :: proc(){
    // Own update code here
}

draw :: proc(){
    // Set the opengl clear color
    // 0-1 rgba values
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    // Clear the screen with the set clearcolor
    gl.Clear(gl.COLOR_BUFFER_BIT)

    // Own drawing code here
    gl.UseProgram(shader_program)
    gl.BindVertexArray(VAO)
    raw_thing : i32
    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, &raw_thing)
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