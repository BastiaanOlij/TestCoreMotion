extends Spatial

var Camera = null
var movespeed = 10.0
	
var accel_samples = Array()

func get_smoothed_acc():
	accel_samples.push_back(Input.get_accelerometer())
	if (accel_samples.size()>5):
		accel_samples.pop_front()

	var total_v = Vector3()	
	for v in accel_samples:
		total_v += v
		
	total_v = total_v / accel_samples.size()
	
	return total_v

func _ready():
	Camera = get_node("Camera")
	set_process(true)
	
func _process(delta):
	var text = ""
	
	# var acc = Input.get_accelerometer()
	var acc = get_smoothed_acc()
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
	rotate = rotate.rotated(Vector3(1.0, 0.0, 0.0), -gyro.x * delta)
	rotate = rotate.rotated(Vector3(0.0, 1.0, 0.0), -gyro.y * delta)
	rotate = rotate.rotated(Vector3(0.0, 0.0, 1.0), -gyro.z * delta)
	transform.basis = rotate * transform.basis
	
	# what is down according to our current transform?
	var down = Vector3(0.0, -1.0, 0.0)
	down = transform.basis.xform_inv(down)

	# output that, this should be in line with our accelerometer
	text += "Down: " + str(down.x).pad_decimals(2) + "   " + str(down.y).pad_decimals(2) + "   " + str(down.z).pad_decimals(2) + "\n"

	# should use our down vector and compare it to our gravity to compensate for drift.
	if ((grav.x != 0.0) || (grav.y != 0.0) || (grav.z != 0.0)):
		# normalize gravity
		grav = grav.normalized()
		text += "|Grav|: " + str(grav.x).pad_decimals(2) + "   " + str(grav.y).pad_decimals(2) + "   " + str(grav.z).pad_decimals(2) + "\n"
		
		# get rotation between our gravity and down vector
		var dot = grav.dot(down)
		if ((dot > -1.0) && (dot < 1.0)):
			# axis around which we have this rotation
			var axis = grav.cross(down)
			axis = axis.normalized()
		
			text += "Axis: " + str(axis.x).pad_decimals(2) + "   " + str(axis.y).pad_decimals(2) + "   " + str(axis.z).pad_decimals(2) + "\n"
			text += "Dot: " + str(dot).pad_decimals(2) + ", Angle:   " + str(acos(dot)).pad_decimals(2) + "\n"

			# adjust for drift
			#var rotate = Matrix3()
			#rotate = rotate.rotated(axis, -acos(dot))
			#transform.basis = rotate * transform.basis

	# if I ever get a device with a working magnetometer we can use that to compensate from rotation drift

	# now that we have our orientation correct, let's use our accelerometer to move our camera
	# useracc = transform.basis.xform(useracc)
	# transform.origin += useracc * delta * movespeed

	Camera.set_transform(transform)
	
	get_node("Text").set_text(text)