extends Spatial

var Camera = null
var movespeed = 10.0
	
func _ready():
	Camera = get_node("Camera")
	set_process(true)
	
func _process(delta):
	var text = ""
	
	var acc = Input.get_accelerometer()
	text += "Accelerometer: " + str(acc.x).pad_decimals(2) + "   " + str(acc.y).pad_decimals(2) + "   " + str(acc.z).pad_decimals(2) + "\n"

	var grav = Input.get_gravity()
	text += "Gravity: " + str(grav.x).pad_decimals(2) + "   " + str(grav.y).pad_decimals(2) + "   " + str(grav.z).pad_decimals(2) + "\n"

	var gyro = Input.get_gyroscope()
	text += "Gyroscope: " + str(gyro.x).pad_decimals(2) + "   " + str(gyro.y).pad_decimals(2) + "   " + str(gyro.z).pad_decimals(2) + "\n"

	var magneto = Input.get_magnetometer()
	text += "Magnometer: " + str(magneto.x).pad_decimals(2) + "   " + str(magneto.y).pad_decimals(2) + "   " + str(magneto.z).pad_decimals(2) + "\n"

	# get our user movement from our accelerometer
	var useracc = acc - grav
	text += "Useracc: " + str(useracc.x).pad_decimals(2) + "   " + str(useracc.y).pad_decimals(2) + "   " + str(useracc.z).pad_decimals(2) + "\n"

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
		grav = transform.basis.xform(grav.normalized())
		text += "Adj grav: " + str(grav.x).pad_decimals(2) + "   " + str(grav.y).pad_decimals(2) + "   " + str(grav.z).pad_decimals(2) + "\n"
		
		# get rotation between our gravity and down vector
		var dot = grav.dot(down)
		if ((dot > -1.0) && (dot < 1.0)):
			# axis around which we have this rotation
			var axis = grav.cross(down)
			axis = axis.normalized()

			# adjust for drift
			var rotate = Matrix3()
			rotate = rotate.rotated(axis, -acos(dot))
			transform.basis = rotate * transform.basis

	# And do the same with our magnetometer (doesn't work on my iPhone so this is untested)
	if ((magneto.x != 0.0) || (magneto.y != 0.0) || (magneto.z != 0.0)):
		var north = Vector3(0.0, 0.0, -1.0)
		
		# normalize and transform magneto into world space
		magneto = transform.basis.xform(magneto.normalized())
		text += "Adj magneto: " + str(magneto.x).pad_decimals(2) + "   " + str(magneto.y).pad_decimals(2) + "   " + str(magneto.z).pad_decimals(2) + "\n"
		
		# get rotation between our magneto and north vector
		var dot = magneto.dot(north)
		if ((dot > -1.0) && (dot < 1.0)):
			# axis around which we have this rotation
			var axis = magneto.cross(north)
			axis = axis.normalized()

			# adjust for drift
			var rotate = Matrix3()
			rotate = rotate.rotated(axis, -acos(dot))
			transform.basis = rotate * transform.basis

	# now that we have our orientation correct, let's use our accelerometer to move our camera
	# useracc = transform.basis.xform(useracc)
	# transform.origin += useracc * delta * movespeed

	Camera.set_transform(transform)
	
	get_node("Text").set_text(text)