require("/BlueWorkforce/modelScripts/v1/partCreationAndHandling_include")

function getPartToDrop(distributionExtent,partDistribution,destinationDistribution,shiftDistribution,rotationDistribution,massDistribution,scalingDistribution,partsData)
    local errString=nil
    local dropName=getDistributionValue(partDistribution)
    local thePartD=partsData[dropName]
    local partToDrop=nil
    if thePartD then
        local destinationName=getDistributionValue(destinationDistribution)
        local dropShift=getDistributionValue(shiftDistribution)
        if not dropShift then dropShift={0,0,0} end
        dropShift[1]=dropShift[1]*distributionExtent[1]
        dropShift[2]=dropShift[2]*distributionExtent[2]
        dropShift[3]=dropShift[3]*distributionExtent[3]
        local dropRotation=getDistributionValue(rotationDistribution)
        local dropMass=getDistributionValue(massDistribution)
        local dropScaling=nil
        if scalingDistribution then
            dropScaling=getDistributionValue(scalingDistribution)
        end
        partToDrop={dropName,destinationName,dropShift,dropRotation,dropMass,dropScaling}
    else
        local nm=' ['..simBWF.getObjectAltName(model)..']'
        local msg="WARNING (run-time): Part '"..dropName.."' was not found in the part repository"..nm  
        simBWF.outputMessage(msg)
    end
    return partToDrop,errString
end

function getDistributionValue(distribution)
    -- Distribution string could be:
    -- {} --> returns nil
    -- {{}} --> returns nil
    -- a,a,b,c --> returns a,b, or c
    -- {{2,a},{1,b},{1,c}} --> returns a,b, or c
    if #distribution>0 then
        if (type(distribution[1])~='table') or (#distribution[1]>0) then
            if (type(distribution[1])=='table') and (#distribution[1]==2) then
                local cnt=0
                for i=1,#distribution,1 do
                   cnt=cnt+distribution[i][1] 
                end
                local p=sim.getFloatParameter(sim.floatparam_rand)*cnt
                cnt=0
                for i=1,#distribution,1 do
                    if cnt+distribution[i][1]>=p then
                        return distribution[i][2]
                    end
                    cnt=cnt+distribution[i][1] 
                end
            else
                local cnt=#distribution
                local p=1+math.floor(sim.getFloatParameter(sim.floatparam_rand)*cnt-0.0001)
                return distribution[p]
            end
        end
    end
end

function getSensorState()
    if sensorHandle>=0 then
        local data=sim.readCustomDataBlock(sensorHandle,simBWF.BINARYSENSOR_TAG)
        if data then
            data=sim.unpackTable(data)
            return data['detectionState']
        end
        local data=sim.readCustomDataBlock(sensorHandle,simBWF.OLDSTATICPICKWINDOW_TAG)
        if data then
            data=sim.unpackTable(data)
            return data['triggerState']
        end
    end
    return 0
end

function getConveyorDistanceTrigger()
    if conveyorHandle>=0 then
        local data=sim.readCustomDataBlock(conveyorHandle,simBWF.CONVEYOR_TAG)
        if data then
            data=sim.unpackTable(data)
            local d=data['encoderDistance']
            if d then
                if not lastConveyorDistance then
                    lastConveyorDistance=d
                end
                if math.abs(lastConveyorDistance-d)>conveyorTriggerDist then
                    lastConveyorDistance=d
                    return true,d
                end
            end
        end
    end
    return false,d
end

function prepareStatisticsDialog(enabled)
    if enabled then
        local xml =[[
                <label id="1" text="Part production count: 0" style="* {font-size: 20px; font-weight: bold; margin-left: 20px; margin-right: 20px;}"/>
        ]]
        statUi=simBWF.createCustomUi(xml,simBWF.getObjectAltName(model)..' Statistics','bottomLeft',true--[[,onCloseFunction,modal,resizable,activate,additionalUiAttribute--]])
    end
end

function updateStatisticsDialog(enabled)
    if statUi then
        simUI.setLabelText(statUi,1,"Part production count: "..productionCount,true)
    end
end

function wasMultiFeederTriggered()
    local data=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.PARTFEEDER_TAG))
    local val=data['multiFeederTriggerCnt']
    if val and val~=multiFeederTriggerLastState then
        multiFeederTriggerLastState=val
        return true
    end
    return false
end

function getStartStopTriggerType()
    if stopTriggerSensor~=-1 then
        local data=sim.readCustomDataBlock(stopTriggerSensor,simBWF.BINARYSENSOR_TAG)
        if data then
            data=sim.unpackTable(data)
            local state=data['detectionState']
            if not lastStopTriggerState then
                lastStopTriggerState=state
            end
            if lastStopTriggerState~=state then
                lastStopTriggerState=state
                return -1 -- means stop
            end
        end
    end
    if startTriggerSensor~=-1 then
        local data=sim.readCustomDataBlock(startTriggerSensor,simBWF.BINARYSENSOR_TAG)
        if data then
            data=sim.unpackTable(data)
            local state=data['detectionState']
            if not lastStartTriggerState then
                lastStartTriggerState=state
            end
            if lastStartTriggerState~=state then
                lastStartTriggerState=state
                return 1 -- means restart
            end
        end
    end
    return 0
end

function manualTrigger_callback()
    manualTrigger=true
end

function sysCall_init()
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    producedPartsDummy=sim.getObjectHandle('genericFeeder_ownedParts')
    smallLabel=sim.getObjectHandle('genericFeeder_smallLabel')
    largeLabel=sim.getObjectHandle('genericFeeder_largeLabel')
    originalPartHolder=sim.getObjectHandle('partRepository_modelParts#')
    local data=sim.readCustomDataBlock(model,simBWF.PARTFEEDER_TAG)
    data=sim.unpackTable(data)
    maxProductionCnt=data.maxProductionCnt
    if maxProductionCnt==0 then
        maxProductionCnt=-1 -- means unlimited
    end

    online=simBWF.isSystemOnline()
    if online then

    else
        prepareStatisticsDialog(sim.boolAnd32(data['bitCoded'],128)>0)
        productionCount=0
        stopTriggerSensor=simBWF.getReferencedObjectHandle(model,simBWF.FEEDER_STOPSIGNAL_REF)
        startTriggerSensor=simBWF.getReferencedObjectHandle(model,simBWF.FEEDER_STARTSIGNAL_REF)
        sensorHandle=simBWF.getReferencedObjectHandle(model,simBWF.FEEDER_SENSOR_REF)
        conveyorHandle=simBWF.getReferencedObjectHandle(model,simBWF.FEEDER_CONVEYOR_REF)
        conveyorTriggerDist=data['conveyorDist']
        mode=0 -- 0=frequency, 1=sensor, 2=user, 3=conveyor, 4=multi-feeder
        local tmp=sim.boolAnd32(data['bitCoded'],4+8+16)
        if tmp==4 then mode=1 end
        if tmp==8 then mode=2 end
        if tmp==12 then mode=3 end
        if tmp==16 then mode=4 end
        if tmp==20 then mode=5 end
        sensorLastState=0
        multiFeederTriggerLastState=0
        getStartStopTriggerType()
        local parts=simBWF.getAllPartsFromPartRepository()
        partsData={}
        if parts then
            for i=1,#parts,1 do
                local h=parts[i][2]
                local dat=sim.readCustomDataBlock(h,simBWF.PART_TAG)
                dat=sim.unpackTable(dat)
                dat['handle']=h
                partsData[simBWF.getPartAltName(h)]=dat
            end
        else
            sim.addStatusbarMessage('\nWarning: no part repository found in the scene.\n')
        end
        allProducedParts={}
        timeForIdlePartToDeactivate=simBWF.modifyPartDeactivationTime(data['deactivationTime'])
        counter=0
        wasEnabled=false
        fromStartStopTriggerEnable=true
        fromStartStopTriggerWasEnable=true
        if mode==5 then
            local xml ='<button text="Trigger part production"  on-click="manualTrigger_callback" style="* {min-width: 220px; min-height: 50px;}"/>'

            manualTriggerUi=simBWF.createCustomUi(xml,simBWF.getUiTitleNameFromModel(model,_MODELVERSION_,_CODEVERSION_),nil,false,"",false,false,false,"")
        end
    end
end

function sysCall_actuation()
    local t=sim.getSimulationTime()
    local dt=sim.getSimulationTimeStep()
    local data=sim.readCustomDataBlock(model,simBWF.PARTFEEDER_TAG)
    data=sim.unpackTable(data)
    if online then
    
    
    else
        local distributionExtent=data['size']
        local dropFrequency=data['frequency']
        local feederAlgo=data['algorithm']
        local enabled=sim.boolAnd32(data['bitCoded'],2)>0
        if maxProductionCnt~=0 then
            if enabled then
                if not wasEnabled then
                    fromStartStopTriggerEnable=true
                    fromStartStopTriggerWasEnable=true
                    sensorLastState=getSensorState()
                    lastDropTime=nil
                    nothing,lastConveyorDistance=getConveyorDistanceTrigger()
                end
            end
            wasEnabled=enabled

            local trigger=getStartStopTriggerType()
            if enabled then
                if trigger>0 then
                    fromStartStopTriggerEnable=true
                end
                if trigger<0 then
                    fromStartStopTriggerEnable=false
                end
                if fromStartStopTriggerEnable and not fromStartStopTriggerWasEnable then
                    sensorLastState=getSensorState()
                    lastDropTime=nil
                    nothing,lastConveyorDistance=getConveyorDistanceTrigger()
                end
            end
            fromStartStopTriggerWasEnable=fromStartStopTriggerEnable
            
            if enabled and fromStartStopTriggerEnable then
                -- The feeder is enabled
                local partDistribution='{'..data['partDistribution']..'}'
                local f=loadstring("return "..partDistribution)
                partDistribution=f()
                local destinationDistribution='{'..data['destinationDistribution']..'}'
                local f=loadstring("return "..destinationDistribution)
                destinationDistribution=f()
                local shiftDistribution='{'..data['shiftDistribution']..'}'
                local f=loadstring("return "..shiftDistribution)
                shiftDistribution=f()
                local rotationDistribution='{'..data['rotationDistribution']..'}'
                local f=loadstring("return "..rotationDistribution)
                rotationDistribution=f()
                local massDistribution='{'..data['weightDistribution']..'}'
                local f=loadstring("return "..massDistribution)
                massDistribution=f()
                local labelDistribution='{'..data['labelDistribution']..'}'
                local f=loadstring("return "..labelDistribution)
                labelDistribution=f()

                local scalingDistribution=nil
                if data['sizeScaling'] and data['sizeScaling']>0 then
                    if data['sizeScaling']==1 then
                        scalingDistribution='{'..data['isoSizeScalingDistribution']..'}'
                    end
                    if data['sizeScaling']==2 then
                        scalingDistribution='{'..data['nonIsoSizeScalingDistribution']..'}'
                    end
                    local f=loadstring("return "..scalingDistribution)
                    scalingDistribution=f()
                end

                local sensorState=getSensorState()
                local partToDrop=nil
                local errStr=nil
                local t=sim.getSimulationTime()
                if mode==0 then
                    -- Frequency triggered
                    if not lastDropTime then
                        lastDropTime=t-9999
                    end
                    if t-lastDropTime>(1/dropFrequency) then
                        lastDropTime=t
                        partToDrop,errStr=getPartToDrop(distributionExtent,partDistribution,destinationDistribution,shiftDistribution,rotationDistribution,massDistribution,scalingDistribution,partsData)
                    end
                end
                if mode==1 then
                    -- Sensor triggered
                    if sensorState~=sensorLastState then
                        partToDrop,errStr=getPartToDrop(distributionExtent,partDistribution,destinationDistribution,shiftDistribution,rotationDistribution,massDistribution,scalingDistribution,partsData)
                    end
                end
                if mode==3 and getConveyorDistanceTrigger() then
                    -- Conveyor belt distance triggered
                    partToDrop,errStr=getPartToDrop(distributionExtent,partDistribution,destinationDistribution,shiftDistribution,rotationDistribution,massDistribution,scalingDistribution,partsData)
                end
                if mode==2 then
                    -- User triggered
                    local algo=assert(loadstring(feederAlgo))
                    if algo() then
                        partToDrop,errStr=getPartToDrop(distributionExtent,partDistribution,destinationDistribution,shiftDistribution,rotationDistribution,massDistribution,scalingDistribution,partsData)
                    end
                end
                if mode==4 then
                    -- Multi-feeder triggered
                    if wasMultiFeederTriggered() then
                        partToDrop,errStr=getPartToDrop(distributionExtent,partDistribution,destinationDistribution,shiftDistribution,rotationDistribution,massDistribution,scalingDistribution,partsData)
                    end
                end
                if mode==5 then
                    -- Manually triggered
                    if manualTrigger then
                        manualTrigger=nil
                        lastDropTime=t
                        partToDrop,errStr=getPartToDrop(distributionExtent,partDistribution,destinationDistribution,shiftDistribution,rotationDistribution,massDistribution,scalingDistribution,partsData)
                    end
                end
                if errStr then
                    sim.addStatusbarMessage('\n'..errStr..'\n')
                end
                sensorLastState=sensorState
                if partToDrop then
                    if maxProductionCnt>0 then
                        maxProductionCnt=maxProductionCnt-1
                    end
                    counter=counter+1
                    local itemName=partToDrop[1]
                    local itemDestination=partToDrop[2]
                    local itemPosition=partToDrop[3]
                    local itemOrientation=partToDrop[4]
                    local itemMass=partToDrop[5]
                    local itemScaling=partToDrop[6]
                    local dat=partsData[itemName]
                    if dat then
                        productionCount=productionCount+1
                        local h=dat['handle']
                        
                        if itemDestination and itemDestination=='<DEFAULT>' then
                            itemDestination=nil
                        end
                        if not itemPosition then
                            itemPosition=sim.getObjectPosition(model,-1) -- default
                        else
                            itemPosition=sim.multiplyVector(sim.getObjectMatrix(model,-1),itemPosition)
                        end
                        if not itemOrientation then
                            itemOrientation=sim.getObjectOrientation(model,-1) -- default
                        else
                            local m=sim.buildMatrix({0,0,0},itemOrientation)
                            m=sim.multiplyMatrices(sim.getObjectMatrix(model,-1),m)
                            itemOrientation=sim.getEulerAnglesFromMatrix(m)
                        end
                        if itemMass and itemMass=='<DEFAULT>' then
                            itemMass=nil
                        end
                        local labelsToEnable=getDistributionValue(labelDistribution)
                        
                        local baseHandleAndModelTag,auxPartsHandlesAndModelTags=partCreation_instanciatePart(h,producedPartsDummy,itemDestination,itemPosition,itemOrientation,itemMass,itemScaling,labelsToEnable,true)
                        partCreation_addToProducedPartsList(baseHandleAndModelTag,auxPartsHandlesAndModelTags,allProducedParts,t)
                    end
                end
            end
        end
        
        partCreation_handleCreatedParts(allProducedParts,timeForIdlePartToDeactivate,t,dt)
        updateStatisticsDialog()
    end
end

