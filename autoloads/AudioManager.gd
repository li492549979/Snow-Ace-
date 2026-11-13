extends Node
## 中央音效管理器（自动装载）。
## 提供 play(name) / play_throttled(name, min_interval) / play_music(name) / stop_music()。
## 所有音效在首次播放时按需程序化合成（AudioStreamWAV，16-bit/44100/单声道）并缓存。
## BGM 同样程序化合成占位循环（loop_forward）；换真实音频时在 _create_stream()
## 里把对应分支换成 preload(...) 的资源即可，调用点不变。

const POOL_SIZE: int = 8
const SAMPLE_RATE: int = 44100

var _pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0
var _streams: Dictionary = {}        # name -> AudioStreamWAV
var _last_play: Dictionary = {}      # name -> seconds (用于节流)
var _music_player: AudioStreamPlayer = null
var _music_name: String = ""

func _ready() -> void:
	# 暂停时菜单音效/音乐继续混音
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -7.0
	add_child(_music_player)
	# 预合成 BGM（体量远大于单条 SFX），把一次性开销挪到启动而非进关卡瞬间
	_get_stream("stage1")

func play(sfx_name: String) -> void:
	var stream: AudioStreamWAV = _get_stream(sfx_name)
	if stream == null:
		return
	var p: AudioStreamPlayer = _pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	p.stream = stream
	p.play()

func play_throttled(sfx_name: String, min_interval: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	if _last_play.has(sfx_name) and t - _last_play[sfx_name] < min_interval:
		return
	_last_play[sfx_name] = t
	play(sfx_name)

func play_music(music_name: String) -> void:
	# 同曲在播则不重头循环
	if _music_name == music_name and _music_player.playing:
		return
	_music_name = music_name
	_music_player.stream = _get_stream(music_name)
	_music_player.play()

func stop_music() -> void:
	_music_name = ""
	_music_player.stop()

func _get_stream(sfx_name: String) -> AudioStreamWAV:
	if _streams.has(sfx_name):
		return _streams[sfx_name]
	var s: AudioStreamWAV = _create_stream(sfx_name)
	_streams[sfx_name] = s
	return s

func _create_stream(sfx_name: String) -> AudioStreamWAV:
	match sfx_name:
		"shoot":       return _make_tone(900.0, 500.0, 0.07, true, 0.22)
		"charge_fire": return _make_tone(240.0, 80.0, 0.22, true, 0.45)
		"charge":      return _make_tone(320.0, 960.0, 0.14, false, 0.30)
		"laser":       return _make_tone(880.0, 320.0, 0.3, false, 0.3)
		"enemy_shoot": return _make_tone(320.0, 220.0, 0.08, true, 0.16)
		"hit":         return _make_noise(0.06, 0.25, 12.0)
		"explosion":   return _make_noise(0.32, 0.50, 5.0)
		"boss_hit":    return _make_tone(150.0, 90.0, 0.10, true, 0.28)
		"bomb":        return _make_noise(0.60, 0.60, 2.5)
		"player_hit":  return _make_tone(500.0, 80.0, 0.25, false, 0.40)
		"pickup":      return _make_sequence([[600.0, 600.0, 0.06, false], [900.0, 900.0, 0.08, false]], 0.32)
		"powerup":     return _make_sequence([[523.0, 523.0, 0.06, false], [659.0, 659.0, 0.06, false], [784.0, 784.0, 0.06, false], [1047.0, 1047.0, 0.12, false]], 0.36)
		"warning":     return _make_sequence([[440.0, 440.0, 0.12, true], [0.0, 0.0, 0.05, false], [440.0, 440.0, 0.12, true]], 0.35)
		"phase":       return _make_sequence([[300.0, 300.0, 0.08, false], [500.0, 500.0, 0.08, false], [700.0, 700.0, 0.12, false]], 0.38)
		"clear":       return _make_sequence([[523.0, 523.0, 0.10, false], [659.0, 659.0, 0.10, false], [784.0, 784.0, 0.10, false], [1047.0, 1047.0, 0.22, false]], 0.38)
		"over":        return _make_sequence([[440.0, 440.0, 0.14, false], [370.0, 370.0, 0.14, false], [262.0, 262.0, 0.32, false]], 0.40)
		"stage1":      return _make_music_stage1()
		_:             return null

# ---- BGM 占位合成 ----

func _make_music_stage1() -> AudioStreamWAV:
	# 和风小调占位循环（A 羽调式 A-C-D-E-G），旋律方波 + 低音正弦双声部。
	# 音高<=0 表示休止；[频率, 拍数]，132 BPM，共 12 拍约 5.5 秒循环。
	var bpm := 132.0
	var beat := 60.0 / bpm
	var melody: Array = [
		[440.0, 0.5], [523.25, 0.5], [587.33, 0.5], [659.25, 0.5],
		[587.33, 0.5], [523.25, 0.5], [440.0, 1.0],
		[392.0, 0.5], [440.0, 0.5], [523.25, 1.0],
		[440.0, 0.5], [392.0, 0.5], [329.63, 1.0],
		[0.0, 0.5], [329.63, 0.5], [392.0, 0.5], [440.0, 0.5],
		[523.25, 0.5], [587.33, 0.5], [659.25, 1.0],
		[587.33, 0.5], [523.25, 0.5], [587.33, 1.0],
		[659.25, 0.5], [783.99, 0.5], [659.25, 0.5], [587.33, 0.5],
		[523.25, 0.5], [587.33, 0.5], [523.25, 1.0],
		[440.0, 0.5], [392.0, 0.5], [440.0, 0.5], [523.25, 0.5],
		[440.0, 2.0],
	]
	var bass: Array = [
		[110.0, 2.0], [87.31, 2.0], [98.0, 2.0], [82.41, 2.0],
		[110.0, 2.0], [82.41, 1.0], [87.31, 1.0], [110.0, 2.0],
	]
	var m := _render_note_seq(melody, beat, true, 0.09)
	var b := _render_note_seq(bass, beat, false, 0.16)
	var mixed := _mix_streams(m, b)
	var stream := _build_wav(mixed)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = mixed.size() / 2  # 16-bit 单声道：loop 点位单位是帧（2 字节/帧）
	return stream

func _render_note_seq(notes: Array, beat: float, square: bool, volume: float) -> PackedByteArray:
	var data := PackedByteArray()
	for n in notes:
		var freq := float(n[0])
		var dur := float(n[1]) * beat
		if freq <= 0.0:
			var silent := PackedByteArray()
			silent.resize(int(dur * SAMPLE_RATE) * 2)
			data.append_array(silent)
		else:
			data.append_array(_render_tone(freq, freq, dur, square, volume))
	return data

func _mix_streams(a: PackedByteArray, b: PackedByteArray) -> PackedByteArray:
	# 双声部求和（按较短者截齐，防止声部长度不一致）
	var frames := mini(a.size(), b.size()) / 2
	var out := PackedByteArray()
	out.resize(frames * 2)
	for i in frames:
		var sa := _decode_sample16(a, i)
		var sb := _decode_sample16(b, i)
		_write_sample(out, i, sa + sb)
	return out

func _decode_sample16(data: PackedByteArray, frame_index: int) -> int:
	var v := data[frame_index * 2] | (data[frame_index * 2 + 1] << 8)
	return v - 65536 if v >= 32768 else v

# ---- 程序化合成 ----

func _make_tone(freq_start: float, freq_end: float, duration: float, square: bool, volume: float) -> AudioStreamWAV:
	return _build_wav(_render_tone(freq_start, freq_end, duration, square, volume))

func _make_noise(duration: float, volume: float, decay: float) -> AudioStreamWAV:
	var frames := int(duration * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var inv_frames := 1.0 / float(frames) if frames > 0 else 0.0
	for i in frames:
		var t := float(i) * inv_frames
		var env := exp(-decay * t)
		var s := (randf() * 2.0 - 1.0) * env * volume
		_write_sample(data, i, int(s * 32767.0))
	return _build_wav(data)

func _make_sequence(segments: Array, volume: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	for seg in segments:
		var seg_data := _render_tone(float(seg[0]), float(seg[1]), float(seg[2]), bool(seg[3]), volume)
		data.append_array(seg_data)
	return _build_wav(data)

func _render_tone(freq_start: float, freq_end: float, duration: float, square: bool, volume: float) -> PackedByteArray:
	# 频率 <= 0 视作静音段（用于 jingle 里的停顿）
	if freq_start <= 0.0 and freq_end <= 0.0:
		var silent := PackedByteArray()
		silent.resize(int(duration * SAMPLE_RATE) * 2)
		return silent

	var frames := int(duration * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var phase := 0.0
	var inv_frames := 1.0 / float(frames) if frames > 0 else 0.0
	for i in frames:
		var t := float(i) * inv_frames
		phase += (lerpf(freq_start, freq_end, t) / float(SAMPLE_RATE)) * TAU
		var s := sin(phase)
		if square:
			s = 1.0 if s >= 0.0 else -1.0
		# 短促攻击 + 指数衰减包络
		var env := (float(i) / 80.0) if i < 80 else exp(-3.5 * t)
		_write_sample(data, i, int(s * env * volume * 32767.0))
	return data

func _write_sample(data: PackedByteArray, frame_index: int, sample: int) -> void:
	var idx := frame_index * 2
	var clamped := clampi(sample, -32768, 32767)
	data[idx] = clamped & 0xFF
	data[idx + 1] = (clamped >> 8) & 0xFF

func _build_wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
