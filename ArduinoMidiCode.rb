require "csv"
require 'bigdecimal/util'


#Extract the Midi to Frequency mapping, to a plain Hash.
midiToHzMappingArray = CSV.read("MidiToHzMapping.csv")

midiToHzMapping = Hash.new
midiToHzMappingArray.each do |row|
	midiToHzMapping[row[0]] = row[1]
end


#Have the user input the midi file
puts "Enter the midi file"
midiFile = gets.strip
midiFile.strip!
 `midicsv #{midiFile} > temp.csv`

midiCsv = File.read("temp.csv")
midiCsv.gsub!("\"","") #Replace any quotes, as ruby CSV parser seems to hate them
midiCsv.gsub!(", ",",")  #Replace any ", " with just ",", to make things cleaner

midiFileMappingArray = CSV.parse(midiCsv)


#Extract the notes per track, and put them in a hash of track arrays.  Also get the timing information.
trackName = ""
trackHash = Hash.new() # TrackName -> [row] 
trackInfo = Hash.new() # TrackName -> ["Tempo" => int, "Num" => int, "Denom" => int, "Click" => int, "NotesQ" => int ]
midiFileMappingArray.each do |row|
	if "Title_t" == row[2] 
		trackName = row[3]
		trackHash[trackName] = []
	end	

	if "Tempo" == row[2] 
		if trackInfo[trackName] == nil
			trackInfo[trackName] = Hash.new()
		end	

		trackInfo[trackName]["Tempo"] = row[3].to_i
	end	

	if "Time_signature" == row[2]
		if trackInfo[trackName] == nil
			trackInfo[trackName] = Hash.new()
		end	

		trackInfo[trackName]["Num"] = row[3].to_d
		trackInfo[trackName]["Denom"] = row[4].to_d
		trackInfo[trackName]["Click"] = row[5].to_d
		trackInfo[trackName]["NotesQ"] = row[6].to_d
	end	

	if row.include?("Note_on_c") || row.include?("Note_off_c")
		trackHash[trackName].push(row)
	end	
end	


#User must input OUTPUT pin number
puts "Enter the Arduino OUTPUT pin number you are using"
outputPin = gets.strip

sketchFile = File.read("ArduinoCodeTemplate.sketch")
sketchFile.gsub!("$BUZZER$","#{outputPin}")

#Get the track the user wants to
puts "Enter the number of the track you wish to play"
i = 0
#The complicated part: converting the midi to code
trackHash.keys.each do |key| 
   puts "#{i.to_s} - #{key}"
   i = i + 1 
end

trackHashToUse = gets.strip


#Turn the track into Arduino Code
theTrack = trackHash[trackHash.keys[trackHashToUse.to_i]]
theTrackInfo =  trackInfo[trackInfo.keys[trackHashToUse.to_i]]
code = ""


=begin
The math formula, also the hardest part to figure out from documentation.  It could very well be wrong... but it seems to line up

60,000,000/Tempo = quarternotesPerMinute
ticksPerMinute = quarternotesPerMinute * Click
ticksPerMillisecond = ticksPerMinute/60000
ticksTimeInMilliseconds = 1/ticksPerMillisecond

E.g, for a Castlevania track track of about 30 seconds:

60,000,000/465116 = 129 quarternotes per minute

129 quarternotes per minute * 96 = 12,384.
***********************
6136 ticks for Castlevania  / 12,384 = 0.495 * 60 seconds = 29.7 s	
=end
quarternotesPerMinute = 60000000/theTrackInfo["Tempo"]
ticksPerMinute = quarternotesPerMinute * theTrackInfo["Click"]
ticksPerMillisecond = ticksPerMinute/60000
ticksTimeMillisecond = 1/ticksPerMillisecond


offTime = 0
while( i < theTrack.size-1)
	#Get the on and off rows to figure out play time
	on = theTrack[i]
	off = theTrack[i+1]

	onTime = on[1]
	delay = ((onTime.to_d * ticksTimeMillisecond) - (offTime.to_d * ticksTimeMillisecond)).to_s(' F')

	code = code + "  delay(#{delay.to_s})\n"

	#puts on
	#puts off 
	duration = ((off[1].to_d * ticksTimeMillisecond) - (on[1].to_d * ticksTimeMillisecond)).to_s(' F')
	midiNote = on[4]
	frequency = midiToHzMapping[midiNote]

	code = code + "  tone(#{outputPin}, #{frequency}, #{duration.to_s})\n"
	code = code + "  noTone(#{outputPin})\n"
	offTime = off[1]
	i = i + 2
end

sketchFile.gsub!("$CODE$","#{code}")
puts sketchFile

outputFile = File.new("Music.sketch","w+")
outputFile.puts(sketchFile)
outputFile.close

=begin
2, 0, Note_on_c, 0, 74, 127
2, 16, Note_off_c, 0, 74, 64
2, 24, Note_on_c, 0, 74, 127
2, 40, Note_off_c, 0, 74, 64
=end


=begin
	
  tone(buzzer, 300); // Send 1KHz sound signal...
  delay(1000);        // ...for 1 sec
  noTone(buzzer);     // Stop sound...
  delay(1000);        // ...for 1sec
	
=end








#sketchFile.gsub!("$CODE$","#{arduinoCode}")





=begin
2, 0, Note_on_c, 0, 74, 127
2, 16, Note_off_c, 0, 74, 64
2, 24, Note_on_c, 0, 74, 127
2, 40, Note_off_c, 0, 74, 64
2, 72, Note_on_c, 0, 72, 127
2, 88, Note_off_c, 0, 72, 64

2, 0, Time_signature, 4, 2, 96, 8
2, 0, Tempo, 465116


Track, Time, Time_signature, Num, Denom, Click, NotesQ
The time signature, metronome click rate, and number of 32nd notes per MIDI quarter note (24 MIDI clock times) are given by the numeric arguments. Num gives the numerator of the time signature as specified on sheet music. Denom specifies the denominator as a negative power of two, for example 2 for a quarter note, 3 for an eighth note, etc. Click gives the number of MIDI clocks per metronome click, and NotesQ the number of 32nd notes in the nominal MIDI quarter note time of 24 clocks (8 for the default MIDI quarter note definition).

Num = 4
Denom = 2
Click = 96
NotesQ = 8

60,000,000/465116 = 129 quarternotes per minute

129 quarternotes per minute * 96 = 12,384.
***********************
6136 ticks for Castlevania  / 12,384 = 0.495 * 60 seconds = 29.7 s
***********************
16 / 12,384


Track, Time, Tempo, Number
The tempo is specified as the Number of microseconds per quarter note, between 1 and 16777215. A value of 500000 corresponds to 120 quarter notes (“beats”) per minute. To convert beats per minute to a Tempo value, take the quotient from dividing 60,000,000 by the beats per minute.


There are 24 MIDI Clocks in every quarter note. 

Click/Num
96/4 = 24 quarter beats

Tempo/60,000,000
60,000,000/465116 =  129 quarter notes 

129 * 24 midinotes = 3096.

3096 = 1 minute
16/3096 = 0.31 seconds


Vampire Killer = 30 seconds and 5968/24 = 248


16/24 = 0.6666 quarter note



 microseconds per tick = microseconds per quarter note / ticks per quarter note




=end