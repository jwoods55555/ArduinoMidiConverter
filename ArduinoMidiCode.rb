require "csv"


#Extract the Midi to Frequency mapping, to a plain Hash.
midiToHzMappingArray = CSV.read("MidiToHzMapping.csv")

midiToHzMapping = Hash.new
midiToHzMappingArray.each do |row|
	midiToHzMapping[row[0]] = row[1]
end

#Have the user input the midi file
puts "Enter the midi file"
midiFile = gets
midiFile.strip!
 `midicsv #{midiFile} > temp.csv`

midiCsv = File.read("temp.csv")
midiCsv.gsub!("\"","") #Replace any quotes, as ruby CSV parser seems to hate them
midiCsv.gsub!(", ",",")  #Replace any ", " with just ",", to make things cleaner

midiFileMappingArray = CSV.parse(midiCsv)


#Extract the notes per track, and put them in a hash of track arrays
trackNumber = 1
trackHash = Hash.new()
midiFileMappingArray.each do |row|
	if row.include?("Start_track")
		trackHash[trackNumber] = []
	end

	if row.include?("Note_on_c")
		trackHash[trackNumber].push(row)
	end	

	if row.include?("End_track")
		puts "end track"
		trackNumber = trackNumber + 1
		puts "new number: " + trackNumber.to_s
	end	
end	







