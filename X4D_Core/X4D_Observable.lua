local X4D_Observable = LibStub:NewLibrary("X4D_Observable", 1015)
if (not X4D_Observable) then
    return
end
local X4D = LibStub("X4D")
X4D.Observable = X4D_Observable

--[[

    invoking with no arguments should yield the current value, if no value has been set nil is returned
    invoking with an argument should set a new value, nil being a valid value
    there can be more than one observer of an observable, observers subscribe via ::Observe(observer) where observer is 'function (newValue, oldValue) end'
    when a new value is set an observer receives the new value and the old value, at the time the observer is activated the observable has already been updated
    order of execution of observers is not guaranteed, i am considering introducing pqueue behavior for scheduling observers (a.k.a ui binding priority)
    if one observer fails, other observers may not execute (observers should properly trap errors), i may change this behavior later if i can't polyfill uierror()

    Prototype/Vision:

    local entity = {
        FirstName = X4D.Observable("Shaun"),
        LastName = X4D.Observable("Wilson"),
    }

    entity.FirstName:Observe(function(newValue,oldValue)
        if (newValue ~= oldValue) then
            MySettings:Set("FirstName", newValue)
        else
            -- NOTE: this is not a potential state, Test() will check this
        end
    end)

]]
function X4D_Observable:CreateObservable(initialValue)
    local _value = initialValue
    local _timestamp = GetGameTimeMilliseconds()
    local _rateLimit = nil
    local _observers = {}
    local observable = {}
    observable.SetRateLimit = function (self, rateLimit)
        _rateLimit = rateLimit -- optional, default is no rate limit, observers are activateed on every update
        return observable
    end
    observable.Observe = function (self, observer, rateLimit)
		if (rateLimit ~= nil) then
			_rateLimit = rateLimit
		end
		if (observer ~= nil and type(observer) == "function") then
	        table.insert(_observers, observer)
		else
			X4D.Log:Warning{"X4D_Observable:Observe", "Observer null or invalid type", type(observer)}
		end
        return observable
    end
    observable.GetOrSet = function (self, ...)
        if (select("#", ...) > 0) then
            local v = select(1, ...)
            local pre = _value
            if (pre ~= v) then
                _value = v
                local now = GetGameTimeMilliseconds()
                if ((_rateLimit == nil or _timestamp == nil) or ((now - _timestamp) > _rateLimit)) then
                    _timestamp = now
					for _,observer in pairs(_observers) do
						-- TODO: pcall
						observer(v, pre)
					end
                end
            end
        end
        return _value
    end
    setmetatable(observable, { __call = observable.GetOrSet })
    return observable
end

setmetatable(X4D_Observable, { __call = X4D_Observable.CreateObservable })

-- TODO: ObservableTable (create new table converting properties to/from observables)