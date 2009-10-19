//
// WAV/AU Flash player with resampler
// 
// Copyright (c) 2009, Anton Fedorov <datacompboy@call2ru.com>
//
/* This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.
 *  
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 */
package fmt;

// FileRaw: stream raw file reader. Subclass it to define used sound decoder
class FileRaw implements fmt.File {
	var Buffer: flash.utils.ByteArray;
	var bufsize: Int;
	var rate : Int;
	var channels : Int;
	var sndDecoder : Null<Decoder>;
	var chunkSize : Int;
    var align : Int;
	var SoundBuffer: Array<Array<Float>>;
	var dataSize : Null<Int>;
	var dataLen : Null<Float>;
	var Readed : Int;

	public function new() {
		Buffer = new flash.utils.ByteArray();
		bufsize = 0;
		rate = 0;
		channels = 0;
		chunkSize = 0;
		align = 0;
		Readed = 0;
	}

	private function init() {
		SoundBuffer = new Array<Array<Float>>();
		for(c in 0...channels)
			SoundBuffer.push( new Array<Float>() );
	}

	// Set known full file length
	public function setSize(size: Int): Void
	{
		dataSize = size;
	}
	// Get estimated sound length
	public function getEtaLength(): Null<Float>
	{
		if (rate==0 || chunkSize==0 || dataSize==0) return null;
		if (dataLen == null && dataSize > 0) 
			dataLen = (Math.floor(dataSize/chunkSize)*sndDecoder.sampleLength)/rate;
		return dataLen;
	}
	// Get loaded sound length
	public function getLoadedLength(): Float
	{
		if (rate == 0 || chunkSize == 0)
			return 0.0;
		else
			return (Readed/chunkSize)*sndDecoder.sampleLength / rate;
	}

	// Push data from audio stream to decoder
	public function push(bytes: flash.utils.IDataInput, last:Bool): Void
	{
		if (channels == 0 || chunkSize == 0 || rate == 0 || sndDecoder==null) return;
		var avail = bytes.bytesAvailable;
		trace("Pushing "+avail+" bytes...");
		if (avail == 0) return;
		bytes.readBytes(Buffer, bufsize, avail);
		bufsize += avail;
		var i = 0;
		var chk = 0;
		while(bufsize - i > chunkSize) {
			for(j in 0...channels) {
				sndDecoder.decode(Buffer, i, SoundBuffer[j], SoundBuffer[j].length);
				i += sndDecoder.sampleSize;
			}
			i += align;
			chk++;
		}
		trace("Read "+chk+" chunks");
		// Remove processed bytes
		Readed += i;
		bufsize -= i;
		Buffer.writeBytes(Buffer, i, bufsize);
	}

	// Returns is stream ready to operate: header readed (1), not ready (0), error(-1)
	public function ready(): Int {
		if (channels == 0 || chunkSize == 0 || rate == 0 || sndDecoder==null) return -1;
		return 1;
	}

	// Get sound samplerate is Hz
	public function getRate(): Int {
		return rate;
	}

	// Get sound channels
	public function getChannels(): Int {
		return channels;
	}

	// Get count of complete samples available
	public function samplesAvailable(): Int {
		return SoundBuffer[0].length;
	}

	// Get complete samples as array of channel samples
	public function getSamples(): Array<Array<Float>> {
		 var Ret = SoundBuffer;
		 SoundBuffer = new Array<Array<Float>>();
		 for(j in 0...channels)
			 SoundBuffer.push(new Array<Float>());
		 return Ret;
	}
}
