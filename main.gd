extends Spatial

var Camera = null
var movespeed = 10.0

var hasgyro = false

var frame_counter = 0
var next_mag_min = Vector3( 10000, 10000, 10000 )
var next_mag_max = Vector3 ( -10000, -10000, -10000 )
var current_mag_min = Vector3( 0, 0, 0 )
var current_mag_max = Vector3( 0, 0, 0 )
var last_acc = Vector3()
var acc_lpf = 0.2
var last_magneto = Vector3()
var magneto_lpf = 0.3
var acc_mag_slerp = 0.1

var threshold = 0.1
	
func _ready():
	Camera = get_node("Camera")
	set_process(true)
	
func _process(delta):
	var text = ""
	
	var acc = Input.get_accelerometer()
	acc = Maths.scrub_input_v3_d3( acc, last_acc, acc_lpf )
	last_acc = acc
	
	var magneto = Input.get_magnetometer()
	magneto = Maths.scrub_input_v3_d2( magneto, last_magneto, magneto_lpf )
	magneto = scale_mag_v3( magneto )
	
	var gyro = Input.get_gyroscope()
	if gyro.length() > threshold:
		# when we are not moving our phone, we're not getting any readings, so once we've had readings, we know we have a gyro
		hasgyro = true
	
	# Gravity is supported for both Android and iOS since Godot 2.1.3, if your device does not support it, it will be 0, and we'll copy the accelerometer
	# no need to scrub btw, this is already a vector the OS has corrected
	var grav = Input.get_gravity()
	if grav.length() <= threshold:
		# No gravity? just use accelerometer, maybe one day add some math here to do something better
		grav = acc
	
	var hasgrav = grav.length() > threshold
	var hasmag = magneto.length() > threshold

	if OS.get_name() == "Android":
		# x and y axis are inverted on android
		acc = Vector3(-acc.x, acc.y, -acc.z)
		magneto = Vector3(-magneto.x, magneto.y, -magneto.z)
		gyro = Vector3(-gyro.x, gyro.y, -gyro.z)
		grav = Vector3(-grav.x, grav.y, -grav.z)

	var useracc = acc - grav

	if hasgrav:
		text += "Accelerometer: " + str(acc.x).pad_decimals(2) + "   " + str(acc.y).pad_decimals(2) + "   " + str(acc.z).pad_decimals(2)
		acc = acc.normalized()
		text += " (" + str(acc.x).pad_decimals(2) + "   " + str(acc.y).pad_decimals(2) + "   " + str(acc.z).pad_decimals(2) +")"
		text += "\n"

		text += "Gravity: " + str(grav.x).pad_decimals(2) + "   " + str(grav.y).pad_decimals(2) + "   " + str(grav.z).pad_decimals(2)
		grav = grav.normalized()
		text += " (" + str(grav.x).pad_decimals(2) + "   " + str(grav.y).pad_decimals(2) + "   " + str(grav.z).pad_decimals(2) + ")"
		text += "\n"

		# get our user movement from our accelerometer
		text += "Useracc: " + str(useracc.x).pad_decimals(2) + "   " + str(useracc.y).pad_decimals(2) + "   " + str(useracc.z).pad_decimals(2)
		useracc = useracc.normalized()
		text += " (" + str(useracc.x).pad_decimals(2) + "   " + str(useracc.y).pad_decimals(2) + "   " + str(useracc.z).pad_decimals(2) + ")"
		text += "\n"
	else:
		text += "No accelerometer data\n"

	if hasgyro:
		text += "Gyroscope: " + str(gyro.x).pad_decimals(2) + "   " + str(gyro.y).pad_decimals(2) + "   " + str(gyro.z).pad_decimals(2) + "\n"
	else:
		text += "No gyroscope data\n"

	if hasmag:
		text += "Magnetometer: " + str(magneto.x).pad_decimals(2) + "   " + str(magneto.y).pad_decimals(2) + "   " + str(magneto.z).pad_decimals(2)
		magneto = magneto.normalized()
		text += " (" + str(magneto.x).pad_decimals(2) + "   " + str(magneto.y).pad_decimals(2) + "   " + str(magneto.z).pad_decimals(2) + ")"
		text += "\n"
	else:
		text += "No magnetometer data\n"

	# get our current camera transform
	var transform = Camera.get_transform()

	if hasgyro:
		text += "Adjusting by gyro\n"
		
		# rotate our cube with our new gyro data
		var rotate = Matrix3()
		rotate = rotate.rotated(transform.basis.x, -gyro.x * delta)
		rotate = rotate.rotated(transform.basis.y, -gyro.y * delta)
		rotate = rotate.rotated(transform.basis.z, -gyro.z * delta)
		transform.basis = rotate * transform.basis
	
	if hasgrav&&hasmag:
		text += "Adjusting by accelerometer/magnetometer\n"
		# slerp the acc_mag_m3 against the transform to stop it from jittering 
		# the easiest way to do this is convert to Quat -masonjoyers

		var transform_quat = Quat( transform.basis )
		var acc_mag_quat = Quat( combine_acc_mag(grav, magneto) )
		transform_quat = transform_quat.slerp( acc_mag_quat, acc_mag_slerp )
		transform.basis = Matrix3( transform_quat )
	elif hasgrav:
		text += "Adjusting by accelerometer\n"
		# use our down vector and compare it to our gravity to compensate for drift.
		var down = Vector3(0.0, -1.0, 0.0)
		
		# normalize and transform gravity into world space
		# note that our positioning matrix will be inversed to create our view matrix, so the inverse of that is our positioning matrix
		# hence we can do:
		var grav_adj = transform.basis.xform(grav)
		text += "Adj grav: " + str(grav_adj.x).pad_decimals(2) + "   " + str(grav_adj.y).pad_decimals(2) + "   " + str(grav_adj.z).pad_decimals(2) + "\n"
		
		# get rotation between our gravity and down vector
		var dot = grav_adj.dot(down)
		if ((dot > -1.0) && (dot < 1.0)):
			# axis around which we have this rotation
			var axis = grav_adj.cross(down)
			axis = axis.normalized()

			# adjust for drift
			var rotate = Matrix3()
			rotate = rotate.rotated(axis, -acos(dot) * 0.2)
			transform.basis = rotate * transform.basis

	if hasmag:
		# update our magnetometer adjustment every 20 frames
		if frame_counter > 20:
			current_mag_min = next_mag_min
			current_mag_max = next_mag_max
			frame_counter = 0
		else:
			# just copy for now...
			frame_counter += 1

	Camera.set_transform(transform)
	
	get_node("Text").set_text(text)
	
func combine_acc_mag(grav, magneto):
	# yup, stock standard cross product solution...
	var up = -grav
	var magneto_east = up.cross(magneto) # or is this west?, but should be horizon aligned now
	magneto_east = magneto_east.normalized()
	magneto = up.cross(magneto_east) # and now we have a horizon aligned north
	magneto = magneto.normalized()

	# We use our gravity and magnetometer vectors to construct our matrix
	var acc_mag_m3 = Matrix3()
	acc_mag_m3.x = -magneto_east
	acc_mag_m3.y = up
	acc_mag_m3.z = magneto
	
	# we need this transposed...
	acc_mag_m3 = acc_mag_m3.transposed()
	
	return acc_mag_m3
	
func scale_mag_v3( mag_raw ):
	if mag_raw.x > next_mag_max.x:
		next_mag_max.x = mag_raw.x
	if mag_raw.y > next_mag_max.y:
		next_mag_max.y = mag_raw.y
	if mag_raw.z > next_mag_max.z:
		next_mag_max.z = mag_raw.z
	
	if mag_raw.x < next_mag_min.x:
		next_mag_min.x = mag_raw.x
	if mag_raw.y < next_mag_min.y:
		next_mag_min.y = mag_raw.y
	if mag_raw.z < next_mag_min.z:
		next_mag_min.z = mag_raw.z
	
	var mag_scaled = mag_raw
	
	if !( current_mag_max.x - current_mag_min.x ):
		mag_raw.x -= ( current_mag_min.x + current_mag_max.x ) / 2
		mag_scaled.x = ( mag_raw.x - current_mag_min.x ) / ( ( current_mag_max.x - current_mag_min.x ) * 2 - 1 )
	
	if !( current_mag_max.y - current_mag_min.y ):
		mag_raw.y -= ( current_mag_min.y + current_mag_max.y ) / 2
		mag_scaled.y = ( mag_raw.y - current_mag_min.y ) / ( ( current_mag_max.y - current_mag_min.y ) * 2 - 1 )
	
	if !( current_mag_max.z - current_mag_min.z ):
		mag_raw.z -= ( current_mag_min.z + current_mag_max.z ) / 2
		mag_scaled.z = ( mag_raw.z - current_mag_min.z ) / ( ( current_mag_max.z - current_mag_min.z ) * 2 - 1 )
	
	return mag_scaled
