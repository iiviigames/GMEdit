package gml;
import ace.AceWrap;
import ace.extern.*;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlLocals {
	public static var defaultMap:Dictionary<GmlLocals> = new Dictionary();
	public static var currentMap:Dictionary<GmlLocals> = defaultMap;
	//
	public var comp:AceAutoCompleteItems = [];
	public var kind:Dictionary<String> = new Dictionary();
	/** T of `var v:T` in type magic */
	public var type:Dictionary<String> = new Dictionary();
	public function add(name:String) {
		if (kind[name] == null) {
			kind.set(name, "local");
			comp.push(new AceAutoCompleteItem(name, "local"));
		}
	}
	public function new() {
		
	}
}
