extends MeshInstance3D

func _ready() -> void:
	# 1) Create a local rendering device.
	var rd := RenderingServer.create_local_rendering_device()

	# 2) Load the GLSL shader.
	var shader_file := load("res://assets/shaders/compute_example.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)

	# 3) Prepare data (using 32-bit floats).
	var input := PackedFloat32Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
	var input_bytes := input.to_byte_array()

	# 4) Create a storage buffer to hold float values (10 floats => 40 bytes).
	var buffer := rd.storage_buffer_create(input_bytes.size(), input_bytes)

	# 5) Create a uniform describing how the shader will access the buffer.
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0  # must match "binding" in the shader
	uniform.add_id(buffer)

	# 6) Create a uniform set for the specified "set" in the shader.
	var uniform_set := rd.uniform_set_create([uniform], shader, 0)

	# 7) Create a compute pipeline from the shader.
	var pipeline := rd.compute_pipeline_create(shader)

	# 8) Begin a compute list, bind pipeline & uniform set, and dispatch.
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 5, 1, 1)  # group sizes (x=5, y=1, z=1)
	rd.compute_list_end()

	# You may want to call 'RenderingServer.flush()' or 'rd.sync()' 
	# to ensure the compute pass finishes before you read back data.
	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()

	# Optionally, print a message.
	print("Compute pipeline dispatched.")
	# Read back the data from the buffer
	var output_bytes := rd.buffer_get_data(buffer)
	var output := output_bytes.to_float32_array()
	print("Input: ", input)
	print("Output: ", output)

func _process(delta: float) -> void:
	# In case you want to do something each frame
	pass
