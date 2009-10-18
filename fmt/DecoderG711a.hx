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

// G711 a-Law decoder
// Dirty IF-based version removed in favor of more effective
// and beautiful code from sox, licensed under GPL
package fmt;

class DecoderG711a implements fmt.Decoder {
	public var sampleSize : Int;
	public function new(bps : Int, ?bs : Int) {
		if (bps != 8) throw "Unsupported BPS";
		sampleSize = 1;
	}
	static var exp_lut : Array<Int> = [ 0, 264, 528, 1056, 2112, 4224, 8448, 16896 ];
	public function decode( InBuf : haxe.io.BytesData, InOff: Int, OutBuf : Array<Float>, OutOff : Int) : Int {
		/*=================================================================================
		**		The following routines came from the sox-12.15 (Sound eXcahcnge) distribution.
		*/
		/*
		** This routine converts from ulaw to 16 bit linear.
		**
		** Craig Reese: IDA/Supercomputing Research Center
		** 29 September 1989
		**
		** References:
		** 1) CCITT Recommendation G.711  (very difficult to follow)
		** 2) MIL-STD-188-113,"Interoperability and Performance Standards
		**	   for Analog-to_Digital Conversion Techniques,"
		**	   17 February 1987
		**
		** Input: 8 bit ulaw sample
		** Output: signed 16 bit linear sample
		*/
		var Alawbyte = InBuf[InOff];
		var sign, exponent, mantissa, sample ;
		Alawbyte ^= 0x55 ;
		sign = ( Alawbyte & 0x80 ) ;
		Alawbyte &= 0x7f ;					/* get magnitude */
		if (Alawbyte >= 16)
			{		exponent = (Alawbyte >> 4 ) & 0x07 ;
					mantissa = Alawbyte & 0x0F ;
					sample = exp_lut[exponent] + (mantissa << ( exponent + 3 )) ;
					}
		else
					sample = (Alawbyte << 4) + 8 ;
		if (sign == 0)
					sample = -sample ;
		OutBuf[OutOff] = sample / 32768.0;
		return 1;
	}
}
