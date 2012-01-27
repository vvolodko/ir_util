---  Assertion facility.
--
-- @author Vladimir Volodko

require 'util'


--- TODO make lazy message formatting
Assert = {}

    ---  Unconditionally fail.
    --- Write {msg} to log file and abort update process
    --- with {returnCode} or -1 if not specified.
    function Assert.halt(msg, returnCode)
        Log.fatal(msg or '--- HALT ---')
        Application.Exit(returnCode or -1)
    end

    ---  Unconditionally fail.
    --- Write {msg} to log file and abort current script.
    Assert.error = error

    ---  Check boolean condition.
    Assert.check = assert

    function Assert.eq(expected, actual, msg, level)
        if (expected ~= actual) then
            local msg = string.format('%s: expected %q, got %q',
                    msg or 'Assertion failed',
                    tostring(expected),
                    tostring(actual))
            error(msg, level or 2)
        end 
    end

    function Assert.equal(expected, actual, msg, level)
        if (expected ~= actual) then
            level = level or 2
            if type(expected) == 'table' and type(actual) == 'table' then
                Assert.eq(Table.count(expected), Table.count(actual), msg, level + 1)
                for k, v in pairs(expected) do
                    Assert.equal(v, actual[k], msg)
                end
            else
                Assert.eq(expected, actual, msg, level + 1)
            end
        end
    end

    function Assert.checkFun(fun, input, expect)
        for i, v in ipairs(input) do
            Assert.equal(expect[i], fun(v), tostring(i), 3)
        end
    end

    local function appErrorHandler(fun)
        return function(msg)
            local err = Application.GetLastError()
            if err ~= 0 then
                fun(formatAppError(err, msg))
            end
            return err
        end
    end

    --- Log Application.GetLastError() if any.
    Assert.testLastError = appErrorHandler(Log.warn)

    ---  Fail unless Application.GetLastError() equals zero.
    Assert.checkLastError = appErrorHandler(erorr)

    ---  Halt unless Application.GetLastError() return zero.
    Assert.assertLastError = appErrorHandler(Assert.halt)

testAppError = Assert.testLastError
checkAppError = Assert.checkLastError
assertAppError = Assert.assertLastError

-- TODO test built-in function assert()