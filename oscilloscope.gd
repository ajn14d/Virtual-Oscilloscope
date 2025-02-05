extends Node2D

@onready var audio_player = $AudioStreamPlayer
@onready var draw_area = $Control  # Make sure this Control node exists
@onready var amplitude_slider = $Control/AmplitudeSlider  # The Amplitude slider
@onready var frequency_slider = $Control/FrequencySlider  # The Frequency slider
@onready var wave_density_slider = $Control/WaveDensitySlider  # The Wave Density slider

var generator = AudioStreamGenerator.new()
var playback: AudioStreamGeneratorPlayback
var buffer_size = 2048
var waveform_data = []

var phase = 0.0  # Track the phase to keep the waveform continuous
var frequency = 440.0  # Default frequency (A4 note)
var amplitude = 0.5  # Default amplitude
var wave_density = 1.0  # Default wave density (visual)

func _ready():
	# Set up the audio stream
	generator.mix_rate = 44100
	audio_player.stream = generator
	audio_player.play()
	playback = audio_player.get_stream_playback()

func _process(delta):
	if playback.can_push_buffer(buffer_size):
		var samples = generate_audio_samples(buffer_size)
		playback.push_buffer(samples)
		waveform_data = process_audio_data(samples)
		draw_area.queue_redraw()  # Trigger the draw function

func generate_audio_samples(size):
	var samples = PackedVector2Array()
	var phase_increment = (2.0 * PI * frequency) / generator.mix_rate

	# Generate samples as usual, no changes to frequency or sound
	for i in range(size):
		var sample = sin(phase) * amplitude
		samples.append(Vector2(sample, sample))  # Stereo: left and right same
		phase += phase_increment  # Keep the original audio phase

		# Keep phase within 0 to 2π to prevent floating-point errors over time
		if phase > TAU:
			phase -= TAU

	return samples

func process_audio_data(audio_data: PackedVector2Array):
	var processed_data = []
	for sample in audio_data:
		processed_data.append(sample.x)  # Left channel
	return processed_data

func _on_control_draw() -> void:
	if waveform_data.is_empty():
		return

	var width = draw_area.size.x
	var height = draw_area.size.y
	var midline = height / 2
	var scale = height / 2

	var points = []
	# Ensure the wave spans the full width, regardless of wave density
	var total_points = waveform_data.size() * wave_density
	var spacing = total_points / float(width)  # Space the waveform across the width

	for i in range(waveform_data.size()):
		# Adjust the x-axis position so that the wave always spans the width
		var x = (i / spacing)
		x = clamp(x, 0, width - 1)  # Ensure the points stay within bounds

		var y = midline - (waveform_data[i] * scale)
		points.append(Vector2(x, y))

	# Draw the waveform
	draw_area.draw_polyline(points, Color(0, 1, 0), 2)

	# Draw vertical boundary lines at left and right edges
	var boundary_color = Color(0, 1, 0)  # Green color for the boundary line
	draw_area.draw_line(Vector2(0, 0), Vector2(0, height), boundary_color, 2)  # Left boundary line
	draw_area.draw_line(Vector2(width - 1, 0), Vector2(width - 1, height), boundary_color, 2)  # Right boundary line

func _on_frequency_slider_value_changed(value: float) -> void:
	frequency = value  # Update the frequency

func _on_amplitude_slider_value_changed(value: float) -> void:
	amplitude = value  # Update the amplitude

func _on_wave_density_slider_value_changed(value: float) -> void:
	wave_density = value  # Update the wave density (visual only)
