## 0.0.2

* Fixed import path in example and README documentation (audio_trimmer.dart → audio_trimmer_plus.dart).
* Updated iOS deployment target to 15.0 for ffmpeg_kit_flutter_new compatibility.
* Fixed animation duration calculation in audio trim widget - now uses fixed trim window duration.
* Improved file picker with custom file type filtering (mp3, wav, m4a, flac, aac).
* Adjusted default scale factor from 500.0 to 75.0 for better waveform visualization.

## 0.0.1

* Initial release.
* Complete audio trimming widget with waveform visualization.
* Audio file import with validation.
* Frame-accurate audio trimming with FFmpeg integration.
* Playback controls (play/pause) with automatic end position stopping.
* Customizable trim handles, progress animation, and waveform appearance.
* `AudioTrimWidget` - Main widget for audio trimming interface.
* `AudioTrimmerController` - Controller for managing playback, file import, and trim operations.
* Automatic waveform extraction with calculated sample count.
* Scroll-based trim range selection with real-time updates.
* Support for WAV, MP3, and other audio formats.
