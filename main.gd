extends Spatial

var Camera = null
var movespeed = 10.0
	
func _ready():
	Camera = get_node("Camera")
	set_process(true)
	
func _process(delta):
	var text = ""
	
	var acc = Input.get_accelerometer()
	var grav = Input.get_gravity()
	if ((grav.x == 0.0) && (grav.y == 0.0) && (grav.z == 0.0)):
		# No gravity? just use accelerometer, maybe one day add some math here to do something better
		grav = acc

	var useracc = acc - grav

	text += "Accelerometer: " + str(acc.x).pad_decimals(2) + "   " + str(acc.y).pad_decimals(2) + "   " + str(acc.z).pad_decimals(2)
	acc = acc.normalized()
	text += " (" + str(acc.x).pad_decimals(2) + "   " + str(acc.y).pad_decimals(2) + "   " + str(acc.z).pad_decimals(2) +")"
	text += "\n"

	text += "Gravity: " + str(grav.x).pad_decimals(2) + "   " + str(grav.y).pad_decimals(2) + "   " + str(grav.z).pad_decimals(2)
	grav = grav.normalized()
	text += " (" + str(grav.x).pad_decimals(2) + "   " + str(grav.y).pad_decimals(2) + "   " + str(grav.z).pad_decimals(2) + ")"
	text += "\n"

	var gyro = Input.get_gyroscope()
	text += "Gyroscope: " + str(gyro.x).pad_decimals(2) + "   " + str(gyro.y).pad_decimals(2) + "   " + str(gyro.z).pad_decimals(2) + "\n"

	var magneto = Input.get_magnetometer()
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

	Camera.set_transform(transform)
	
	get_node("Text").set_text(text)