package plume.input;

@:allow(plume.Engine)
interface Input
{	
	@:noCompletion
	public function update():Void;
}