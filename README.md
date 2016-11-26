# TestCoreMotion
Test project to test the core motion enhancements I added to Godot

Note that in order to use this you'll need:
https://github.com/godotengine/godot/pull/7127

In theory this example will work on Android as well however the current Android implementation does not provide the gravity vector, only the unprocessed accelerometer data. 
Android can easily be enhanced to provide the gravity vector by implementing TYPE_GRAVITY but lacking an Android device to work with I haven't been able to implement this.