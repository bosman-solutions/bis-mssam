' MS Sam WAV File Generator
' Reads training_corpus.txt and generates numbered WAV files.
' Each non-empty line becomes one .wav file: 001.wav, 002.wav, etc.
'
' Run this from inside a Windows XP VM with Microsoft SAPI 5.1 installed.
' Place this script in v1-sam/ with corpus/ accessible at ../corpus/training_corpus.txt

Option Explicit

' === CONFIGURATION ===
Const INPUT_FILE = "..\corpus\training_corpus.txt"
Const OUTPUT_FOLDER = "wav_output"

' === MAIN SCRIPT ===
Dim fso, inputFile, textStream, lineNumber, currentLine
Dim sapi, fileStream, outputPath, paddedNumber

Set fso = CreateObject("Scripting.FileSystemObject")

If Not fso.FolderExists(OUTPUT_FOLDER) Then
    fso.CreateFolder(OUTPUT_FOLDER)
End If

Set sapi = CreateObject("SAPI.SpVoice")

' Voice index 0 is Microsoft Sam on a stock Windows XP SAPI 5.1 install.
' If you have additional voices installed, enumerate sapi.GetVoices to confirm the index.
Set sapi.Voice = sapi.GetVoices.Item(0)

Set inputFile = fso.GetFile(INPUT_FILE)
Set textStream = inputFile.OpenAsTextStream(1) ' 1 = ForReading

lineNumber = 0

WScript.Echo "Starting WAV generation..."
WScript.Echo "Reading from: " & INPUT_FILE
WScript.Echo "Output folder: " & OUTPUT_FOLDER
WScript.Echo ""

Do While Not textStream.AtEndOfStream
    currentLine = textStream.ReadLine

    If Len(Trim(currentLine)) > 0 Then
        lineNumber = lineNumber + 1
        paddedNumber = Right("000" & lineNumber, 3)
        outputPath = OUTPUT_FOLDER & "\" & paddedNumber & ".wav"

        Set fileStream = CreateObject("SAPI.SpFileStream")
        fileStream.Format.Type = 39 ' SAFT22kHz16BitMono
        fileStream.Open outputPath, 3  ' SSFMCreateForWrite

        Set sapi.AudioOutputStream = fileStream
        sapi.Speak currentLine, 0 ' 0 = synchronous

        fileStream.Close
        Set fileStream = Nothing

        If lineNumber Mod 10 = 0 Then
            WScript.Echo "Generated " & lineNumber & " files..."
        End If
    End If
Loop

textStream.Close
Set textStream = Nothing
Set inputFile = Nothing
Set sapi = Nothing
Set fso = Nothing

WScript.Echo ""
WScript.Echo "Complete! Generated " & lineNumber & " WAV files in: " & OUTPUT_FOLDER
WScript.Echo ""
WScript.Echo "Next: run transcript_generator.py to create matching .txt files,"
WScript.Echo "then transfer wav_output/ to your Linux training host."
WScript.Echo ""
WScript.Echo "Press Enter to exit..."
WScript.StdIn.ReadLine
