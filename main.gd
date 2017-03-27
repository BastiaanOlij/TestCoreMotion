extends Spatial

var Camera = null
var movespeed = 10.0

var frame_counter = 0
var next_mag_min = Vector3( 10000, 10000, 10000 )
var next_mag_max = Vector3 ( -10000, -10000, -10000 )
var current_mag_min = Vector3( 0, 0, 0 )
var current_mag_max = Vector3( 0, 0, 0 )
var last_acc = Vector3()
var acc_lpf = 0.2
var last_magneto = Vector3()
var magneto_lpf = 0.3

	
func _ready():
	Camera = get_node("Camera")
	set_process(true)
	
func _process(delta):
	var text = ""
	
	var acc = Input.get_accelerometer()
	acc = Maths.scrub_input_v3_d3( acc, last_acc, acc_lpf )
	last_acc = acc
	get_node( "Debug1" ).set_text( "acc: " + str( acc ) )
	var magneto = Input.get_magnetometer()
	magneto = Maths.scrub_input_v3_d2( magneto, last_magneto, magneto_lpf )
	magneto = scale_mag_v3( magneto )
	get_node( "Debug2" ).set_text( "mag: " + str( magneto ) )
	var gyro = Input.get_gyroscope()
	get_node( "Debug3" ).set_text( "gyro: " + str( gyro ) )
	#var grav = Input.get_gravity()
	#get_node( "Debug4" ).set_text( "grav: " + str( grav ) )
	#if ((grav.x == 0.0) && (grav.y == 0.0) && (grav.z == 0.0)):
		# No gravity? just use accelerometer, maybe one day add some math here to do something better
	var grav = acc

	if OS.get_name() == "Android":
		# x and y axis are inverted on android
		acc = Vector3(-acc.x, acc.y, -acc.z)
		magneto = Vector3(-magneto.x, magneto.y, -magneto.z)
		gyro = Vector3(-gyro.x, gyro.y, -gyro.z)
		grav = Vector3(-grav.x, grav.y, -grav.z)

	var useracc = acc - grav

	text += "Accelerometer: " + str(acc.x).pad_decimals(2) + "   " + str(acc.y).pad_decimals(2) + "   " + str(acc.z).pad_decimals(2)
	acc = acc.normalized()
	text += " (" + str(acc.x).pad_decimals(2) + "   " + str(acc.y).pad_decimals(2) + "   " + str(acc.z).pad_decimals(2) +")"
	text += "\n"

	text += "Gravity: " + str(grav.x).pad_decimals(2) + "   " + str(grav.y).pad_decimals(2) + "   " + str(grav.z).pad_decimals(2)
	grav = grav.normalized()
	text += " (" + str(grav.x).pad_decimals(2) + "   " + str(grav.y).pad_decimals(2) + "   " + str(grav.z).pad_decimals(2) + ")"
	text += "\n"

	text += "Gyroscope: " + str(gyro.x).pad_decimals(2) + "   " + str(gyro.y).pad_decimals(2) + "   " + str(gyro.z).pad_decimals(2) + "\n"

	text += "Magnometer: " + str(magneto.x).pad_decimals(2) + "   " + str(magneto.y).pad_decimals(2) + "   " + str(magneto.z).pad_decimals(2)
	magneto = magneto.normalized()
	text += " (" + str(magneto.x).pad_decimals(2) + "   " + str(magneto.y).pad_decimals(2) + "   " + str(magneto.z).pad_decimals(2) + ")"
	text += "\n"

	# get our user movement from our accelerometer
	text += "Useracc: " + str(useracc.x).pad_decimals(2) + "   " + str(useracc.y).pad_decimals(2) + "   " + str(useracc.z).pad_decimals(2)
	useracc = useracc.normalized()
	text += " (" + str(useracc.x).pad_decimals(2) + "   " + str(useracc.y).pad_decimals(2) + "   " + str(useracc.z).pad_decimals(2) + ")"
	text += "\n"

	# get our current camera transform
	var transform = Camera.get_transform()
	
	# rotate our cube with our new gyro data
	var rotate = Matrix3()
	rotate = rotate.rotated(transform.basis.x, -gyro.x * delta)
	rotate = rotate.rotated(transform.basis.y, -gyro.y * delta)
	rotate = rotate.rotated(transform.basis.z, -gyro.z * delta)
	transform.basis = rotate * transform.basis
	
	# should use our down vector and compare it to our gravity to compensate for drift.
	if ((grav.x != 0.0) || (grav.y != 0.0) || (grav.z != 0.0)):
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
			rotate = rotate.rotated(axis, -acos(dot) * 0.2) # *0.2 to dampen it
			transform.basis = rotate * transform.basis

	# And do something similar with our magnetometer
	if ((magneto.x != 0.0) || (magneto.y != 0.0) || (magneto.z != 0.0)):
		# turns out the magnetometer is not horizon aligned so we need to combine it with our gravity
		if ((grav.x != 0.0) || (grav.y != 0.0) || (grav.z != 0.0)):
			var magneto_east = grav.cross(magneto) # or is this west?, but should be horizon aligned now
			magneto_east = magneto_east.normalized()
			magneto = grav.cross(magneto_east) # and now we have a horizon aligned north
			magneto = magneto.normalized()
		
		var north = Vector3(0.0, 0.0, 1.0)
		
		# normalize and transform magneto into world space
		var magneto_adj = transform.basis.xform(magneto)
		text += "Adj magneto: " + str(magneto_adj.x).pad_decimals(2) + "   " + str(magneto_adj.y).pad_decimals(2) + "   " + str(magneto_adj.z).pad_decimals(2) + "\n"
		
		# get rotation between our magneto and north vector
		var dot = magneto_adj.dot(north)
		if ((dot > -1.0) && (dot < 1.0)):
			# axis around which we have this rotation
			var axis = magneto_adj.cross(north)
			axis = axis.normalized()

			# adjust for drift
			var rotate = Matrix3()
			rotate = rotate.rotated(axis, -acos(dot) * 0.2) # *0.2 to dampen it
			transform.basis = rotate * transform.basis

	# now that we have our orientation correct, let's use our accelerometer to move our camera, this is not accurate enough... alas...
	# useracc = transform.basis.xform(useracc)
	# transform.origin += useracc * delta * movespeed
	if frame_counter > 20:
		current_mag_min = next_mag_min
		current_mag_max = next_mag_max
		frame_counter = 0
	else:
		frame_counter += 1

	Camera.set_transform(transform)
	
	get_node("Text").set_text(text)
	
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
