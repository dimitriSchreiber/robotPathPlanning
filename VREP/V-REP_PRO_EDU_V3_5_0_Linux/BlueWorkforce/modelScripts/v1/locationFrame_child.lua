require("/BlueWorkforce/modelScripts/v1/partCreationAndHandling_include")

function getAssociatedRobotHandle()
    local ragnars=sim.getObjectsWithTag(simBWF.RAGNAR_TAG,true)
    for i=1,#ragnars,1 do
        if simBWF.callCustomizationScriptFunction('ext_checkIfRobotIsAssociatedWithLocationFrameOrTrackingWindow',ragnars[i],model) then
            return ragnars[i]
        end
    end
    return -1
end

function sysCall_init()
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    local data=sim.readCustomDataBlock(model,simBWF.LOCATIONFRAME_TAG)
    data=sim.unpackTable(data)
    showPoints=sim.boolAnd32(data.bitCoded,16)>0
    isPick=(data.type==0)
    createParts=isPick and (sim.boolAnd32(data.bitCoded,8)>0)
    robot=getAssociatedRobotHandle()
    m=sim.getObjectMatrix(model,-1)
    sphereContainer=sim.addDrawingObject(sim.drawing_spherepoints,0.007,0,-1,9999,{1,0,1})
    online=simBWF.isSystemOnline()
    createdPartsInOnlineMode={}
    allProducedPartsInOnlineMode={}
end

function sysCall_sensing()
    local t=sim.getSimulationTime()
    local dt=sim.getSimulationTimeStep()
    sim.addDrawingObjectItem(sphereContainer,nil)
   
    if robot>0 then
        local data={}
        data.id=model
        local reply,retData=simBWF.query('locationFrame_getPoints',data)
        if simBWF.isInTestMode() then
            reply='ok'
            retData={}
            retData.points={{0,0,0.3}}
            retData.pointIds={1}
            retData.partIds={sim.getObjectHandle('genericBox#')}
        end
        if reply=='ok' then
            local pts=retData.points
            local ptIds=retData.pointIds
            if online then
                local partIds=retData.partIds
                for i=1,#pts,1 do
                    local ptRel=pts[i]
                    if showPoints then
                        local ptAbs=sim.multiplyVector(m,ptRel)
                        sim.addDrawingObjectItem(sphereContainer,ptAbs)
                    end
                    -- We create parts that were detected / that exist in the real world:
                    if createParts and partIds and partIds[i]>=0 and createdPartsInOnlineMode[partIds[i]]==nil then
                        local partData=simBWF.readPartInfo(partIds[i])
                        local vertMinMax=partData.vertMinMax
                        ptRel[1]=ptRel[1]-0.5*vertMinMax[1][2]-0.5*vertMinMax[1][1]
                        ptRel[2]=ptRel[2]-0.5*vertMinMax[2][2]-0.5*vertMinMax[2][1]
                        ptRel[3]=ptRel[3]-vertMinMax[3][2]
                        local itemPosition=sim.multiplyVector(m,ptRel)
                        local itemOrientation=sim.getEulerAnglesFromMatrix(m)
                        local baseHandleAndModelTag,auxPartsHandlesAndModelTags=partCreation_instanciatePart(partIds[i],model,nil,itemPosition,itemOrientation,nil,nil,nil,false)
                        partCreation_addToProducedPartsList(baseHandleAndModelTag,auxPartsHandlesAndModelTags,allProducedPartsInOnlineMode,t)
                        createdPartsInOnlineMode[partIds[i]]=true
                    end
                end
            else
                if showPoints then
                    for i=1,#pts,1 do
                        local ptRel=pts[i]
                        local ptAbs=sim.multiplyVector(m,ptRel)
                        sim.addDrawingObjectItem(sphereContainer,ptAbs)
                    end
                end
            end
        end
        partCreation_handleCreatedParts(allProducedPartsInOnlineMode,60,t,dt)
    end
end

