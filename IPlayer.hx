interface IPlayer {
	var volume(getVolume, setVolume): Float;
    var pan(getPan, setPan): Float;
    var soundTransform(getST, setST): flash.media.SoundTransform;
	function play(?path : String, ?trigger_buffer : Float): Void;
	function setVolume(volume: Float) : Float;
	function getVolume(): Float;
	function setPan(pan: Float): Float;
	function getPan(): Float;
	function setST(st: flash.media.SoundTransform): flash.media.SoundTransform;
	function getST(): flash.media.SoundTransform;
	function pause(): Void;
	function resume(): Void;
	function seek(pos: Float): Void;
	function stop(): Void;
}