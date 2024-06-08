package llua;

import hxluajit.Types;

@:buildXml('<include name="${haxelib:hxluajit}/project/Build.xml" />')
@:include('lua.hpp')
@:unreflective
extern class Lua
{
	public static inline var LUA_OK:Int = 0;
	public static inline var LUA_YIELD:Int = 1;
	public static inline var LUA_ERRRUN:Int = 2;
	public static inline var LUA_ERRSYNTAX:Int = 3;
	public static inline var LUA_ERRMEM:Int = 4;
	public static inline var LUA_ERRERR:Int = 5;
	public static inline var LUA_TNONE:Int = (-1);
	public static inline var LUA_TNIL:Int = 0;
	public static inline var LUA_TBOOLEAN:Int = 1;
	public static inline var LUA_TLIGHTUSERDATA:Int = 2;
	public static inline var LUA_TNUMBER:Int = 3;
	public static inline var LUA_TSTRING:Int = 4;
	public static inline var LUA_TTABLE:Int = 5;
	public static inline var LUA_TFUNCTION:Int = 6;
	public static inline var LUA_TUSERDATA:Int = 7;
	public static inline var LUA_TTHREAD:Int = 8;

	@:native('lua_pushnil')
	static function pushnil(L:cpp.RawPointer<Lua_State>):Void;

	@:native('lua_pushnumber')
	static function pushnumber(L:cpp.RawPointer<Lua_State>, n:Lua_Number):Void;

	@:native('lua_pushinteger')
	static function pushinteger(L:cpp.RawPointer<Lua_State>, n:Lua_Integer):Void;

	@:native('lua_pushlstring')
	static function pushlstring(L:cpp.RawPointer<Lua_State>, s:cpp.ConstCharStar, len:cpp.SizeT):Void;

	@:native('lua_pushstring')
	static function pushstring(L:cpp.RawPointer<Lua_State>, s:cpp.ConstCharStar):Void;

	@:native('lua_pushvfstring')
	static function pushvfstring(L:cpp.RawPointer<Lua_State>, s:cpp.ConstCharStar, argp:cpp.VarList):Void;

	@:native('lua_pushfstring')
	static function pushfstring(L:cpp.RawPointer<Lua_State>, fmt:cpp.ConstCharStar, args:cpp.Rest<cpp.VarArg>):cpp.ConstCharStar;

	@:native('lua_pushcclosure')
	static function pushcclosure(L:cpp.RawPointer<Lua_State>, fn:Lua_CFunction, n:Int):Void;

	@:native('lua_pushboolean')
	static function pushboolean(L:cpp.RawPointer<Lua_State>, b:Int):Void;

	@:native('lua_pushlightuserdata')
	static function pushlightuserdata(L:cpp.RawPointer<Lua_State>, p:cpp.RawPointer<cpp.Void>):Void;

	@:native('lua_pushthread')
	static function pushthread(L:cpp.RawPointer<Lua_State>):Int;

	@:native('lua_pop')
	static function pop(L:cpp.RawPointer<Lua_State>, n:Int):Void;

	@:native('lua_type')
	static function type(L:cpp.RawPointer<Lua_State>, idx:Int):Int;

	@:native('lua_typename')
	static function typename(L:cpp.RawPointer<Lua_State>, tp:Int):cpp.ConstCharStar;

	@:native('lua_setglobal')
	static function setglobal(L:cpp.RawPointer<Lua_State>, s:cpp.ConstCharStar):Int;

	@:native('lua_getglobal')
	static function getglobal(L:cpp.RawPointer<Lua_State>, s:cpp.ConstCharStar):Int;

	@:native('lua_tostring')
	static function tostring(L:cpp.RawPointer<Lua_State>, i:Int):cpp.ConstCharStar;

	@:native('lua_close')
	static function close(L:cpp.RawPointer<Lua_State>):Void;

	@:noCompletion
	@:native('lua_isboolean')
	static function _isboolean(l:State, idx:Int):Int;

	static inline function isboolean(l:State, idx:Int):Bool {
		return _isboolean(l, idx) != 0;
	}

	@:noCompletion
	@:native('lua_isstring')
	static function _isstring(l:State, idx:Int) : Int;

	static inline function isstring(l:State, idx:Int) : Bool {
		return _isstring(l, idx) != 0;
	}

	@:native('lua_toboolean')
	static function toboolean(L:cpp.RawPointer<Lua_State>, idx:Int):Int;

	@:noCompletion
	@:native('lua_isnumber')
	static function _isnumber(l:State, idx:Int):Int;

	static inline function isnumber(l:State, idx:Int):Bool {
		return _isnumber(l, idx) != 0;
	}

	@:native('lua_tonumber')
	static function tonumber(L:cpp.RawPointer<Lua_State>, idx:Int):Lua_Number;

	@:native('lua_pcall')
	static function pcall(L:cpp.RawPointer<Lua_State>, nargs:Int, nresults:Int, errfunc:Int):Int;

	@:native('lua_tointeger')
	static function tointeger(L:cpp.RawPointer<Lua_State>, idx:Int):Lua_Integer;

	@:native('lua_next')
	static function next(L:cpp.RawPointer<Lua_State>, idx:Int):Int;

	@:native('lua_createtable')
	static function createtable(L:cpp.RawPointer<Lua_State>, narr:Int, nrec:Int):Void;

	@:native('lua_settable')
	static function settable(L:cpp.RawPointer<Lua_State>, idx:Int):Int;

	static inline function init_callbacks(l:State):Void
	{
		return hxluajit.Lua.register(l, "print", cpp.Function.fromStaticFunction(print));
	}

	static inline function print(l:State):Int
	{
		final nargs:Int = hxluajit.Lua.gettop(l);

		for (i in 0...nargs)
			trace(cast(hxluajit.Lua.tostring(l, i + 1), String));

		hxluajit.Lua.pop(l, nargs);
		return 0;
	}
}

class Lua_helper
{
	public static var callbacks:Map<String, Dynamic> = new Map();

	public static inline function add_callback(l:State, fname:String, f:Dynamic):Bool
	{
		callbacks.set(fname, f);
		hxluajit.Lua.pushstring(l, fname);
		hxluajit.Lua.pushcclosure(l, cpp.Function.fromStaticFunction(callback), 1);
		hxluajit.Lua.setglobal(l, fname);
		return true;
	}

	private static function callback(l:State):Int
	{
		final nargs:Int = hxluajit.Lua.gettop(l);

		var args:Array<Dynamic> = [];
		for (i in 0...nargs)
			args[i] = Convert.fromLua(l, i + 1);

		hxluajit.Lua.pop(l, nargs);

		final name:String = hxluajit.Lua.tostring(l, hxluajit.Lua.upvalueindex(1));

		if (callbacks.exists(name))
		{
			var ret:Dynamic = Reflect.callMethod(null, callbacks.get(name), args);

			if (ret != null)
			{
				Convert.toLua(l, ret);
				return 1;
			}
		}

		return 0;
	}
}
