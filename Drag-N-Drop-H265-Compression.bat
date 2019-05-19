@echo off
SET "COMPRESS_PERCENT=45"
SET "COMPRESS_TRESHOLD=16"
SET inputFile="%~1"
SET outputFile="%~p1%~n1 (HEVC).mkv"


for /F "delims=" %%I in ('ffprobe -v error -select_streams v:0 -show_entries format^=bit_rate -of default^=noprint_wrappers^=1:nokey^=1 %inputFile%') do SET "sourceBitrate=%%I"
for /F "delims=" %%I in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 %inputFile%') do SET "sourceCodec=%%I"


SET /A compressTreshold="%COMPRESS_TRESHOLD%*1000000"
SET /A targetBitrate="((%sourceBitrate%/100)*%COMPRESS_PERCENT%)/1000"


echo Input: %inputFile%
echo Output: %outputFile%
echo Source Codec: %sourceCodec%
echo Source Bitrate: %sourceBitrate%
echo Raw Compress Treshold: %compressTreshold%
echo Compress Percentage: %COMPRESS_PERCENT%%
echo Compress Treshold: %COMPRESS_TRESHOLD%mbps
echo Target Bitrate: %targetBitrate%K


IF %sourceCodec% EQU h265 (
	ECHO Source codec is h265, not compressing.
	goto fin
)


ECHO Source codec is not hevc. Proceeding
IF %sourceBitrate% LEQ %compressTreshold% (
	ECHO Bitrate is under target %compressTreshold%, was %sourceBitrate%
	goto fin
) ELSE (
	ECHO Source bitrate is higher than the compression treshold. Proceeding.
	goto compress
)


ECHO UNKNOWN ERROR
pause
exit


:compress
ECHO Source codec is %sourceCodec%, compressing to h265
	ffmpeg -i %inputFile% ^
	-strict experimental ^
	-map 0:v:0 ^
	-map 0:a:0 ^
	-map 0:s ^
	-c:v hevc_nvenc ^
	-c:a copy ^
	-c:s copy ^
	-tune grain ^
	-preset slow ^
	-b:v %targetBitrate%k ^
	%outputFile%
goto fin


:fin
echo FIN
pause
exit