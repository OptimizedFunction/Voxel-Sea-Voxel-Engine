local DebrisCollector = {}
DebrisCollector.WaitingQueue = {}
DebrisCollector.DeletionQueue = {}

function removeElementFromTable(list : {}, element : any)
    assert(typeof(list) == 'table', 'Expected type table, got type '..typeof(list)..'.')
    if not table.find(list, element) then
        return
    else
        table.remove(list, table.find(list, element))
    end
end

function DebrisCollector.AddItem(instance : Instance, lifetime : number)
    if not instance then return end

    lifetime = lifetime or 0

    assert(typeof(instance) == 'Instance', '[[Debris Collector]][.AddItem] Argument #1 must be of type Instance.')
    assert(typeof(lifetime) == 'number', '[[Debris Collector]][.AddItem] Argument #2 must be of type number.')

    local function QueueForDeletion()
        if not instance or not table.find(DebrisCollector.WaitingQueue, instance) then
            return
        else
            removeElementFromTable(DebrisCollector.WaitingQueue, instance)
            table.insert(DebrisCollector.DeletionQueue, instance)
            task.delay(#DebrisCollector.DeletionQueue/2, function()
                removeElementFromTable(DebrisCollector.DeletionQueue, instance)
                instance:Destroy()
            end)
        end
    end

    task.delay(lifetime, QueueForDeletion)
    table.insert(DebrisCollector.WaitingQueue, instance)

end

function DebrisCollector.RemoveItem(instance : Instance)
    if not instance then return end
    removeElementFromTable(DebrisCollector.WaitingQueue, instance)
end

function DebrisCollector.GetWaitingQueueSize()
    return #DebrisCollector.WaitingQueue
end

return DebrisCollector