local cache = {}
local requiring = {}
local function nocache_require( moduleScript: ModuleScript )
	local hasCache = cache[ moduleScript ]
	if ( hasCache ) then return hasCache end
	if ( requiring[ moduleScript ] ) then
		table.insert( requiring[ moduleScript ], coroutine.running() )
		return coroutine.yield()
	end
	requiring[ moduleScript ] = {}

	local module, parseError = loadstring( moduleScript.Source )
	if ( parseError ) then error( parseError, 2 ) end

	local moduleEnvironment = setmetatable( {
		script = moduleScript,
		require = nocache_require, -- this cache system is required for this to work properly, just use resetCache when necessary
	}, {
		__index = getfenv( module )
	} )

	setfenv( module, moduleEnvironment )

	local output = module() -- let's assume that you are following the rules of module scripts

	for index, thread in requiring[ moduleScript ] do
		task.spawn( thread, output )
		requiring[ moduleScript ][ index ] = nil
	end
	requiring[ moduleScript ] = nil

	return output
end

local function resetCache()
	table.clear( cache )
end

return {
	require = nocache_require,
	clear = resetCache,
}