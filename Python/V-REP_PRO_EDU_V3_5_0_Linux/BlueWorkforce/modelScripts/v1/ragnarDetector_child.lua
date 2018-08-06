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
    showDetections=false
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    calibrationBalls={model}
    for i=2,3,1 do
        calibrationBalls[i]=sim.getObjectHandle('RagnarDetector_calibrationBall'..i)
    end
    online=simBWF.isSystemOnline()
    local properties=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.RAGNARDETECTOR_TAG))
    
    showDetections=sim.boolAnd32(properties.bitCoded,4)~=0
    sphereContainer=sim.addDrawingObject(sim.drawing_spherepoints,0.007,0,-1,9999,{1,0,0})


    detectorBox=sim.getObjectHandle('RagnarDetector_detectorBox')
    detector=sim.getObjectHandle('RagnarDetector_detectorSensor')
    ball1Mi=sim.getObjectMatrix(model,-1)
    sim.invertMatrix(ball1Mi)
    boxSize=getObjectSize(detectorBox)
    alreadyFakeDetectedAndTransmittedParts={}
end

function sysCall_sensing()
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
        simBWF.query('ragnarDetector_detections',dataToTransmit)
    end
    for key,value in pairs(alreadyFakeDetectedAndTransmittedParts) do
        if t-value>2 then
            alreadyFakeDetectedAndTransmittedParts[key]=nil
        end
    end
end


function sysCall_cleanup()
end

