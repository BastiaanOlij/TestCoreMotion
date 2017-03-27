# Maths.gd - started 7-18-2016 by masonjoyers
# holds a bunch on constants and some helper functions

extends Node

var oneOvrPI = 1/PI
var PIovrEight = PI/8 # 22.5 degrees
var PIovrFour = PI/4 # 45 degrees
var ThreePIovrEight = 3 * (PI/8) # 67.5 degrees
var PIovrTwo = PI/2 # 90 degrees
var FivePIovrEight = 5 * (PI/8) # 112.5 degrees
var ThreePIovrFour = 3 * (PI/4) # 135 degrees
var SevenPIovrEight = 7 * (PI/8) # 157.5 degrees
var NinePIovrEight = 9 * (PI/8) # 202.5 degrees
var FivePIovrFour = 5 * (PI/4) # 225 degrees
var ElevenPIovrEight = 11 * (PI/8) # 247.5
var ThreePIovrTwo = 3 * (PI/2) # 270 degrees
var ThrteenPIovrEight = 13 * (PI/8) # 292.5 degrees
var SevenPIovrFour = 7 * (PI/4) # 315 degrees
var FivteenPIovrEight = 15 * (PI/8) # 337.5 degrees
var TwoPI = PI * 2 # 360 degrees

var PIovrOneEighty = PI/180 # degrees to radians
var OneEightyOvrPI = 180/PI # radians to degrees

var debug_wrap_angle = false
var debug_wrap_angle_v3 = false
var debug_set_one_decimal = false
var debug_set_one_decimal_v3 = false
var debug_set_two_decimals = false
var debug_set_two_decimals_v3 = false
var debug_set_three_decimals = false
var debug_set_three_decimals_v3 = false
var debug_get_abs_difference = false
var debug_get_abs_difference_v3 = false
var debug_sort_min_max = false
var debug_compliment_v3 = false
var debug_low_pass_v3 = false
var debug_scrub_input_v3_d1 = false
var debug_scrub_input_v3_d2 = false
var debug_scrub_input_v3_d3 = false

func wrap_angle(angle):
	if angle < 0:
		angle = angle + TwoPI
		wrap_angle( angle )
	elif angle > TwoPI:
		angle = angle - TwoPI
		wrap_angle( angle )

	return angle

func wrap_angle_v3(angles):
	angles.x = wrap_angle( angles.x )
	angles.y = wrap_angle( angles.y )
	angles.z = wrap_angle( angles.z )
	return angles

func set_one_decimal(data):
	data = data * 10
	data = floor( data )
	data = data / 10
	return data

func set_one_decimal_v3(data):
	data.x = set_one_decimal( data.x )
	data.y = set_one_decimal( data.y )
	data.z = set_one_decimal( data.z )
	return data

func set_two_decimals(data):
	data = data * 100
	data = floor( data )
	data = data / 100
	return data

func set_two_decimals_v3(data):
	data.x = set_two_decimals( data.x )
	data.y = set_two_decimals( data.y )
	data.z = set_two_decimals( data.z )
	return data

func set_three_decimals(data):
	data = data * 1000
	data = floor( data )
	data = data / 1000
	return data

func set_three_decimals_v3(data):
	data.x = set_three_decimals( data.x )
	data.y = set_three_decimals( data.y )
	data.z = set_three_decimals( data.z )
	return data

func get_abs_difference(term1, term2):
	var result = abs( abs(term1) - abs(term2) )
	return result

func get_abs_difference_v3(term1, term2):
	var result = Vector3(0, 0, 0)
	result.x = get_abs_difference( term1.x, term2.x )
	result.y = get_abs_difference( term1.y, term2.y )
	result.z = get_abs_difference( term1.z, term2.z )
	return result

func sort_min_max(term1, term2):
	if term1 > term2:
		var tmp = term1
		term1 = term2
		term2 = tmp

	var return_value = [term1, term2]
	return return_value

func compliment_v3( data, last_data, factor ):
	data.x = data.x * factor + last_data.x * (1 - factor)
	data.y = data.y * factor + last_data.y * (1 - factor)
	data.z = data.z * factor + last_data.z * (1 - factor)
	
	return data

func low_pass_v3( data, last_data, factor ):
	data.x = data.x + ( factor * ( last_data.x - data.x ) )
	data.y = data.y + ( factor * ( last_data.y - data.y ) )
	data.z = data.z + ( factor * ( last_data.z - data.z ) )
	
	return data

func high_pass_v3( data, last_data, factor ):
	data.x = data.x - ( factor * ( last_data.x + data.x ) )
	data.y = data.y - ( factor * ( last_data.y + data.y ) )
	data.z = data.z - ( factor * ( last_data.z + data.z ) )
	
	return data

func low_pass_m3( data, last_data, factor ):
	data.x = low_pass( data.x, last_data.x, factor )
	data.y = low_pass( data.y, last_data.y, factor )
	data.z = low_pass( data.z, last_data.z, factor )
	
	return data

func scrub_input_v3_d1( data, last_data, factor ):
	data = set_one_decimal_v3( data )
	data = low_pass_v3( data, last_data, factor )
	#data = wrap_angle_v3( data )
	return data

func scrub_input_v3_d2( data, last_data, factor ):
	data = set_two_decimals_v3( data )
	data = low_pass_v3( data, last_data, factor )
	#data = wrap_angle_v3( data )
	return data

func scrub_input_v3_d3( data, last_data, factor ):
	data = set_three_decimals_v3( data )
	data = low_pass_v3( data, last_data, factor )
	#data = wrap_angle_v3( data )
	return data 


func euler_to_quat( pitch, yaw, roll ):
	var cos_yaw_ovr_2 = cos( yaw ) / 2
	var sin_yaw_ovr_2 = sin( yaw ) / 2
	var cos_roll_ovr_2 = cos( roll ) / 2
	var sin_roll_ovr_2 = sin( roll ) / 2
	var cos_pitch_ovr_2 = cos( pitch ) / 2
	var sin_pitch_ovr_2 = sin( pitch ) / 2
	
	var w = cos_yaw_ovr_2 * cos_roll_ovr_2 * cos_pitch_ovr_2 + \
	    sin_yaw_ovr_2 * sin_roll_ovr_2 * sin_pitch_ovr_2
	var x = cos_yaw_ovr_2 * sin_roll_ovr_2 * cos_pitch_ovr_2 - \
	    sin_yaw_ovr_2 * cos_roll_ovr_2 * sin_pitch_ovr_2
	var y = cos_yaw_ovr_2 * cos_roll_ovr_2 * sin_pitch_ovr_2 + \
	    sin_yaw_ovr_2 * sin_roll_ovr_2 * cos_pitch_ovr_2
	var z = sin_yaw_ovr_2 * cos_roll_ovr_2 * cos_pitch_ovr_2 - \
	    cos_yaw_ovr_2 * sin_roll_ovr_2 * sin_pitch_ovr_2
	
	var quat = Quat( x, y, z, w )
	quat = quat.normalized()
	return quat

func get_current_xyz_rotation_q( quat ):
	var q_y_squared = quat.y * quat.y
	
	# x-axis
	var pitch_term1 = 2 * ( quat.w * quat.x + quat.y * quat.z )
	var pitch_term2 = 1 - ( 2 * ( quat.x * quat.x + q_y_squared ) )
	
	var pitch = atan2( pitch_term1, pitch_term2 )
	
	# y-axis
	var yaw_term = 2 * ( quat.w * quat.y - quat.z * quat.x )
	if yaw_term > 1:
		yaw_term = 1
	elif yaw_term < -1:
		yaw_term = -1
	
	var yaw = asin( yaw_term )
	
	# z-axis
	var roll_term1 = 2 * ( quat.w * quat.z + quat.x * quat.y )
	var roll_term2 = 1 - 2 * ( q_y_squared + quat.z * quat.z )
	
	var roll = atan2( roll_term1, roll_term2 )
	
	var rotation = Vector3( pitch, yaw, roll )
	
	return rotation