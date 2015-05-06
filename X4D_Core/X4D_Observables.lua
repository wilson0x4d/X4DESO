local X4D_Observables = LibStub:NewLibrary("X4D_Observables", 1000)
if (not X4D_Observables) then
    return
end
local X4D = LibStub("X4D")
X4D.Observables = X4D_Observables

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
function X4D_Observables:CreateObservable(initialValue)
    local _value = initialValue
    local _observers = {}
    local observable = {
        Observe = function (self, observer)
            table.insert(_observers, observer)
        end,
        GetOrSet = function (self, ...)
            if (select("#", ...) == 0) then
                return _value
            else
                local v = select(1,...)
                local pre = _value
                if (pre ~= _value) then
                    _value = v
                    for _,observer in pairs(_observers) do
                        -- TODO: pcall
                        observer(v, pre)
                    end
                end
            end
        end,
    }
    setmetatable(observable, { __call = observable.GetOrSet })
    return observable
end

setmetatable(X4D_Observables, { __call = X4D_Observables.CreateObservable })

-- TODO: ObservableTable (create new table converting properties to/from observables)