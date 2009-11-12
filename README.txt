WavPlayer -- flash player for asterisk

	WavPlayer if flash player, specially designed to play files, recorded for and by Asterisk (www.asterisk.org).

	If supports playback of:
	Format | Codecs
	=====================================================================
	.au		G711u, G711a, PCM format, any samplerate/channels
	.wav	G711u, G711a, PCM, GSM 6.10 (MS) formats, any samplerate/channels
	 .wav49	just alias of .wav, can content any of wav codecs
	.gsm	raw GSM 6.10
	.sln 	raw PCM 16bit-signed 8kHz
	 .raw	alias of .sln
	.alaw	raw G711a 8kHz mono
	 .al	alias of .alaw
	.ulaw	raw G711u 8kHz mono
	 .ul	alias of .ulaw
	 .mu	alias of .ulaw
	 .pcm	alias of .ulaw
	=====================================================================

Flash interface:
	none. Just one button, 
		shape of circle = buffering
		shape of square = playing, click will stop
		shape of triangle = stopped, click to play last file

JS interface:
	doPlay([filename])
		start playback of given filename. if filename not given -- play last
	doStop()
		stop playback of current file
	attachHandler(Event, Handler[, User]) -> handlerId
		when Event occurs, Handler will be called, with optionally User info as first argument
	detachHandler(Event, Handler[, User])
		detach all Event handlers, identified by Event/Handler/User triplet
	removeHandler(HandlerId)
		detach event handler, identified by handlerId, returent by previous call to attachHandler

JS events:
	*(eventName[, User][, Arguments])
		fired on any events. first argument then eventName, next is user-supplied argument, rest is event arguments
	PLAYER_BUFFERING()
		fired when player starts buffering of sound.
	PLAYER_LOAD(soundAvailable, soundTotal)
		fired when player loads sound stream.
		soundAvailable = sound length in seconds available to play right now
		soundTotal = total sound length in file, if known
	PLAYER_PLAYING()
		fired when player starts playing sound
	PLAYER_STOPPED()
		fired when player stops playing sound
	progress(bytesLoaded, bytesTotal)
		fired when player loaded next chunk from file.

See usage example in debug.html and index.html

