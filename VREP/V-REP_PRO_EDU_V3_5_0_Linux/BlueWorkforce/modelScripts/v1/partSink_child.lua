function destroyPartIfPart(objH)
    if objH and objH>=0 then
        local isPart,isInstanciated=simBWF.isObjectPartAndInstanciated(objH)
        if isPart then
            if isInstanciated then
                local p=sim.getModelProperty(objH)
                if sim.boolAnd32(p,sim.modelproperty_not_model)>0 then
                    sim.removeObject(objH)
                else
                    sim.removeModel(objH)
                end
                return true
            else
                return false
            end
        else
            while objH>=0 do
                objH=sim.getObjectParent(objH)
                if objH>=0 then
                    isPart,isInstanciated=simBWF.isObjectPartAndInstanciated(objH)
                    if isPart then
                        if isInstanciated then
                            sim.removeModel(objH)
                            return true
                        else
                            return false
                        end
                    end
                end
            end
        end
    end
    return false
end

function prepareStatisticsDialog(enabled)
    if enabled then
        local xml =[[
                <label id="1" text="Part destruction count: 0" style="* {font-size: 20px; font-weight: bold; margin-left: 20px; margin-right: 20px;}"/>
        ]]
        statUi=simBWF.createCustomUi(xml,sim.getObjectName(model)..' Statistics','bottomLeft',true--[[,onCloseFunction,modal,resizable,activate,additionalUiAttribute--]])
    end
end

function updateStatisticsDialog(enabled)
    if statUi then
        simUI.setLabelText(statUi,1,"Part destruction count: "..destructionCount,true)
    end
end

function isSinkActive()
    if operational then
        if triggerObject~=-1 then
            local data=sim.readCustomDataBlock(triggerObject,simBWF.BINARYSENSOR_TAG)
            if not data then
                data=sim.readCustomDataBlock(triggerObject,simBWF.OLDSTATICPICKWINDOW_TAG)
            end
            if not data then
                data=sim.readCustomDataBlock(triggerObject,simBWF.OLDSTATICPLACEWINDOW_TAG)
            end
            if data then
                data=sim.unpackTable(data)
                local state=data['detectionState']
                if not lastTriggerState then
                    lastTriggerState=state
                end
                if lastTriggerState~=state then
                    lastTriggerState=state
                    return true
                end
                return false
            end
            return false
        else
            return true
        end
    end
end


function sysCall_init()
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    sensor=sim.getObjectHandle('partSink_sensor')
    local data=sim.readCustomDataBlock(model,simBWF.PARTSINK_TAG)
    data=sim.unpackTable(data)
    operational=data['status']~='disabled'
    destructionCount=0
    prepareStatisticsDialog(sim.boolAnd32(data['bitCoded'],128)>0)
    triggerObject=simBWF.getReferencedObjectHandle(model,simBWF.PARTSINK_TRIGGER_REF)
end


function sysCall_actuation()
    if isSinkActive() then
        local shapes=sim.getObjectsInTree(sim.handle_scene,sim.object_shape_type)
        for i=1,#shapes,1 do
            if sim.isHandleValid(shapes[i])>0 then
                if sim.boolAnd32(sim.getObjectSpecialProperty(shapes[i]),sim.objectspecialproperty_detectable_all)>0 then
                    local r=sim.checkProximitySensor(sensor,shapes[i])
                    if r>0 then
                        if destroyPartIfPart(shapes[i]) then
                            destructionCount=destructionCount+1
                            local data=sim.readCustomDataBlock(model,simBWF.PARTSINK_TAG)
                            data=sim.unpackTable(data)
                            data['destroyedCnt']=data['destroyedCnt']+1
                            sim.writeCustomDataBlock(model,simBWF.PARTSINK_TAG,sim.packTable(data))
                        end
                    end
                end
            end
        end
    end
    updateStatisticsDialog()
end

