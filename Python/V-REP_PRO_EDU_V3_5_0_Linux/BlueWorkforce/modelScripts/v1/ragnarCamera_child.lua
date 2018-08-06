function ext_setCameraPoseFromCalibrationBallDetections(ragnarVisionHandle,absMatrix)
    if online then
        allDesiredModelPoses[ragnarVisionHandle]=absMatrix
        local m=nil
        local cnt=1
        for key,value in pairs(allDesiredModelPoses) do
            if m==nil then
                m=value
            else
                m=sim.interpolateMatrices(m,value,1/i)
            end
            cnt=cnt+1
        end
        if m then
            sim.setObjectMatrix(sensor,-1,m)
        else
            sim.setObjectMatrix(sensor,-1,sensorInitialMatrix)
        end
    end
end

function enableSimulatedCamera()
    if bwfPluginLoaded then
--[[        local data={}
        data.id=model
        data.imageProcessingParameters=imgProcessingParams
        simBWF.query('ragnarVision_connectSimulated',data)--]]
    end
end

function disableSimulatedCamera()
    if bwfPluginLoaded then
--[[        local data={}
        data.id=model
        simBWF.query('ragnarVision_disconnectSimulated',data)--]]
    end
end

function createSimulatedCameraDisplay()
    if bwfPluginLoaded then
        if imgToDisplay>0 then
            if not ui_simulationDisplay then
                local resDividers={4,2,1}
                local div=resDividers[imgSizeToDisplay+1]
                local w=sensorResolution[1]/div
                local h=sensorResolution[2]/div
                local xml='<image id="1" width="'..w..'" height="'..h..'"/>'
                local prevPos,prevSiz=simBWF.readSessionPersistentObjectData(model,"visionImgDlgPosSim")
                if prevPos and prevSiz~=imgSizeToDisplay then
                    prevPos=nil
                    simBWF.writeSessionPersistentObjectData(model,"visionImgDlgPosSim",nil)
                end
                if not prevPos then
                    prevPos='bottomRight'
                end
                ui_simulationDisplay=simBWF.createCustomUi(xml,simBWF.getObjectAltName(model),prevPos,true,'removeSimulatedCameraDisplay'--[[,modal,resizable,activate,additionalUiAttribute--]])
                return true
            end
        end
    end
    return false
end

function removeSimulatedCameraDisplay()
    if ui_simulationDisplay then
        local x,y=simUI.getPosition(ui_simulationDisplay)
        simBWF.writeSessionPersistentObjectData(model,"visionImgDlgPosSim",{x,y},imgSizeToDisplay)
        simUI.destroy(ui_simulationDisplay)
        ui_simulationDisplay=nil
    end
end

function updateDataFromSimulatedCamera()
    if bwfPluginLoaded then
        local res,nclipp=sim.getObjectFloatParameter(sensor,sim.visionfloatparam_near_clipping)
        local res,fclipp=sim.getObjectFloatParameter(sensor,sim.visionfloatparam_far_clipping)
        local rgbRaw=sim.getVisionSensorCharImage(sensor)
        local depthRaw=sim.getVisionSensorDepthBuffer(sensor+sim.handleflag_codedstring)
        depth=sim.transformBuffer(depthRaw,sim.buffer_float,1000*(fclipp-nclipp),1000*nclipp,sim.buffer_uint16)
        local data={}
        data.id=model
        data.resolution=sensorResolution
        data.depth=depth
        data.color=rgbRaw
        simBWF.query('ragnarCamera_setSimulatedImage',data)

        local t=(sim.getSimulationTime()+sim.getSimulationTimeStep())*1000
        if (t+1>lastImgUpdateTimeInMs+imgUpdateFrequMs) and ui_simulationDisplay then
            lastImgUpdateTimeInMs=t
            local resDividers={4,2,1}
            local div=resDividers[imgSizeToDisplay+1]
            local image=nil
            if imgToDisplay==1 then -- rgb
                image=rgbRaw
            end
            if imgToDisplay==2 then -- depth
                image=sim.transformBuffer(depthRaw,sim.buffer_float,255,0,sim.buffer_uint8rgb)
            end
            if div~=1 then -- Scaling
                image=sim.getScaledImage(image,{sensorResolution[1],sensorResolution[2]},{sensorResolution[1]/div,sensorResolution[2]/div},0)
            end
            simUI.setImageData(ui_simulationDisplay,1,image,sensorResolution[1]/div,sensorResolution[2]/div)
        end
    end
end

function enableRealCamera()
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

function disableRealCamera()
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

function createRealCameraDisplay()
    if bwfPluginLoaded then
        if imgToDisplay>0 then
            if not ui_realDisplay then
                -- We need the resolution of the real camera:
                local data={}
                data.id=model
                data.type='none'
                data.frequency=-2+1000/imgUpdateFrequMs
                local result,retData=simBWF.query('ragnarCamera_getRealImage',data)
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
                    local prevPos,prevSiz=simBWF.readSessionPersistentObjectData(model,"visionImgDlgPosReal")
                    if prevPos and prevSiz~=imgSizeToDisplay then
                        prevPos=nil
                        simBWF.writeSessionPersistentObjectData(model,"visionImgDlgPosReal",nil)
                    end
                    if not prevPos then
                        prevPos='bottomRight'
                    end
                    ui_realDisplay=simBWF.createCustomUi(xml,simBWF.getObjectAltName(model),prevPos,true,'removeRealCameraDisplay'--[[,modal,resizable,activate,additionalUiAttribute--]])
                    return true
                end
            end
        end
    end
    return false
end

function removeRealCameraDisplay()
    if ui_realDisplay then
        local x,y=simUI.getPosition(ui_realDisplay)
        simBWF.writeSessionPersistentObjectData(model,"visionImgDlgPosReal",{x,y},imgSizeToDisplay)
        simUI.destroy(ui_realDisplay)
        ui_realDisplay=nil
    end
end

function updateDataFromRealCamera()
    if ui_realDisplay and bwfPluginLoaded then -- realCamera_initialCameraTransform
        local c=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.RAGNARCAMERA_TAG))
        local data={}
        data.id=model
        local tp={'none','color','depth'}
        data.type=tp[imgToDisplay+1]
        data.frequency=-2+1000/imgUpdateFrequMs
       
        local dt=sim.getSystemTimeInMs(lastImgUpdateTimeInMs)
        if (dt>imgUpdateFrequMs) and (ui_realDisplay~=nil) and data.type~='none' then
            lastImgUpdateTimeInMs=sim.getSystemTimeInMs(-1)

            
            local result,retData=simBWF.query('ragnarCamera_getRealImage',data)
            local testing=simBWF.isInTestMode()
            local image=nil
            if not testing then
                if result=="ok" then
--                    if retData.ball1 then
--                        local m=simBWF.getMatrixFromCalibrationBallPositions(retData.ball1,retData.ball2,retData.ball3,true)
--                        sim.invertMatrix(m)
--                        sim.setObjectMatrix(sensor,calibrationBalls[1],m)
--                    end
                    image=retData.image
--                    if image then
--                        sim.transformImage(image,sensorResolution,2) -- we receive the image flipped along the x axis. Correct that
--                    end
                end
            else
            --[[
                local ampl=0.01
                local off=-ampl*0.5
                local p1={-0.2-off+math.random()*ampl,-0.075-off+math.random()*ampl,0.4553-off+math.random()*ampl}
                local p2={-0.2-off+math.random()*ampl,0.1-off+math.random()*ampl,0.455-off+math.random()*ampl}
                local p3={0.16-off+math.random()*ampl,0.09-off+math.random()*ampl,0.455-off+math.random()*ampl}
                local m=simBWF.getMatrixFromCalibrationBallPositions(p1,p2,p3,true)
                sim.invertMatrix(m)
                sim.setObjectMatrix(sensor,calibrationBalls[1],m)
                --]]
            end
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
            simUI.setImageData(ui_realDisplay,1,image,w/div,h/div)
        end
    end
end

function sysCall_init()
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    sensor=sim.getObjectHandle('RagnarCamera_sensor')
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    sensorInitialMatrix=sim.getObjectMatrix(sensor,-1)
    allDesiredModelPoses={}

    online=simBWF.isSystemOnline()
    simOrRealIndex=1
    lastImgUpdateTimeInMs=-1000
    if online then
        simOrRealIndex=2
        lastImgUpdateTimeInMs=sim.getSystemTimeInMs(-1)-1000
    end
    local properties=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.RAGNARCAMERA_TAG))
    sensorResolution=properties.resolution
    
--    imgProcessingParams=properties.imgProcessingParams[simOrRealIndex]
    imgToDisplay=properties.imgToDisplay[simOrRealIndex]
    imgSizeToDisplay=properties.imgSizeToDisplay[simOrRealIndex]
    
    lastImgToDisplay=-1
    lastImgSizeToDisplay=imgSizeToDisplay-- -1
    
    if online then
        enableRealCamera()
    else
        enableSimulatedCamera()
    end
end

function sysCall_sensing()
    local properties=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.RAGNARCAMERA_TAG))
    imgToDisplay=properties.imgToDisplay[simOrRealIndex]
    imgSizeToDisplay=properties.imgSizeToDisplay[simOrRealIndex]
    local delaysInMs={50,200,1000}
    imgUpdateFrequMs=delaysInMs[properties.imgUpdateFrequ[simOrRealIndex]+1]

    if bwfPluginLoaded then
        if online then
            if lastImgToDisplay~=imgToDisplay or lastImgSizeToDisplay~=imgSizeToDisplay then
                removeRealCameraDisplay()
                if lastImgSizeToDisplay~=imgSizeToDisplay then
                    simBWF.writeSessionPersistentObjectData(model,"visionImgDlgPosReal",nil)
                end
                if createRealCameraDisplay() then
                    lastImgToDisplay=imgToDisplay
                    lastImgSizeToDisplay=imgSizeToDisplay
                end
            end
            updateDataFromRealCamera()
        else
            sim.handleVisionSensor(sensor)
            if lastImgToDisplay~=imgToDisplay or lastImgSizeToDisplay~=imgSizeToDisplay then
                removeSimulatedCameraDisplay()
                if lastImgSizeToDisplay~=imgSizeToDisplay then
                    simBWF.writeSessionPersistentObjectData(model,"visionImgDlgPosSim",nil)
                end
                if createSimulatedCameraDisplay() then
                    lastImgToDisplay=imgToDisplay
                    lastImgSizeToDisplay=imgSizeToDisplay
                end
            end
            updateDataFromSimulatedCamera()
        end
    end
end


function sysCall_cleanup()
    if online then
        removeRealCameraDisplay()
        disableRealCamera()
    else
        removeSimulatedCameraDisplay()
        disableSimulatedCamera()
    end
    sim.setObjectMatrix(sensor,-1,sensorInitialMatrix)
end

