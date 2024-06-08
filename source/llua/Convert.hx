package llua;

import haxe.DynamicAccess;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import hxluajit.Types;
import llua.Lua;

class Convert
{
	public static function fromLua(l:State, idx:Int):Dynamic
	{
		switch (Lua.type(l, idx))
		{
			case type if (type == Lua.LUA_TNIL):
				return null;
			case type if (type == Lua.LUA_TBOOLEAN):
				return Lua.toboolean(l, idx);
			case type if (type == Lua.LUA_TNUMBER):
				return Lua.tonumber(l, idx);
			case type if (type == Lua.LUA_TSTRING):
				return cast(Lua.tostring(l, idx), String);
			case type if (type == Lua.LUA_TTABLE):
				var count:Int = 0;
				var array:Bool = true;

				Lua.pushnil(l);

				while (Lua.next(l, idx < 0 ? idx - 1 : idx) != 0)
				{
					if (array)
					{
						if (Lua.isnumber(l, -2))
							array = false;
						else
						{
							final index:Float = Lua.tonumber(l, -2);
							if (index < 0 || Std.int(index) != index)
								array = false;
						}
					}

					count++;
					Lua.pop(l, 1);
				}

				if (count == 0)
					return
					{
					};
				else if (array)
				{
					var ret:Array<Dynamic> = [];

					Lua.pushnil(l);

					while (Lua.next(l, idx < 0 ? idx - 1 : idx) != 0)
					{
						ret[Std.int(Lua.tonumber(l, -2)) - 1] = fromLua(l, -1);

						Lua.pop(l, 1);
					}

					return ret;
				}
				else
				{
					var ret:DynamicAccess<Dynamic> = {};

					Lua.pushnil(l);

					while (Lua.next(l, idx < 0 ? idx - 1 : idx) != 0)
					{
						switch (Lua.type(l, -2))
						{
							case type if (type == Lua.LUA_TSTRING):
								ret.set(cast(Lua.tostring(l, -2), String), fromLua(l, -1));

								Lua.pop(l, 1);
							case type if (type == Lua.LUA_TNUMBER):
								ret.set(Std.string(Lua.tonumber(l, -2)), fromLua(l, -1));

								Lua.pop(l, 1);
						}
					}

					return ret;
				}
			default:
				trace('Couldn\'t convert "${cast (Lua.typename(l, idx), String)}" to Haxe.');
		}

		return null;
	}

	public static function toLua(l:State, val:Dynamic):Void
	{
		switch (Type.typeof(val))
		{
			case TNull:
				Lua.pushnil(l);
			case TInt:
				Lua.pushinteger(l, Std.int(val));
			case TFloat:
				Lua.pushnumber(l, val);
			case TBool:
				Lua.pushboolean(l, val);
			case TClass(Array):
				Lua.createtable(l, val.length, 0);

				for (i in 0...val.length)
				{
					Lua.pushinteger(l, i + 1);
					toLua(l, val[i]);
					Lua.settable(l, -3);
				}
			case TClass(ObjectMap) | TClass(StringMap):
				var map:Map<String, Dynamic> = val;

				Lua.createtable(l, Lambda.count(map), 0);

				for (key => value in map)
				{
					Lua.pushstring(l, Std.isOfType(key, String) ? key : Std.string(key));
					toLua(l, value);
					Lua.settable(l, -3);
				}
			case TClass(String):
				Lua.pushstring(l, cast(val, String));
			case TObject:
				Lua.createtable(l, Reflect.fields(val).length, 0);

				for (key in Reflect.fields(val))
				{
					Lua.pushstring(l, key);
					toLua(l, Reflect.field(val, key));
					Lua.settable(l, -3);
				}
			default:
				trace('Couldn\'t convert "${Type.typeof(val)}" to Lua.');
		}
	}
}
