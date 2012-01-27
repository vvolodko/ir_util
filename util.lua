---  Various utilities.
--
-- @author Vladimir Volodko


--- 'memoize' a function (cache returned value for next call).
--
-- This is useful if you have a function which is relatively expensive,
-- but you don't know in advance what values will be required, so
-- building a table upfront is wasteful/impossible.
--
-- @param func a function of one argument.
-- @param mode if not @c nil used as weaktable mode ('k', 'v', 'kv').
--
-- @return a functable with one argument, which is used as the key.
--
-- From http://lua-users.org/wiki/FuncTables
function memoize(mode, func)
    local mt = {
        __index = function(self, k)
            local v = func(k)
            self[k] = v
            return v
        end,
        
    }
    function mt:__call(k)
        if k ~= nil then return self[k] end
        
        if not mt.nilValueCached then
            mt.nilValueCached = true
            mt.nilValue = func(nil)
        end
        return mt.nilValue
    end


    if mode ~= nil then mt.__mode = mode end
    return setmetatable({}, mt)
end


---  Natural combinator of lexical comparators (fn1, fn2, ...)
function combineLexicalCompare(fn1, fn2, ...)
    local tests = {fn1, fn2, unpack(arg)}
    return function(a1, a2)
        local check
        for i, fn in ipairs(tests) do
            check = fn(a1, a2)
            if check ~= 0 then return check end
        end
        return 0
    end
end


--- Count down iterator
local function countDownIter(s, i)
    if i > 0 then return (i - 1), s end
end

--- Count down iterator factory
function countDown(v, n)
    return countDownIter, v, (n or 1)
end

-- Test countDown iterator.
--[[
do
    for i, v in countDown('zzz', 5) do
        print(i, v)
    end
end
--]]


--- Filtering iterator
local function filterIter(s, i)
    -- s = {filter, iter, state}
    local filter, iter, state = s[1], s[2], s[3]
    for j, v in iter, state, i do
        if filter(v) then return j, v end
    end
end

--- Filtering iterator factory
function filter(filter, iter, state, i)
    return filterIter, {filter, iter, state}, i
end


-- Test filter iterator.
--[[
do
    local function odd(x)
        return Math.Mod(x, 2) == 1
    end
    
    for i, v in filter(odd, pairs {a = 1, b = 2, c = 3, d = 4, e = 5, f = 6,}) do
        print(i, odd(v))
    end
end
--]]

--- Transformation iterator
local function transformIter(s, i)
    -- s = {transform, iter, state}
    local transform, iter, state = s[1], s[2], s[3]
    local i, v = iter(state, i)
    if i ~= nil then return i, transform(v) end
end

--- Transformation iterator factory
function transform(f, iter, state, i)
    return transformIter, {f, iter, state}, i
end

-- Test transform iterator.
--[[
do
    local function add2(x)
        return x + 2
    end
    
    for i, v in transform(add2, ipairs {1, 2, 3, 4, 5, 6,}) do
        print(i, v)
    end

    for i, v in transform(add2, pairs {a = 1, b = 2, c = 3, d = 4, e = 5, f = 6,}) do
        print(i, v)
    end
end
--]]


--- @return logical AND for all @p filters.
function every(filters)
    local function x(a)
        local r = nil
        for i, filter in filters or {} do
            r = filter(a)
            if not r then return r end
        end
        return r
    end
    
    return x
end


--- @return logical OR for all @p filters.
function any(filters)
    local function x(a)
        local r = nil
        for i, filter in filters or {} do
            r = filter(a)
            if r then return r end
        end
        return r
    end
    
    return x
end


--- Map function @p f on table @p t.
function map(f, t)
    local r = {}
    for i, v in t do
        r[i] = f(v)
    end
    return r
end


---  Logging facility.

---  Make logging function with @p severity level.
local function logLevel(severity)
    local severityPrefix = string.format("%-9s ", severity or '')
    return function(msg, ...)
        if (arg.n > 0) then
            msg = string.format(msg, unpack(arg))
        end
        TrueUpdate.WriteToLogFile(severityPrefix..msg.."\r\n")
    end;
end;

--- Logging package.
Log = {}
    ---  Generic log function, severity and msg must be strings.
    function Log.log(severity, msg, ...)
        TrueUpdate.WriteToLogFile(string.format("%-9s "..msg.."\r\n", severity or '', unpack(arg)))
    end

    Log.trace = logLevel('Trace')
    Log.debug = logLevel('Debug')
    Log.info  = logLevel('Info')
    Log.warn  = logLevel('Warning')
    Log.error = logLevel('Error')
    Log.fatal = logLevel('Fatal')

die = error

function halt(msg, returnCode)
    Log.fatal(msg or '--- HALT ---')
    Application.Exit(returnCode or -1)
end


--- Format Application.GetLastError() error code and error description as string.
function formatAppError(err, msg)
    return string.format("%s %d: %q", msg or 'Application error', err,
                _tblErrorMessages[err] or 'unknown error')
end


function lastAppError()
    local err = Application.GetLastError()
    if err ~= 0 then
        local msg = formatAppError(err)
        return false, msg
    end
    return true
end


--- _tostring with buffer
local function _tostringHelper(buf, x)
    if type(x) ~= "table" then
        table.insert(buf, tostring(x))
    else
        table.insert(buf, '{')
        local i, v = next(x)
        if i then
            _tostringHelper(buf, i)
            table.insert(buf, ' = ')
            _tostringHelper(buf, v)
        end
        i, v = next(x, i)
        while i do
            table.insert(buf, ', ')
            _tostringHelper(buf, i)
            table.insert(buf, ' = ')
            _tostringHelper(buf, v)
            i, v = next(x, i)
        end
        table.insert(buf, '}')
    end
end

--- Extend tostring to work better on tables.
local function _tostring(x)
    local buf = {}
    _tostringHelper(buf, x)
    return table.concat(buf, '')
end

---  Extend print to work better on tables
--   arg: objects to print
function print(...)
    Log.trace(table.concat(map(_tostring, arg), ' '))
end



--- Return name for temporary file with given {prefix} and {extension}.
function tmpFile(prefix, extension)
    prefix = prefix or ''
    extension = extension or 'tmp'
    return _TempFolder..'\\'..prefix..string.sub(os.tmpname(), 2)..'.'..extension
end


--- Prepend empty section '[]' to fix bug in TrueUpdate INIFile.
function fixupIniFile(iniFile)
    local file = assert(io.open(iniFile, "r"))
    local content = file:read("*all")
    file:close()
    file = assert(io.open(iniFile, "w"))
    file:write('[]\n')
    file:write(content)
    file:close()
end


---  Ensure destination folder exists.
function ensureDirExists(dir)
    if not Folder.DoesExist(dir) then
        Folder.Create(dir)
    end
end


---  Append all array values of ${t2} to ${t1}
function Table.append(t1, t2)
    for _, v in ipairs(t2) do
        table.insert(t1, v)
    end
end


--[[
FileInfo = {}

--- Object wrapper for TrueUpdate INIFile package.
IniFile = {}

FileInfo.mt = { __index = FileInfo }

--- Create new IniFile instance from given @p file path.
function FileInfo:new(path, )
    return setmetatable({ file = file }, IniFile.mt)
end
--]]

local pathSeparator = {
    posix = '/',
    win = '\\',
    
    system = '\\'
}
function systemPath(str)
    return String.replace(str, pathSeparator.posix, pathSeparator.win)
end

--- Return directory path of the given @p file.
function dirPath(file)
    local dir = String.SplitPath(file)
    dir.Filename = nil
    dir.Extension = nil
    return String.MakePath(dir)
end

--- Return directory path of the given @p file.
function completePath(path, basePath)
    local pathInfo = String.SplitPath(path)
    if pathInfo.Drive ~= '' then return path end
    
    local baseInfo = String.SplitPath(basePath)
    pathInfo.Drive = baseInfo.Drive
    pathInfo.Folder = baseInfo.Folder .. pathSeparator.system .. pathInfo.Folder
    return String.MakePath(pathInfo)
end

--- Load external Action Plugin '$name.lmd' from $dir or current directory if $dir is not specified.
function loadActionPlugin(name, dir)
    local path = systemPath((dir or SessionVar.Expand('%SourceFolder%')) .. '/' .. name .. '.lmd')
    Application.LoadActionPlugin(path)
end
