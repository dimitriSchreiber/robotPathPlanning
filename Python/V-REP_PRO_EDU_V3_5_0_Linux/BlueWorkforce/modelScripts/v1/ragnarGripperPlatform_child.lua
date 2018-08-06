function setPlatformColor(col)
    if platformShape then
       sim.setShapeColor(platformShape,'RAGNARPLATFORM',sim.colorcomponent_ambient,col)
    end
end

function sysCall_init()
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    gripper=-1
    local objs=sim.getObjectsInTree(model,sim.handle_all,1)
    for i=1,#objs,1 do
        if sim.readCustomDataBlock(objs[i],simBWF.RAGNARGRIPPER_TAG) then
            gripper=objs[i]
            break
        end
    end
    
    properties=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.RAGNARGRIPPERPLATFORM_TAG))
    if sim.boolAnd32(properties.bitCoded,1)>0 then
        local obj=sim.getObjectsInTree(model,sim.object_shape_type,0)
        for i=1,#obj,1 do
            local res,col=sim.getShapeColor(obj[i],'RAGNARPLATFORM',sim.colorcomponent_ambient)
            if res>0 then
                platformOriginalCol=col
                platformShape=obj[i]
                break
            end
        end
    end
    prevState=-1
end

function sysCall_sensing()
    if bwfPluginLoaded and sim.boolAnd32(properties.bitCoded,1)>0 then
        local data={}
        data.id=gripper
        local res,retDat=simBWF.query('get_gripperState',data)
        local state=-1
        if res=='ok' then
            state=retDat.gripperState
        end
        if simBWF.isInTestMode() then
            state=1
        end
        if state~=prevState then
            if state==-1 then
                setPlatformColor(platformOriginalCol)
            end
            if state==0 then
                setPlatformColor({0,0.5,1})
            end
            if state==1 then
                setPlatformColor({1,0,0})
            end
            prevState=state
        end
    end
end

function sysCall_cleanup()
    if sim.boolAnd32(properties.bitCoded,1)>0 then
        setPlatformColor(platformOriginalCol)
    end
end

