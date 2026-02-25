' MS Mike & Mary WAV Generator
' Generates a complete Piper-ready dataset for both voices in one pass.
'
' For each voice this produces:
'   wav_output_<voice>/001.wav ... NNN.wav   — audio files
'   wav_output_<voice>/001.txt ... NNN.txt   — matching transcripts
'   wav_output_<voice>/metadata.csv          — LJSpeech-format index
'
' Run this inside your Windows XP VM with SAPI 5.1 + Microsoft voices installed.
' Then transfer both wav_output_* folders to your Linux training host.

Option Explicit

' === CONFIGURATION ===
Const INPUT_FILE = "..\corpus\training_corpus.txt"

' Voice name fragment to search for, and output folder for each voice.
' Extend this array to add more voices.
Dim voiceConfigs(1, 1)
voiceConfigs(0, 0) = "Mary" : voiceConfigs(0, 1) = "wav_output_mary"
voiceConfigs(1, 0) = "Mike" : voiceConfigs(1, 1) = "wav_output_mike"

' === MAIN ===
Dim fso, sapi, allVoices, i

Set fso       = CreateObject("Scripting.FileSystemObject")
Set sapi      = CreateObject("SAPI.SpVoice")
Set allVoices = sapi.GetVoices

For i = 0 To UBound(voiceConfigs, 1)
    ProcessVoice voiceConfigs(i, 0), voiceConfigs(i, 1)
Next

Set allVoices = Nothing
Set sapi      = Nothing
Set fso       = Nothing

WScript.Echo ""
WScript.Echo "All voices complete. Transfer wav_output_mary/ and wav_output_mike/"
WScript.Echo "to your Linux host, then run setup_datasets.sh."
WScript.Echo ""
WScript.Echo "Press Enter to exit..."
WScript.StdIn.ReadLine


' === SUBROUTINE ===
Sub ProcessVoice(voiceName, outputFolder)
    Dim voice, foundVoice
    Dim inputFile, textStream
    Dim lineNumber, currentLine, paddedNumber
    Dim fileStream, outputPath, txtFile, csvFile

    WScript.Echo "======================================="
    WScript.Echo "Processing voice: " & voiceName
    WScript.Echo "Output: " & outputFolder
    WScript.Echo "======================================="

    ' Find voice by name substring match
    foundVoice = False
    For Each voice In allVoices
        If InStr(1, voice.GetDescription, voiceName, vbTextCompare) > 0 Then
            Set sapi.Voice = voice
            foundVoice = True
            Exit For
        End If
    Next

    ' Fallback to index if name match fails
    If Not foundVoice Then
        WScript.Echo "  Warning: '" & voiceName & "' not found by name, falling back to index."
        If voiceName = "Mary" Then Set sapi.Voice = allVoices.Item(1)
        If voiceName = "Mike" Then Set sapi.Voice = allVoices.Item(2)
    End If

    ' Create output folder
    If Not fso.FolderExists(outputFolder) Then
        fso.CreateFolder(outputFolder)
    End If

    Set inputFile  = fso.GetFile(INPUT_FILE)
    Set textStream = inputFile.OpenAsTextStream(1)
    Set csvFile    = fso.CreateTextFile(outputFolder & "\metadata.csv", True)

    lineNumber = 0

    Do While Not textStream.AtEndOfStream
        currentLine = textStream.ReadLine

        If Len(Trim(currentLine)) > 0 Then
            lineNumber   = lineNumber + 1
            paddedNumber = Right("000" & lineNumber, 3)
            outputPath   = outputFolder & "\" & paddedNumber & ".wav"

            ' Write WAV
            Set fileStream = CreateObject("SAPI.SpFileStream")
            fileStream.Format.Type = 39 ' SAFT22kHz16BitMono
            fileStream.Open outputPath, 3
            Set sapi.AudioOutputStream = fileStream
            sapi.Speak currentLine, 0
            fileStream.Close
            Set fileStream = Nothing

            ' Write matching .txt
            Set txtFile = fso.CreateTextFile(outputFolder & "\" & paddedNumber & ".txt", True)
            txtFile.Write currentLine
            txtFile.Close
            Set txtFile = Nothing

            ' Append to metadata.csv (LJSpeech format: filename|transcript)
            csvFile.WriteLine paddedNumber & ".wav|" & currentLine

            If lineNumber Mod 25 = 0 Then
                WScript.Echo "  " & lineNumber & " files..."
            End If
        End If
    Loop

    textStream.Close
    csvFile.Close
    Set textStream = Nothing
    Set inputFile  = Nothing
    Set csvFile    = Nothing

    WScript.Echo "  Done: " & lineNumber & " files written to " & outputFolder
    WScript.Echo ""
End Sub
