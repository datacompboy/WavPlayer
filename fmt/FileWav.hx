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

// FileWav: stream WAV file reader
// Currently able to read only files with one <data> block
package fmt;

class FileWav implements fmt.File {
	public var last: Bool;
	var Buffer: flash.utils.ByteArray;
	var bufsize: Int;
	var Readed: Int;
	var State: Int;
	var dataOff: Int;
	var dataSize: Int;
	var fileSize: Int;
	var dataLen: Null<Float>;
	var format: Int;
	var rate : Int;
	var channels : Int;
	var bps : Int;
	var align : Int;
	var sndDecoder : Decoder;
	var chunkSize : Int;
	var SoundBuffer: Array<Array<Float>>;

	public function new() {
		Buffer = new flash.utils.ByteArray();
		bufsize = 0;
		Readed = 0;
		dataOff = 0;
		dataSize = 0;
		fileSize = 0;
		format = 0;
		rate = 0;
		channels = 0;
		chunkSize = 0;
		State = 0;
		bps = 0;
		align = 0;
		last = false;
	}

	// Set known full file length
	public function setSize(size: Int): Void
	{
		fileSize = size;
	}
	// Get estimated sound length
	public function getEtaLength(): Null<Float>
	{
		if (Readed < 0 || State<4 || rate==0 || chunkSize==0 || dataSize==0) return null;
		if (dataLen == null && dataSize != 0)
			dataLen = (Math.floor(dataSize/chunkSize)*sndDecoder.sampleLength)/rate;
		return dataLen;
	}
	// Get loaded sound length
	public function getLoadedLength(): Float
	{
		if (rate == 0 || chunkSize == 0 || dataOff == 0 || State<4)
			return 0.0;
		else
			return Math.floor((bufsize+Readed-dataOff)/chunkSize)*sndDecoder.sampleLength / rate;
	}

	// Push data from audio stream to decoder
	public function push(bytes: flash.utils.IDataInput, last:Bool): Void
	{
		if (Readed < 0) return;
		var avail = bytes.bytesAvailable;
		trace("Pushing "+avail+" bytes...");
		bytes.readBytes(Buffer, bufsize, avail);
		bufsize += avail;
		var i = 0;
		while (i<bufsize) {
			switch (State) {
			  case 0: // Read RIFF header
				if (Readed+i < 12) {
					if (bufsize-i < 4) break;
					var DW = Buffer[i+3]*16777216+Buffer[i+2]*65536+Buffer[i+1]*256+Buffer[i];
					switch( Readed+i ) {
					  case 0:
						if (DW != 0x46464952) {
							trace("Wrong RIFF magic! Got "+DW+" instead of 0x46464952");
							Readed = -1;
							return;
						}
					  case 4:
						dataSize = DW;
						trace("dataSize = "+dataSize);
					  case 8:
						if (DW != 0x45564157) {
							trace("Wrong WAVE magic! Got "+DW+" instead of 0x45564157");
							Readed = -1;
							return;
						}
					}
					i += 4;
				}
				if ((Readed+i) == 12) { // RIFF header skipped, go to WAVE blocks
					State++;
					dataOff = Readed+i;
				}
			  case 1: // Read fmt block
				if (Readed+i-dataOff < 24) {
					if (bufsize-i < 4) break;
					var W1 = Buffer[i+1]*256+Buffer[i];
					var W2 = Buffer[i+3]*256+Buffer[i+2];
					var DW = W2*65536+W1;
					switch( Readed+i-dataOff ) {
					  case 0:
						if (DW != 0x20746D66) {
							trace("Wrong 'fmt ' magic! Got "+DW+" instead of 0x20746D66");
							Readed = -1;
							return;
						}
					  case 4:
						dataSize = DW;
						trace("dataSize2 = "+dataSize);
					  case 8:
						channels = W2;
						format = W1;
						trace("format = "+format+"; channels = "+channels);
					  case 12:
						rate = DW;
						trace("rate = "+rate);
					  case 20:
						bps = W2;
						align = W1;
						trace("align = "+align+"; bps="+bps);
					}
					i += 4;
					if (Readed+i-dataOff == 24) {
						if (channels < 1 || channels > 2) {
							trace("Wrong number of channels: "+channels);
							Readed = -1;
							return;
						}
						switch ( format ) {
						  case 1:
							trace("File in PCM");
							sndDecoder = new DecoderPCM(bps);
						  case 65534:
							trace("File in (Bad?) PCM");
							sndDecoder = new DecoderPCM(bps);
						  case 2:
							trace("File in MS ADPCM");
							Readed = -1; return;
							//sndDecoder = new DecoderMSADPCM(bps);
						  case 6:
							trace("File in 8-bit G.711 a-law format");
							sndDecoder = new DecoderG711a(bps);
						  case 7:
							trace("File in 8-bit G.711 mu-law format");
							sndDecoder = new DecoderG711u(bps);
						  case 17:
							trace("File in IMA ADPCM");
							Readed = -1; return;
							//sndDecoder = new DecoderIMAADPCM(bps);
						  case 20:
							trace("File in G.723 ADPCM");
							Readed = -1; return;
							//sndDecoder = new DecoderG723ADPCM(bps);
						  case 49:
							trace("File in GSM 6.10");
							sndDecoder = new DecoderGSM(bps, align);
						  case 64:
							trace("File in G.721 ADPCM");
							Readed = -1; return;
							//sndDecoder = new DecoderG721ADPCM(bps);
						  case 80:
							trace("File in MPEG");
							//sndDecoder = new DecoderMPEG(bps);
							Readed = -1; return;
						  default:
							trace("File in unknown/unsupported format #"+format);
							Readed = -1;
							return;
						}
						SoundBuffer = new Array<Array<Float>>();
						for(j in 0...channels)
							SoundBuffer.push(new Array<Float>());
						chunkSize = sndDecoder.sampleSize*channels;
						if (align > chunkSize) align -= chunkSize; else align = 0;
						if (Readed+i-dataOff == dataSize+8) {
							State++;
							dataOff = Readed+i;
						}
						trace("chunkSize = "+chunkSize+"; sampleSize="+sndDecoder.sampleSize+"; align="+align);
					}
				}
				else if (Readed+i-dataOff < dataSize+8) {
					var NeedSkip = (dataSize+8) - (Readed+i-dataOff);
					trace("dataOff = "+dataOff+"; dataSize = "+dataSize+"; Readed="+Readed+"; i="+i+"; bufsize="+bufsize+"; NeedSkip="+NeedSkip);
					if (NeedSkip > bufsize-i) {
						i = bufsize;
					} else {
						i += NeedSkip;
					}
					if (Readed+i-dataOff == dataSize+8) {
						State++;
						dataOff = Readed+i;
					}
				}
			  case 2: // Read any misc header
				if (Readed+i-dataOff < 8) {
					if (bufsize-i < 4) break;
					var DW = Buffer[i+3]*16777216+Buffer[i+2]*65536+Buffer[i+1]*256+Buffer[i];
					switch( Readed+i-dataOff ) {
					  case 0:
						if (DW == 0x61746164) {
							trace("Data block!");
							State++;
						} else
							trace("Unknown block, skipping ("+DW+")");
					  case 4:
						dataSize = DW;
						trace("dataSize3 = "+dataSize);
					}
					i += 4;
				}
				if (Readed+i-dataOff >= 8 && Readed+i-dataOff <= dataSize+8) {
					var NeedSkip = (dataSize+8) - (Readed+i-dataOff);
					trace("dataOff = "+dataOff+"; dataSize = "+dataSize+"; Readed="+Readed+"; i="+i+"; bufsize="+bufsize+"; NeedSkip="+NeedSkip);
					if (NeedSkip > bufsize-i) {
						i = bufsize;
					} else {
						i += NeedSkip;
					}
					if (Readed+i-dataOff == dataSize+8) {
						dataOff = Readed+i;
					}
				}
			  case 3: // Read data header
				if (Readed+i-dataOff < 8) {
					if (bufsize-i < 4) break;
					var DW = Buffer[i+3]*16777216+Buffer[i+2]*65536+Buffer[i+1]*256+Buffer[i];
					switch( Readed+i-dataOff ) {
					  case 0:
						if (DW != 0x61746164) {
							trace("Wrong 'data' magic! Got "+DW+" instead of 0x61746164");
							Readed = -1;
							return;
						}
					  case 4:
						dataSize = DW;
						trace("dataSize(data) = "+dataSize);
						if (dataSize <= 0 && fileSize > 0)
							dataSize = fileSize - dataOff; // Try to get data size
						// Todo: support multiple "DATA" chunks in file, skipping unknown blocks
					}
					i += 4;
				}
				if (Readed+i-dataOff == 8) {
					State++;
					dataOff = Readed+i;
					trace("Get data block begin (dataOff="+dataOff+"; State="+State+"; bufsize="+bufsize+")");
				}
			  default: // Read sound stream
				break;
			}
		}
		// Remove processed bytes
		Readed += i;
		bufsize -= i;
		Buffer.position = 0;
		Buffer.writeBytes(Buffer, i, bufsize);
	}

	// Require decoder to populate at least <samples> samples from audio stream
	public function populate(samples: Int): Void
	{
		if (ready() != 1) return;
		var i = 0;
		var chk = 0;
		while(SoundBuffer[0].length < samples && bufsize - i > chunkSize) {
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
		Buffer.position = 0;
		Buffer.writeBytes(Buffer, i, bufsize);
		last = (Readed == fileSize);
	}

	// Returns is stream ready to operate: header readed (1), not ready (0), error(-1)
	public function ready(): Int 
	{
		if (channels == 0 || chunkSize == 0 || rate == 0 || sndDecoder==null) return -1;
		if (Readed < 0) return -1;
		if (State < 4) return 0;
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
