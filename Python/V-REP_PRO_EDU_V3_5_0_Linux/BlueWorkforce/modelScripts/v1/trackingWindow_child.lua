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
    local data=sim.readCustomDataBlock(model,simBWF.TRACKINGWINDOW_TAG)
    data=sim.unpackTable(data)
    showPoints=sim.boolAnd32(data.bitCoded,4)>0
    isPick=(data.type==0)
    createParts=isPick and (sim.boolAnd32(data.bitCoded,8)>0)
    robot=getAssociatedRobotHandle()
    if robot>=0 then
        robotRef=simBWF.callCustomizationScriptFunction('ext_getReferenceObject',robot)
        robotRefM=sim.getObjectMatrix(robotRef,-1)
        local mRelRef=sim.getObjectMatrix(model,robotRef)
        local dat=simBWF.callCustomizationScriptFunction('ext_getCalibrationDataForCurrentMode',model)
        calibrationMDat=dat.matrix -- data.calibrationMatrix
        calibrationM=calibrationMDat
        if not calibrationMDat then
            calibrationM=mRelRef
        end
    end
    m=sim.getObjectMatrix(model,-1)
    mi=sim.getObjectMatrix(model,-1)
    sim.invertMatrix(mi)
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
        robotRefM=sim.getObjectMatrix(robotRef,-1)
        local mRelRef=sim.getObjectMatrix(model,robotRef)
        if not calibrationMDat then
            calibrationM=mRelRef
        end
        local data={}
        data.id=model
        local reply,retData=simBWF.query('trackingWindow_getPoints',data)
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
                    local ptMRel=sim.buildMatrix(ptRel,{0,0,0})
                    -- We transform the position of the point in order to correct for calibration errors:
                    local dist=-ptMRel[4]
                    local tr=1-(dist-0.3)/0.3
                    if tr>1 then tr=1 end
                    if tr<0 then tr=0 end
                    if showPoints then
                        local mFar=sim.multiplyMatrices(m,ptMRel)
                        local mClose=sim.multiplyMatrices(calibrationM,ptMRel)
                        local mClose=sim.multiplyMatrices(robotRefM,mClose)
                        local theMatr=sim.interpolateMatrices(mFar,mClose,tr)
                        local dat={theMatr[4],theMatr[8],theMatr[12]}
                        sim.addDrawingObjectItem(sphereContainer,dat)
                    end
                    -- We create parts that were detected in the real world (but only when the position is correct in simulation):
                    if createParts and partIds and partIds[i]>=0 and tr==1 and createdPartsInOnlineMode[ptIds[i]]==nil then
                        local partData=simBWF.readPartInfo(partIds[i])
                        local vertMinMax=partData.vertMinMax
                        ptRel[1]=ptRel[1]-0.5*vertMinMax[1][2]-0.5*vertMinMax[1][1]
                        ptRel[2]=ptRel[2]-0.5*vertMinMax[2][2]-0.5*vertMinMax[2][1]
                        ptRel[3]=ptRel[3]-vertMinMax[3][2]
                        local itemPosition=sim.multiplyVector(m,ptRel)
                        local itemOrientation=sim.getEulerAnglesFromMatrix(m)
                        local baseHandleAndModelTag,auxPartsHandlesAndModelTags=partCreation_instanciatePart(partIds[i],model,nil,itemPosition,itemOrientation,nil,nil,nil,false)
                        partCreation_addToProducedPartsList(baseHandleAndModelTag,auxPartsHandlesAndModelTags,allProducedPartsInOnlineMode,t)
                        createdPartsInOnlineMode[ptIds[i]]=true
                    end
                end
            else
                 if showPoints then
                     for i=1,#pts,1 do
                        local ptRel=pts[i]
                        local ptMRel=sim.buildMatrix(ptRel,{0,0,0})
                        -- We transform the position of the point in order to correct for calibration errors:
                        local dist=-ptMRel[4]
                        local mFar=sim.multiplyMatrices(m,ptMRel)
                        local mClose=sim.multiplyMatrices(calibrationM,ptMRel)
                        local mClose=sim.multiplyMatrices(robotRefM,mClose)
                        local tr=1-(dist-0.3)/0.3
                        if tr>1 then tr=1 end
                        if tr<0 then tr=0 end
                        local theMatr=sim.interpolateMatrices(mFar,mClose,tr)
                        local dat={theMatr[4],theMatr[8],theMatr[12]}
                        sim.addDrawingObjectItem(sphereContainer,dat)
                    end
                end
            end
        end
        partCreation_handleCreatedParts(allProducedPartsInOnlineMode,60,t,dt)
    end
end

