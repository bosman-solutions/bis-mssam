' MS Sam WAV File Generator
' Reads mssam_training_corpus.txt and generates numbered WAV files
' Each line becomes a separate audio file

Option Explicit

' === CONFIGURATION ===
Const INPUT_FILE = "mssam_training_corpus.txt"
Const OUTPUT_FOLDER = "wav_output"

' === MAIN SCRIPT ===
Dim fso, inputFile, textStream, lineNumber, currentLine
Dim sapi, fileStream, outputPath, paddedNumber

' Create filesystem object
Set fso = CreateObject("Scripting.FileSystemObject")

' Create output folder if it doesn't exist
If Not fso.FolderExists(OUTPUT_FOLDER) Then
    fso.CreateFolder(OUTPUT_FOLDER)
End If

' Create SAPI voice object
Set sapi = CreateObject("SAPI.SpVoice")

' Set voice to Microsoft Sam (voice index 0 is usually Sam)
' If this doesn't work, we can enumerate voices
Set sapi.Voice = sapi.GetVoices.Item(0)

' Open input file for reading
Set inputFile = fso.GetFile(INPUT_FILE)
Set textStream = inputFile.OpenAsTextStream(1) ' 1 = ForReading

lineNumber = 0

' Process each line
WScript.Echo "Starting WAV generation..."
WScript.Echo "Reading from: " & INPUT_FILE
WScript.Echo "Output folder: " & OUTPUT_FOLDER
WScript.Echo ""

Do While Not textStream.AtEndOfStream
    ' Read current line
    currentLine = textStream.ReadLine
    
    ' Skip empty lines
    If Len(Trim(currentLine)) > 0 Then
        lineNumber = lineNumber + 1
        
        ' Create padded number (001, 002, etc.)
        paddedNumber = Right("000" & lineNumber, 3)
        
        ' Build output path
        outputPath = OUTPUT_FOLDER & "\" & paddedNumber & ".wav"
        
        ' Create file stream for WAV output
        Set fileStream = CreateObject("SAPI.SpFileStream")
        fileStream.Format.Type = 39 ' 39 = SAFT22kHz16BitMono (standard quality)
        fileStream.Open outputPath, 3 ' 3 = SSFMCreateForWrite
        
        ' Set SAPI to write to file instead of speakers
        Set sapi.AudioOutputStream = fileStream
        
        ' Speak the text (writes to WAV file)
        sapi.Speak currentLine, 0 ' 0 = synchronous (wait for completion)
        
        ' Close the file stream
        fileStream.Close
        Set fileStream = Nothing
        
        ' Progress indicator
        If lineNumber Mod 10 = 0 Then
            WScript.Echo "Generated " & lineNumber & " files..."
        End If
    End If
Loop

' Cleanup
textStream.Close
Set textStream = Nothing
Set inputFile = Nothing
Set sapi = Nothing
Set fso = Nothing

' Final report
WScript.Echo ""
WScript.Echo "Complete! Generated " & lineNumber & " WAV files."
WScript.Echo "Files saved to: " & OUTPUT_FOLDER
WScript.Echo ""
WScript.Echo "Press any key to exit..."

' Wait for user (so they can see the results)
WScript.StdIn.ReadLine