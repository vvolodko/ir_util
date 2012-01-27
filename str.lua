---  String utilities.
--
-- @author Vladimir Volodko

--- String utilities namespace, which extends TrueUpdate's String.
Str = setmetatable({}, { __index = String })

    --- Check whether ${str} begins with ${prefix}.
    function Str.begins(str, prefix)
        local len = string.len(prefix)
        return string.len(str) >= len and String.Left(str, len) == prefix
    end


    --- Check whether ${str} ends with ${suffix}.
    function Str.ends(str, suffix)
        local len = string.len(suffix)
        return string.len(str) >= len and String.Right(str, len) == suffix
    end

    --- Return ${str}..${suffix} if ${str} does not end with ${suffix} else return ${str}.
    function Str.withSuffix(str, suffix)
        return Str.ends(str, suffix) and str or str..suffix
    end

    --- Return true if ${str} either nil or empty string.
    function Str.empty(str)
        return (str == nil) or string.len(str) == 0
    end

    function Str.ifEmpty(str, defaultValue)
        return ((str ~= nil) and (string.len(str) ~= 0)) and str or defaultValue
    end

    -- Wrap ${str} with double quotes.
    function Str.dquote(str)
        return '"'.. str .. '"'
    end

    --- Test whether string is empty or nil.
    function Str.trim(str, chars)
        return str == nil and '' or String.TrimLeft(String.TrimRight(str, chars), chars)
    end;

