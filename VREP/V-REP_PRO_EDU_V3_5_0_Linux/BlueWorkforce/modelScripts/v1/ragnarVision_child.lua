function enableRagnarVision()
--[[
    if not realCamera_initialCameraTransform then
        realCamera_initialCameraTransform=sim.getObjectMatrix(sensor,model)
        if bwfPluginLoaded then
            local data={}
            data.id=model
            data.imageProcessingParameters=imgProcessingParams
            simBWF.query('ragnarVision_connectReal',data)
        end
    end
    --]]
end

function disableRagnarVision()
--[[
    if realCamera_initialCameraTransform then
        if bwfPluginLoaded then
            local data={}
            data.id=model
            simBWF.query('ragnarVision_disconnectReal',data)
        end
        sim.setObjectMatrix(sensor,model,realCamera_initialCameraTransform)
        realCamera_initialCameraTransform=nil
    end
    --]]
end

function createRagnarVisionDisplay()
    if bwfPluginLoaded and camera>=0 then
        if imgToDisplay>0 then
            if not ui_display then
                -- We need the resolution of the real camera:
                local data={}
                data.id=model
                data.type='none'
                data.frequency=-2+1000/imgUpdateFrequMs
                local result,retData=simBWF.query('ragnarVision_getImage',data)
                if result=='ok' then
                    sensorResolution=retData.resolution
                else
                    if simBWF.isInTestMode() then
                        if not _staticVarTesting then
                            _staticVarTesting=0
                        end
                        _staticVarTesting=_staticVarTesting+1
                        if _staticVarTesting==5 then
                            sensorResolution={640,480}
                            result='ok'
                        end
                    end
                end
                if result=='ok' then
                    local resDividers={4,2,1}
                    local div=resDividers[imgSizeToDisplay+1]
                    local w=sensorResolution[1]/div
                    local h=sensorResolution[2]/div
                    local xml='<image id="1" width="'..w..'" height="'..h..'"/>'
                    local prevPos,prevSiz=simBWF.readSessionPersistentObjectData(model,"visionImgDlgPos")
                    if prevPos and prevSiz~=imgSizeToDisplay then
                        prevPos=nil
                        simBWF.writeSessionPersistentObjectData(model,"visionImgDlgPos",nil)
                    end
                    if not prevPos then
                        prevPos='bottomRight'
                    end
                    ui_display=simBWF.createCustomUi(xml,simBWF.getObjectAltName(model),prevPos,true,'removeRagnarVisionDisplay'--[[,modal,resizable,activate,additionalUiAttribute--]])
                    return true
                end
            end
        end
    end
    return false
end

function removeRagnarVisionDisplay()
    if ui_display then
        local x,y=simUI.getPosition(ui_display)
        simBWF.writeSessionPersistentObjectData(model,"visionImgDlgPos",{x,y},imgSizeToDisplay)
        simUI.destroy(ui_display)
        ui_display=nil
    end
end

function updateDataFromRagnarVision()
    if bwfPluginLoaded and camera>=0 and ui_display then
--        local c=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.RAGNARVISION_TAG))
        local data={}
        data.id=model
        local tp={'none','processed'}
       
        local dt=sim.getSystemTimeInMs(lastImgUpdateTimeInMs)
        if (dt>imgUpdateFrequMs) and (ui_display~=nil) then
            data.type=tp[imgToDisplay+1]
            lastImgUpdateTimeInMs=sim.getSystemTimeInMs(-1)
        else
            data.type=tp[1] -- i.e. 'none'
        end
        if imgToDisplay==0 then
            data.frequency=0
        else
            data.frequency=-2+1000/imgUpdateFrequMs
        end
        local result,retData=simBWF.query('ragnarVision_getImage',data)
        local testing=simBWF.isInTestMode()
        local image=nil
        if not testing then
            if result=="ok" then
                if retData.ball1 then
                    local m=simBWF.getMatrixFromCalibrationBallPositions(retData.ball1,retData.ball2,retData.ball3,true)
                    sim.invertMatrix(m)
                    m=sim.multiplyMatrices(sim.getObjectMatrix(model,-1),m)
                    simBWF.callChildScriptFunction_noError("ext_setCameraPoseFromCalibrationBallDetections",camera,model,m)
                else
                    simBWF.callChildScriptFunction_noError("ext_setCameraPoseFromCalibrationBallDetections",camera,model,nil)
                end
                image=retData.image
--                if image then
--                    sim.transformImage(image,sensorResolution,2) -- we receive the image flipped along the x axis. Correct that
--                end
            end
        else
            local ampl=0.01
            local off=-ampl*0.5
            local p1={-0.2-off+math.random()*ampl,-0.075-off+math.random()*ampl,0.4553-off+math.random()*ampl}
            local p2={-0.2-off+math.random()*ampl,0.1-off+math.random()*ampl,0.455-off+math.random()*ampl}
            local p3={0.16-off+math.random()*ampl,0.09-off+math.random()*ampl,0.455-off+math.random()*ampl}
            local m=simBWF.getMatrixFromCalibrationBallPositions(p1,p2,p3,true)
            sim.invertMatrix(m)
            m=sim.multiplyMatrices(sim.getObjectMatrix(model,-1),m)
            simBWF.callChildScriptFunction_noError("ext_setCameraPoseFromCalibrationBallDetections",camera,model,m)
        end
        if ui_display then
            if data.type~='none' then
                if not image then
                    if not sstaticBla then sstaticBla=0 end
                    sstaticBla=sstaticBla+60
                    if sstaticBla>255 then sstaticBla=sstaticBla-255 end
                    local ttmp=sim.packUInt8Table({sstaticBla,0,255-sstaticBla})
                    image=string.rep(ttmp,sensorResolution[1]*sensorResolution[2])
                end
                local resDividers={4,2,1}
                local div=resDividers[imgSizeToDisplay+1]
                local w=sensorResolution[1]
                local h=sensorResolution[2]
                if div~=1 then
                    image=sim.getScaledImage(image,{w,h},{w/div,h/div},0)
                end
                simUI.setImageData(ui_display,1,image,w/div,h/div)
            end
        end
    end
end

function getFakeDetectedPartsInWindow()
    local m=sim.getObjectMatrix(detectorBox,-1)
    local op=sim.getObjectPosition(detector,detectorBox)
    local l=sim.getObjectsInTree(sim.handle_scene,sim.object_shape_type,0)
    local retL={}
    for i=1,#l,1 do
        local isPart,isInstanciated,data=simBWF.isObjectPartAndInstanciated(l[i])
        if isInstanciated then
            local p=sim.getObjectPosition(l[i],detectorBox)
            if (math.abs(p[1])<boxSize[1]*0.5) and (math.abs(p[2])<boxSize[2]*0.5) and (math.abs(p[3])<boxSize[3]*0.5) then
                sim.setObjectPosition(detector,detectorBox,{p[1],p[2],op[3]})
                local r,dist,pt,obj,n=sim.handleProximitySensor(detector)
                if r>0 then
                    -- Only if we detected the same object (there might be overlapping objects)
                    while obj~=-1 do
                        local data2=sim.readCustomDataBlock(obj,simBWF.PART_TAG)
                        if data2 then
                            break
                        end
                        obj=sim.getObjectParent(obj)
                    end
                    if obj==l[i] then
                        p=sim.multiplyVector(m,{p[1],p[2],op[3]-dist})
                        retL[#retL+1]={id=l[i],type=data.type,pos=p,name=data.name,destination=data.destination}
                    end
                end
            end
        end
    end
    return retL
end

function getObjectSize(h)
    local r,mmin=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_min_x)
    local r,mmax=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_max_x)
    local sx=mmax-mmin
    local r,mmin=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_min_y)
    local r,mmax=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_max_y)
    local sy=mmax-mmin
    local r,mmin=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_min_z)
    local r,mmax=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_max_z)
    local sz=mmax-mmin
    return {sx,sy,sz}
end

function sysCall_init()
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    camera=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARVISION_CAMERA_REF)
    --[[
    cameraSensor=-1
    if camera>=0 then
        local objs=sim.getObjectsInTree(camera,sim.object_visionsensor_type)
        cameraSensor=objs[1]
        realSensorM=sim.getObjectMatrix(cameraSensor,-1)
    end
    --]]
    calibrationBalls={model}
    for i=2,3,1 do
        calibrationBalls[i]=sim.getObjectHandle('RagnarVision_calibrationBall'..i)
    end
    online=simBWF.isSystemOnline()
    simOrRealIndex=1
    lastImgUpdateTimeInMs=-1000
    if online then
        simOrRealIndex=2
        lastImgUpdateTimeInMs=sim.getSystemTimeInMs(-1)-1000
    end
    local properties=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.RAGNARVISION_TAG))
    fakeDetection=sim.boolAnd32(properties.bitCoded,8)~=0
    showDetections=sim.boolAnd32(properties.bitCoded,4)~=0
    
--    imgProcessingParams=properties.imgProcessingParams[simOrRealIndex]
    imgToDisplay=properties.imgToDisplay[simOrRealIndex]
    imgSizeToDisplay=properties.imgSizeToDisplay[simOrRealIndex]
    
    lastImgToDisplay=-1
    lastImgSizeToDisplay=imgSizeToDisplay-- -1
    sphereContainer=sim.addDrawingObject(sim.drawing_spherepoints,0.007,0,-1,9999,{1,0,0})


    detectorBox=sim.getObjectHandle('RagnarVision_detectorBox')
    detector=sim.getObjectHandle('RagnarVision_detectorSensor')
    ball1M=sim.getObjectMatrix(model,-1)
    ball1Mi=sim.getObjectMatrix(model,-1)
    sim.invertMatrix(ball1Mi)
    boxSize=getObjectSize(detectorBox)
    alreadyFakeDetectedAndTransmittedParts={}
    
    enableRagnarVision()
end

function sysCall_sensing()
    local properties=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.RAGNARVISION_TAG))
    imgToDisplay=properties.imgToDisplay[simOrRealIndex]
    imgSizeToDisplay=properties.imgSizeToDisplay[simOrRealIndex]
    local delaysInMs={50,200,1000}
    imgUpdateFrequMs=delaysInMs[properties.imgUpdateFrequ[simOrRealIndex]+1]

    if bwfPluginLoaded and camera>=0 then
        if lastImgToDisplay~=imgToDisplay or lastImgSizeToDisplay~=imgSizeToDisplay then
            removeRagnarVisionDisplay()
            if lastImgSizeToDisplay~=imgSizeToDisplay then
                simBWF.writeSessionPersistentObjectData(model,"visionImgDlgPos",nil)
            end
            if createRagnarVisionDisplay() then
                lastImgToDisplay=imgToDisplay
                lastImgSizeToDisplay=imgSizeToDisplay
            end
        end
        updateDataFromRagnarVision()
    end
    
    if camera>=0 then
        if not fakeDetection then
            sim.addDrawingObjectItem(sphereContainer,nil)
            if showDetections then
                local data={}
                data.id=model
                local reply,retData=simBWF.query('ragnarVision_getPoints',data)
                if simBWF.isInTestMode() then
                    reply='ok'
                    retData={}
                    retData.points={{0.1,0.2,0.003}}
                end
                if reply=='ok' then
                    local pts=retData.points
                    for i=1,#pts,1 do
                        local ptRel=pts[i]
                        local ptAbs=sim.multiplyVector(ball1M,ptRel)
                        sim.addDrawingObjectItem(sphereContainer,ptAbs)
                    end
                end
            end
        else
            -- Following for the fake detection:
            local t=sim.getSimulationTime()
            local detected=getFakeDetectedPartsInWindow()
            sim.addDrawingObjectItem(sphereContainer,nil)
            local dataToTransmit={}
            dataToTransmit.id=model
            dataToTransmit.pos={}
            dataToTransmit.types={}
            dataToTransmit.names={}
            dataToTransmit.destinations={}
            for i=1,#detected,1 do
                local id=detected[i].id
                if not alreadyFakeDetectedAndTransmittedParts[id] then
                    local p=sim.multiplyVector(ball1Mi,detected[i].pos) -- the point is now relative to the red calibration ball
                    dataToTransmit.pos[#dataToTransmit.pos+1]=p
                    dataToTransmit.types[#dataToTransmit.types+1]=detected[i].type
                    dataToTransmit.names[#dataToTransmit.names+1]=detected[i].name
                    dataToTransmit.destinations[#dataToTransmit.destinations+1]=detected[i].destination
                    alreadyFakeDetectedAndTransmittedParts[id]=t
                end
                if showDetections then
                    sim.addDrawingObjectItem(sphereContainer,detected[i].pos)
                end
            end
            if #dataToTransmit.types>0 then
                simBWF.query('ragnarVision_detections',dataToTransmit)
            end
            for key,value in pairs(alreadyFakeDetectedAndTransmittedParts) do
                if t-value>2 then
                    alreadyFakeDetectedAndTransmittedParts[key]=nil
                end
            end
        end
    end
end


function sysCall_cleanup()
    removeRagnarVisionDisplay()
    disableRagnarVision()
end

