Welcome to the Arduinio Midi converter tool!

In this project, I've created a script that can convert midi files into Arduino code, for the Arduino to output one channel of music through a piezo!

You'll need:
  - command line tool midicsv
  - Ruby 2.7.*
  - Arduino Uno (or something compatible with Arduino sketch files)

For the Ardunio, you simply need to wire up a Piezo from any of the digital out pins, and ensure it goes to the piezo, and then a ground wire from the piezo to the ground.

To run:
  - ruby ArduinoMidiCode.rb

You'll be prompted to enter:
  - Enter the midi file
  - Enter the Arduino OUTPUT pin number you are using 
  - Enter the number of the track you wish to play

It should produce:
  - A sketch file called music.sketch.   Copy and paste the code into your Arduino IDE, and upload to it!


This might not work on every midi file out there, as I found some were missing note_off_c notations, or had the same Track Title for every track. 