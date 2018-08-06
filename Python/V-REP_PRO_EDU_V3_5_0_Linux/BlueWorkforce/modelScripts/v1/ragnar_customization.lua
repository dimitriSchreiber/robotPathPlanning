function ext_isPickWithoutTargetOverridden()
    local c=readInfo()
    return sim.boolAnd32(c['bitCoded'],2048)>0
end

function ext_getItemData_pricing()
    local c=readInfo()
    local obj={}
    obj.name=simBWF.getObjectAltName(model)
    obj.type='ragnar'
    obj.ragnarType='default'
    obj.brVersion=1
    obj.motors=MOTORTYPES[c.motorType].pricingText
    obj.exterior=EXTERIORTYPES[c.exteriorType].pricingText
    obj.frame=FRAMETYPES[c.frameType].pricingText
    obj.primary_arms=c.primaryArmLengthInMM
    obj.secondary_arms=c.secondaryArmLengthInMM
    local dep={}
    for i=1,CIC,1 do
        local ids={}
        ids[1]=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+i-1)
        ids[2]=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+i-1)
        ids[3]=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKFRAME1_REF+i-1)
        ids[4]=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACEFRAME1_REF+i-1)
        for j=1,4,1 do
            if ids[j]>=0 then
                dep[#dep+1]=simBWF.getObjectAltName(ids[j])
            end
        end
    end
    if platform>=0 then
        obj.gripper_platform=simBWF.callCustomizationScriptFunction('ext_getItemData_pricing',platform)
--        dep[#dep+1]=simBWF.getObjectAltName(platform)
        local grip=getGripper(platform)
        if grip>=0 then
            obj.gripper=simBWF.callCustomizationScriptFunction('ext_getItemData_pricing',grip)
        end
    end
    if #dep>0 then
        obj.dependencies=dep
    end
    obj.software_configuration={}
    obj.software_configuration.ragnar_joint1_base_x=sim.getObjectPosition(motorJoints[1],ragnarRef)[1]
    obj.software_configuration.ragnar_joint1_base_y=sim.getObjectPosition(motorJoints[1],ragnarRef)[2]
    obj.software_configuration.ragnar_joint2_base_x=sim.getObjectPosition(motorJoints[2],ragnarRef)[1]
    obj.software_configuration.ragnar_joint2_base_y=sim.getObjectPosition(motorJoints[2],ragnarRef)[2]
    obj.software_configuration.ragnar_joint3_base_x=sim.getObjectPosition(motorJoints[3],ragnarRef)[1]
    obj.software_configuration.ragnar_joint3_base_y=sim.getObjectPosition(motorJoints[3],ragnarRef)[2]
    obj.software_configuration.ragnar_joint4_base_x=sim.getObjectPosition(motorJoints[4],ragnarRef)[1]
    obj.software_configuration.ragnar_joint4_base_y=sim.getObjectPosition(motorJoints[4],ragnarRef)[2]
    obj.software_configuration.ragnar_joint1_base_tilt=tiltAdjustmentAngles[1]
    obj.software_configuration.ragnar_joint2_base_tilt=tiltAdjustmentAngles[2]
    obj.software_configuration.ragnar_joint3_base_tilt=tiltAdjustmentAngles[3]
    obj.software_configuration.ragnar_joint4_base_tilt=tiltAdjustmentAngles[4]
    obj.software_configuration.ragnar_joint1_base_pan=panAdjustmentAngles[1]
    obj.software_configuration.ragnar_joint2_base_pan=panAdjustmentAngles[2]
    obj.software_configuration.ragnar_joint3_base_pan=panAdjustmentAngles[3]
    obj.software_configuration.ragnar_joint4_base_pan=panAdjustmentAngles[4]
    obj.software_configuration.belt_encoder_E1_enable=false
    obj.software_configuration.belt_encoder_E2_enable=false
    obj.software_configuration.LATCH_E1_enabled=false
    obj.software_configuration.LATCH_E2_enabled=false
    local off=1
    local windowsTmp={}
    for i=1,CIC,1 do
        local tmp=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+i-1)
        if tmp>=0 then
            windowsTmp[off]=tmp
            off=off+1
        end
        local tmp=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+i-1)
        if tmp>=0 then
            windowsTmp[off]=tmp
            off=off+1
        end
    end
    if #windowsTmp>0 then
        obj.software_configuration.belt_encoder_E1_enable=true
        local s=simBWF.callCustomizationScriptFunction('ext_getAssociatedSensorDetectorOrVisionHandle',windowsTmp[1])
        obj.software_configuration.LATCH_E1_enabled=(sim.readCustomDataBlock(s,simBWF.RAGNARSENSOR_TAG)~=nil)
    end
    if #windowsTmp>1 then
        obj.software_configuration.belt_encoder_E2_enable=true
        local s=simBWF.callCustomizationScriptFunction('ext_getAssociatedSensorDetectorOrVisionHandle',windowsTmp[2])
        obj.software_configuration.LATCH_E2_enabled=(sim.readCustomDataBlock(s,simBWF.RAGNARSENSOR_TAG)~=nil)
    end
    return obj
end

function ext_checkIfRobotIsAssociatedWithGripperPlatform(id)
    if id>=0 then
        return id==platform
    end
    return false
end

function ext_checkIfRobotIsAssociatedWithLocationFrameOrTrackingWindow(id)
    for i=1,CIC,1 do
        if simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+i-1)==id then
            return true
        end
        if simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+i-1)==id then
            return true
        end
        if simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKFRAME1_REF+i-1)==id then
            return true
        end
        if simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACEFRAME1_REF+i-1)==id then
            return true
        end
    end
    return false
end

function ext_getReferenceObject()
    return ragnarRef
end

function ext_getConnectedConveyors()
    local retValue={simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_CONVEYOR1_REF),simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_CONVEYOR2_REF)}
    return retValue
end

function ext_outputBrSetupMessages()
    local nm=' ['..simBWF.getObjectAltName(model)..']'
    local msg=""
    if platform<0 then
        msg="WARNING (set-up): Has no attached gripper platform"..nm
    else
        if getGripper(platform)<0 then
            msg="WARNING (set-up): Gripper platform has no attached gripper"..nm
        else
            local pickPlace={false,false}
            for i=1,CIC,1 do
                if simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+i-1)>=0 then
                    pickPlace[1]=true
                end
                if simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+i-1)>=0 then
                    pickPlace[2]=true
                end
                if simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKFRAME1_REF+i-1)>=0 then
                    pickPlace[1]=true
                end
                if simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACEFRAME1_REF+i-1)>=0 then
                    pickPlace[2]=true
                end
            end
            if not pickPlace[1] then
                msg="WARNING (set-up): Has no associated pick location frame or pick tracking window"..nm
            else
                if not pickPlace[2] then
                    msg="WARNING (set-up): Has no associated place location frame or place tracking window"..nm
                end
            end
        end
    end
    if #msg>0 then
        simBWF.outputMessage(msg)
    end
end

function ext_outputPluginSetupMessages()
    if bwfPluginLoaded then
        local nm=' ['..simBWF.getObjectAltName(model)..']'
        local msg=""
        local data={}
        data.id=model
        local result,msgs=simBWF.query('get_objectSetupMessages',data)
        if result=='ok' then
            for i=1,#msgs.messages,1 do
                if msg~='' then
                    msg=msg..'\n'
                end
                msg=msg..msgs.messages[i]..nm
            end
        end
        if #msg>0 then
            simBWF.outputMessage(msg)
        end
    end
end

function ext_outputPluginRuntimeMessages()
    if bwfPluginLoaded then
        local nm=' ['..simBWF.getObjectAltName(model)..']'
        local msg=""
        local data={}
        data.id=model
        local result,msgs=simBWF.query('get_objectRuntimeMessages',data)
        if result=='ok' then
            for i=1,#msgs.messages,1 do
                if msg~='' then
                    msg=msg..'\n'
                end
                msg=msg..msgs.messages[i]..nm
            end
        end
        if #msg>0 then
            simBWF.outputMessage(msg)
        end
    end
end

function removeFromPluginRepresentation()
    if bwfPluginLoaded then
        local data={}
        data.id=model
        simBWF.query('object_delete',data)
    end
end

function updatePluginRepresentation()
    if bwfPluginLoaded then
        local c=readInfo()
        local data={}
        data.id=model
        data.name=simBWF.getObjectAltName(model)
        data.alias=c.robotAlias
        data.deviceId=''
        if c.deviceId~=simBWF.NONE_TEXT then
            data.deviceId=c.deviceId
        end
        data.primaryArmLength=c.primaryArmLengthInMM/1000
        data.secondaryArmLength=c.secondaryArmLengthInMM/1000
        data.platformId=platform
        data.pickTrackingWindows={}
        data.placeTrackingWindows={}
        data.pickFrames={}
        data.placeFrames={}
        data.robotAlias=c.robotAlias
        data.motorType=c.motorType
        for i=1,CIC,1 do
            data.pickTrackingWindows[i]=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+i-1)
            data.placeTrackingWindows[i]=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+i-1)
            data.pickFrames[i]=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKFRAME1_REF+i-1)
            data.placeFrames[i]=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACEFRAME1_REF+i-1)
            -- trigger a window/location frame plugin update (the robot pose might have changed):
            if data.pickTrackingWindows[i]~=-1 then
                simBWF.callCustomizationScriptFunction('ext_associatedRobotChangedPose',data.pickTrackingWindows[i])
            end
            if data.placeTrackingWindows[i]~=-1 then
                simBWF.callCustomizationScriptFunction('ext_associatedRobotChangedPose',data.placeTrackingWindows[i])
            end
        end
        data.conveyors={simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_CONVEYOR1_REF),simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_CONVEYOR2_REF)}
        data.wsBox=c.wsBox
 
        simBWF.query('ragnar_update',data)
 
        lastTransmittedData={}
        lastTransmittedData.pickTrackingWindows=data.pickTrackingWindows
        lastTransmittedData.placeTrackingWindows=data.placeTrackingWindows
        lastTransmittedData.pickFrames=data.pickFrames
        lastTransmittedData.placeFrames=data.placeFrames
        lastTransmittedData.platformId=data.platformId
        -- Following not really transmitted, but required to track pose change in updatePluginRepresentation_ifNeeded
        lastTransmittedData.robotPose={sim.getObjectPosition(model,-1),sim.getObjectOrientation(model,-1)}
        
        updatePluginRepresentation_dynParams()
    end
end

function updatePluginRepresentation_ifNeeded()
    -- To track general type data change that might be modified by V-REP directly:
    if lastTransmittedData then
        local update=false
        if platform~=lastTransmittedData.platformId then
            update=true
        end
        local pos=sim.getObjectPosition(model,-1)
        local orient=sim.getObjectOrientation(model,-1)
        for i=1,3,1 do
            if pos[i]~=lastTransmittedData.robotPose[1][i] then
                update=true
                break
            end
            if orient[i]~=lastTransmittedData.robotPose[2][i] then
                update=true
                break
            end
        end
        for i=1,CIC,1 do
            if simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+i-1)~=lastTransmittedData.pickTrackingWindows[i] then
                update=true
                break
            else
                if simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+i-1)~=lastTransmittedData.placeTrackingWindows[i] then
                    update=true
                    break
                else
                    if simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKFRAME1_REF+i-1)~=lastTransmittedData.pickFrames[i] then
                        update=true
                        break
                    else
                        if simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACEFRAME1_REF+i-1)~=lastTransmittedData.placeFrames[i] then
                            update=true
                            break
                        end
                    end
                end
            end
        end
        if update then
            updatePluginRepresentation()
        end
    end
end

function updatePluginRepresentation_dynParams()
    if bwfPluginLoaded then
        local c=readInfo()
        local data={}
        data.id=model
        data.speed=c.maxVel
        data.accel=c.maxAccel
        data.dynamics=c.dynamics
        data.waitingLocationAfterPick=c.waitLocAfterPickOrPlace[1]
        data.waitingLocationAfterPlace=c.waitLocAfterPickOrPlace[2]
        simBWF.query('ragnar_parameters',data)
    end
end

function sysCall_beforeDelete(data)
    for i=1,CIC,1 do
        local obj=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+i-1)
        if obj>=0 and data.objectHandles[obj] then
            updateAfterObjectDeletion=true
            break
        end
        local obj=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+i-1)
        if obj>=0 and data.objectHandles[obj] then
            updateAfterObjectDeletion=true
            break
        end
        local obj=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKFRAME1_REF+i-1)
        if obj>=0 and data.objectHandles[obj] then
            updateAfterObjectDeletion=true
            break
        end
        local obj=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACEFRAME1_REF+i-1)
        if obj>=0 and data.objectHandles[obj] then
            updateAfterObjectDeletion=true
            break
        end
    end
end

function sysCall_afterDelete(data)
    if updateAfterObjectDeletion then
        updatePluginRepresentation()
        refreshDlg()
    end
    updateAfterObjectDeletion=nil
end

function openFrame(open)
    local a=0
    if open then
        a=-math.pi
    end
    for i=1,3,1 do
        sim.setJointPosition(frameOpenClose[i],a)
    end
end

function setFrameVisible(visible)
    local p=0
    if not visible then
        p=sim.modelproperty_not_collidable+sim.modelproperty_not_detectable+sim.modelproperty_not_dynamic+
          sim.modelproperty_not_measurable+sim.modelproperty_not_renderable+sim.modelproperty_not_respondable+
          sim.modelproperty_not_visible+sim.modelproperty_not_showasinsidemodel
    end
    sim.setModelProperty(frameModel,p)
end

function setLowBeamsVisible(visible)
    for i=1,2,1 do
        if not visible then
            sim.setObjectSpecialProperty(frameBeams[i],0)
            sim.setObjectInt32Parameter(frameBeams[i],sim.objintparam_visibility_layer,0)
        else
            sim.setObjectSpecialProperty(frameBeams[i],sim.objectspecialproperty_collidable+sim.objectspecialproperty_detectable_all+sim.objectspecialproperty_measurable+sim.objectspecialproperty_renderable)
            sim.setObjectInt32Parameter(frameBeams[i],sim.objintparam_visibility_layer,1)
        end
    end
end

function isFrameOpen()
    return math.abs(sim.getJointPosition(frameOpenClose[1]))<0.1
end

function getAvailableTrackingWindows(pick)
    local theType=0
    if not pick then
        theType=1
    end
    local l=sim.getObjectsInTree(sim.handle_scene,sim.handle_all,0)
    local retL={}
    for i=1,#l,1 do
        local data=sim.readCustomDataBlock(l[i],simBWF.TRACKINGWINDOW_TAG)
        if data then
            data=sim.unpackTable(data)
            if data['type']==theType then -- 0 is for pick, 1 is for place
                retL[#retL+1]={simBWF.getObjectAltName(l[i]),l[i]}
            end
        end
    end
    return retL
end

function getAvailableFrames(pick)
    local theType=0
    if not pick then
        theType=1
    end
    local l=sim.getObjectsInTree(sim.handle_scene,sim.handle_all,0)
    local retL={}
    for i=1,#l,1 do
        local data=sim.readCustomDataBlock(l[i],simBWF.LOCATIONFRAME_TAG)
        if data then
            data=sim.unpackTable(data)
            if data['type']==theType then -- 0 is for pick, 1 is for place
                retL[#retL+1]={simBWF.getObjectAltName(l[i]),l[i]}
            end
        end
    end
    return retL
end

function getAvailableConveyors()
    local l=sim.getObjectsInTree(sim.handle_scene,sim.handle_all,0)
    local retL={}
    for i=1,#l,1 do
        local data=sim.readCustomDataBlock(l[i],simBWF.CONVEYOR_TAG)
        if data then
            retL[#retL+1]={simBWF.getObjectAltName(l[i]),l[i]}
        end
    end
    return retL
end

function getDefaultInfoForNonExistingFields(info)
    info['dwellTime']=nil
    info['algorithm']=nil
    info['pickOffset']=nil
    info['placeOffset']=nil
    info['pickRounding']=nil
    info['placeRounding']=nil
    info['pickNulling']=nil
    info['placeNulling']=nil
    info['pickApproachHeight']=nil
    info['placeApproachHeight']=nil
    info['gripperActionsWithColorChange']=nil
        
    if not info['version'] then
        info['version']=_MODELVERSION_
    end
    if not info['subtype'] then
        info['subtype']='ragnar'
    end
    if not info['primaryArmLengthInMM'] then
        info['primaryArmLengthInMM']=300
    end
    if not info['secondaryArmLengthInMM'] then
        info['secondaryArmLengthInMM']=550
    end
    if not info['frameHeightInMM'] then
        info['frameHeightInMM']=1800 -- nominal
    end
    if not info['maxVel'] then
        info['maxVel']=1
    end
    if not info['maxAccel'] then
        info['maxAccel']=1
    end
    if not info['dynamics'] then
        info['dynamics']=2000*math.pi/180
    end
    if not info['bitCoded'] then
        info['bitCoded']=0 -- 1=wsbox visible, 2=frame open, 4=wsbox visible during run,8= frame low beam visible, 16=free, 64=enabled, 128=show statistics, 256=show ws, 512=show ws also during simulation, 1024=attach part to target via a force sensor, 2048=pick part without target in sight
    end
    if not info['connectionBufferSize'] then
        info['connectionBufferSize']={1000,1000} -- simulation and real
    end
    if not info['showPlot'] then
        info['showPlot']={false,false} -- simulation and real
    end
    if not info['showTrajectory'] then
        info['showTrajectory']={false,false} -- simulation and real
    end
    if not info['visualizeUpdateFrequ'] then
        info['visualizeUpdateFrequ']={0,0} -- simulation and real parameters. 0=always, 1=medium (every 200ms), 2=rare (every 1s)
    end
    if not info['motorType'] then
        info['motorType']=MOTORTYPELIST[1] -- 0, i.e. standard
    end
    if not info['exteriorType'] then
        info['exteriorType']=EXTERIORTYPELIST[1] -- 0, i.e. standard
    end
    if not info['frameType'] then
        info['frameType']=FRAMETYPELIST[1] -- 0, i.e. experimental
    end
    if not info['clearance'] then
        info['clearance']={false,false} -- simulation and real parameters.
    end
    if not info['clearanceWithPlatform'] then
        info['clearanceWithPlatform']={false,false} -- simulation and real parameters.
    end
    if not info['clearanceForAllSteps'] then
        info['clearanceForAllSteps']={false,false} -- simulation and real parameters.
    end
    if not info['clearanceWarning'] then
        info['clearanceWarning']={0,0} -- simulation and real parameters.
    end
    --[[
    if not info['gripperActionsWithColorChange'] then
        info['gripperActionsWithColorChange']={false,false} -- simulation and real parameters.
    end
--]]
    if not info['deviceId'] then
        info['deviceId']=simBWF.NONE_TEXT
    end
    if not info['wsBox'] then
        info['wsBox']={{-0.3,-0.4,-0.8},{0.3,0.4,-0.3}}
    end
    if not info['waitLocAfterPickOrPlace'] then
        info['waitLocAfterPickOrPlace']={{0,0,-0.35},{0,0,-0.35}}
    end
    
    -- Following should disappear:
    if not info['robotAlias'] then
        info['robotAlias']=simBWF.NONE_TEXT
    end
end

function readInfo()
    local data=sim.readCustomDataBlock(model,simBWF.RAGNAR_TAG)
    if data then
        data=sim.unpackTable(data)
    else
        data={}
    end
    getDefaultInfoForNonExistingFields(data)
    return data
end

function writeInfo(data)
    if data then
        sim.writeCustomDataBlock(model,simBWF.RAGNAR_TAG,sim.packTable(data))
    else
        sim.writeCustomDataBlock(model,simBWF.RAGNAR_TAG,'')
    end
end

function isWorkspaceVisible()
    local c=readInfo()
    return sim.boolAnd32(c['bitCoded'],256)>0
end


function getGripper(thePlatform)
    local objs=sim.getObjectsInTree(thePlatform,sim.handle_all,1)
    for i=1,#objs,1 do
        if sim.readCustomDataBlock(objs[i],simBWF.RAGNARGRIPPER_TAG) then
            return objs[i]
        end
    end
    return -1
end

function updateWs()
    local gripper=getGripper(platform)
    if gripper>=0 then
        local grData=sim.unpackTable(sim.readCustomDataBlock(gripper,simBWF.RAGNARGRIPPER_TAG))
    
        local inf=readInfo()
        local primaryArmL=inf['primaryArmLengthInMM']/1000
        local secondaryArmL=inf['secondaryArmLengthInMM']/1000
        local alpha=sim.getJointPosition(alphaOffsetJ1)
        local beta=sim.getJointPosition(betaOffsetJ1)
        local ax=sim.getJointPosition(xOffsetJ1)
        local ay=sim.getJointPosition(yOffsetJ1)
        local r=grData.kinematricsParams[1] --    0.15
        local gamma1=grData.kinematricsParams[2] -- 0.5236 -- i.e. 30 deg
        local gamma2=grData.kinematricsParams[3] -- 2.0944 -- i.e. 120 deg

        local data={}
        data.details=1
        
        -- See the ragnar.pdf document in the repository for the meaning of following arm parameters.
        -- For now, the plugin expects arm in following order: 3,4,1,2
        -- Also, the plugin uses the negative of beta.
        local arm1Param={-ax, -ay, -alpha, -beta, primaryArmL, secondaryArmL, r, -gamma2}
        local arm2Param={ax, -ay, alpha, beta, primaryArmL, secondaryArmL, r, -gamma1}
        local arm3Param={ax, ay, -alpha, beta, primaryArmL, secondaryArmL, r, gamma1}
        local arm4Param={-ax, ay, alpha, -beta, primaryArmL, secondaryArmL, r, gamma2}
        local makeCorrections=true
        if makeCorrections then
            data.armParams={arm3Param,arm4Param,arm1Param,arm2Param}
            for i=1,4,1 do
                data.armParams[i][4]=data.armParams[i][4]*-1
            end
        else
            data.armParams={arm1Param,arm2Param,arm3Param,arm4Param}
        end
        
        local res,retDat=simBWF.query("ragnar_ws",data)
        sim.removePointsFromPointCloud(ragnarWs,0,nil,0)
        sim.insertPointsIntoPointCloud(ragnarWs,1,retDat.points)
    end
end

function adjustRobot()
---[[
    local inf=readInfo()
    local primaryArmLengthInMM=inf['primaryArmLengthInMM']
    local secondaryArmLengthInMM=inf['secondaryArmLengthInMM']

--    local a=0.2+((primaryArmLengthInMM-200)/50)*0.05+0.0005
    local a=primaryArmLengthInMM/1000
    local b=secondaryArmLengthInMM/1000
 

    local c=0.025
    local x=math.sqrt(a*a-c*c)
    local primaryAdjust=x-math.sqrt(0.3*0.3-c*c) -- Initial lengths are 300 and 550
    local secondaryAdjust=b-0.55
    local dx=a*28/30
    local ddx=dx-0.28

    for i=1,4,1 do
        sim.setJointPosition(primaryArmsEndAdjust[i],primaryAdjust)
    end

    for i=1,8,1 do
        sim.setJointPosition(secondaryArmsEndAdjust[i],secondaryAdjust)
    end


    for i=1,4,1 do
        sim.setJointPosition(primaryArmsLAdjust[i],primaryAdjust*0.5)
    end

    for i=1,8,1 do
        sim.setJointPosition(secondaryArmsLAdjust[i],secondaryAdjust*0.5)
    end

    for i=1,2,1 do
        sim.setJointPosition(leftAndRightSideAdjust[i],dx)
    end

    -- Scale the central elements in the X-direction:
    for i=1,3,1 do
        local h=centralCover[i]
        local r,minX=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_min_x)
        local r,maxX=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_max_x)
        local s=maxX-minX
        local desiredXSize=((a*28/30)-0.233+0.025)*2
        if desiredXSize<0.049 then
            desiredXSize=0.05
        end
        sim.scaleObject(h,desiredXSize/s,1,1)
    end

    
    -- Scale the "Ragnar Robot" meshes:
    for i=1,2,1 do
        local h=nameElement[i]
        local r,minZ=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_min_z)
        local r,maxZ=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_max_z)
        local s=maxZ-minZ
        local d=0.3391
        if a<0.18 then
            d=0.1187
        elseif a<0.23 then
            d=0.2204
        end
        --[[
        local p=sim.getObjectPosition(h,-1)
        if d/s>1.1 then
            p[1]=p[1]+
        end
        if d/s<0.9 then
        
        end
        --]]
        sim.scaleObject(h,d/s,d/s,d/s)
    end

    

    for i=1,4,1 do
        local h=primaryArms[i]
        local r,minZ=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_min_z)
        local r,maxZ=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_max_z)
        local s=maxZ-minZ
        local d=0.242+primaryAdjust
        sim.scaleObject(h,1,1,d/s)
    end

    for i=1,8,1 do
        local h=secondaryArms[i]
        local r,minZ=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_min_z)
        local r,maxZ=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_max_z)
        local s=maxZ-minZ
        local r,minX=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_min_x)
        local r,maxX=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_max_x)
        local sx=maxX-minX
        local d=0.5+secondaryAdjust
        local diam=0.01
        if d>=0.5 then
            diam=0.014
        end
        sim.scaleObject(h,diam/sx,diam/sx,d/s)
    end

    executeIk(true)

    -- The frame (width and height):
    local nomS={0.9674,0.9674,0.9674,0.411,0.98509,0.98509,0.7094,0.7094}
    for i=1,4,1 do
        local h=frameBeams[i]
        local r,minY=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_min_y)
        local r,maxY=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_max_y)
        local s=maxY-minY
        local d=nomS[i]+ddx*2
        sim.scaleObject(h,1,d/s,1)
    end
    sim.setJointPosition(frameJoints[1],ddx)
    sim.setJointPosition(frameJoints[2],ddx)

    local inf=readInfo()
    local z=(inf['frameHeightInMM']/1000)-0.2 -- so that we have z=1.6 at nominal height
    local dz=z-1.36
    for i=5,8,1 do
        local h=frameBeams[i]
        local r,minZ=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_min_z)
        local r,maxZ=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_max_z)
        local s=maxZ-minZ
        local d=nomS[i]+dz
        sim.scaleObject(h,1,1,d/s)
    end

    sim.setJointPosition(frameJoints[3],-dz)
    sim.setJointPosition(frameJoints[4],-dz)
    sim.setJointPosition(frameJoints[5],-dz)
    sim.setJointPosition(frameJoints[6],-dz)

    for i=7,10,1 do
        sim.setJointPosition(frameJoints[i],-dz*0.5)
    end

    local p=sim.getObjectPosition(ragnarRef,sim.handle_parent)
    sim.setObjectPosition(ragnarRef,sim.handle_parent,{p[1],p[2],z-0.09})
    local p=sim.getObjectPosition(frameModel,sim.handle_parent)
    sim.setObjectPosition(frameModel,sim.handle_parent,{p[1],p[2],z})
    
    workspaceUpdateRequest=sim.getSystemTimeInMs(-1)
--]]
end

function getJointPositions(handles)
    local retTable={}
    for i=1,#handles,1 do
        retTable[i]=sim.getJointPosition(handles[i])
    end
    return retTable
end

function setJointPositions(handles,positions)
    for i=1,#handles,1 do
        sim.setJointPosition(handles[i],positions[i])
    end
end


function setArmLength(primaryArmLengthInMM,secondaryArmLengthInMM)
    local allowedB={} -- in multiples of 50
    allowedB[200]={400,450}
    allowedB[250]={450,600}
    allowedB[300]={550,700}
    allowedB[350]={650,800}
    allowedB[400]={750,900}
    allowedB[450]={850,1000}
    allowedB[500]={900,1150}
    allowedB[550]={1000,1250}
    
    local allowedA={} -- in multiples of 50
    allowedA[400]={200,200}
    allowedA[450]={200,250}
    allowedA[500]={250,250}
    allowedA[550]={250,300}
    allowedA[600]={250,300}
    allowedA[650]={300,350}
    allowedA[700]={300,350}
    allowedA[750]={350,400}
    allowedA[800]={350,400}
    allowedA[850]={400,450}
    allowedA[900]={400,500}
    allowedA[950]={450,500}
    allowedA[1000]={450,550}
    allowedA[1050]={500,550}
    allowedA[1100]={500,550}
    allowedA[1150]={500,550}
    allowedA[1200]={550,550}
    allowedA[1250]={550,550}
    
    local c=readInfo()
    if primaryArmLengthInMM then
        -- We changed the primary arm length
        c['primaryArmLengthInMM']=primaryArmLengthInMM
        local allowed=allowedB[primaryArmLengthInMM]
        secondaryArmLengthInMM=c['secondaryArmLengthInMM']
        if secondaryArmLengthInMM<allowed[1] then
            secondaryArmLengthInMM=allowed[1]
        end
        if secondaryArmLengthInMM>allowed[2] then
            secondaryArmLengthInMM=allowed[2]
        end
        c['secondaryArmLengthInMM']=secondaryArmLengthInMM
    else
        -- We changed the secondary arm length
        c['secondaryArmLengthInMM']=secondaryArmLengthInMM
        local allowed=allowedA[secondaryArmLengthInMM]
        primaryArmLengthInMM=c['primaryArmLengthInMM']
        if primaryArmLengthInMM<allowed[1] then
            primaryArmLengthInMM=allowed[1]
        end
        if primaryArmLengthInMM>allowed[2] then
            primaryArmLengthInMM=allowed[2]
        end
        c['primaryArmLengthInMM']=primaryArmLengthInMM
    end
    writeInfo(c)
    simBWF.markUndoPoint()
    adjustRobot()
 --   showHideWorkspace(isWorkspaceVisible())
    refreshDlg()
end

function sizeAChange_callback(ui,id,newVal)
    setArmLength(200+newVal*50,nil)
    refreshDlg()
end

function sizeBChange_callback(ui,id,newVal)
    setArmLength(nil,400+newVal*50)
    refreshDlg()
end

function setObjectSize(h,x,y,z)
    local r,mmin=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_min_x)
    local r,mmax=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_max_x)
    local sx=mmax-mmin
    local r,mmin=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_min_y)
    local r,mmax=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_max_y)
    local sy=mmax-mmin
    local r,mmin=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_min_z)
    local r,mmax=sim.getObjectFloatParameter(h,sim.objfloatparam_objbbox_max_z)
    local sz=mmax-mmin
    sim.scaleObject(h,x/sx,y/sy,z/sz)
end

function adjustWsBox()
    local c=readInfo()
    local s={c.wsBox[2][1]-c.wsBox[1][1],c.wsBox[2][2]-c.wsBox[1][2],c.wsBox[2][3]-c.wsBox[1][3]}
    local p={(c.wsBox[2][1]+c.wsBox[1][1])/2,(c.wsBox[2][2]+c.wsBox[1][2])/2,(c.wsBox[2][3]+c.wsBox[1][3])/2}
    setObjectSize(ragnarWsBox,s[1],s[2],s[3])
    sim.setObjectPosition(ragnarWsBox,ragnarRef,p)
end

function frameHeightChange_callback(ui,id,newVal)
    local c=readInfo()
    c['frameHeightInMM']=newVal*50
    writeInfo(c)
    simBWF.markUndoPoint()
    adjustRobot()
    refreshDlg()
end

function velocityChange_callback(uiHandle,id,newValue)
    local c=readInfo()
    newValue=tonumber(newValue)
    if newValue then
        if newValue<1 then newValue=1 end
--        if newValue>5000 then newValue=5000 end
        newValue=newValue/1000
        if newValue~=c['maxVel'] then
            c['maxVel']=newValue
            writeInfo(c)
            simBWF.markUndoPoint()
            adjustMaxVelocityMaxAcceleration()
            updatePluginRepresentation_dynParams()
        end
    end
    refreshDlg()
end

function accelerationChange_callback(uiHandle,id,newValue)
    local c=readInfo()
    newValue=tonumber(newValue)
    if newValue then
        if newValue<1 then newValue=1 end
--        if newValue>35000 then newValue=35000 end
        newValue=newValue/1000
        if newValue~=c['maxAccel'] then
            c['maxAccel']=newValue
            writeInfo(c)
            simBWF.markUndoPoint()
            adjustMaxVelocityMaxAcceleration()
            updatePluginRepresentation_dynParams()
        end
    end
    refreshDlg()
end

function dynamicsChange_callback(uiHandle,id,newValue)
    local c=readInfo()
    newValue=tonumber(newValue)
    if newValue then
        if newValue<100 then newValue=100 end
        if newValue>20000 then newValue=20000 end
        newValue=newValue*math.pi/180
        if newValue~=c['dynamics'] then
            c['dynamics']=newValue
            writeInfo(c)
            simBWF.markUndoPoint()
            updatePluginRepresentation_dynParams()
        end
    end
    refreshDlg()
end

function visualizeWorkspaceClick_callback(uiHandle,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],256)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-256
    end
    writeInfo(c)
    
    if newVal>0 then
        sim.setObjectInt32Parameter(ragnarWs,sim.objintparam_visibility_layer,1)
        workspaceUpdateRequest=sim.getSystemTimeInMs(-1) -- to trigger recomputation
    else
        sim.setObjectInt32Parameter(ragnarWs,sim.objintparam_visibility_layer,0)
    end
    simBWF.markUndoPoint()
    refreshDlg()
end

function visualizeWorkspaceSimClick_callback(uiHandle,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],512)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-512
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function visualizeWsBoxClick_callback(uiHandle,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],1)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-1
    end
    writeInfo(c)
    
    if newVal>0 then
        sim.setObjectInt32Parameter(ragnarWsBox,sim.objintparam_visibility_layer,1)
    else
        sim.setObjectInt32Parameter(ragnarWsBox,sim.objintparam_visibility_layer,0)
    end
    simBWF.markUndoPoint()
    refreshDlg()
end

function visualizeWsBoxSimClick_callback(uiHandle,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],4)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-4
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function openFrameClick_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],2)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-2
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    openFrame(newVal~=0)
    refreshDlg()
end

function visibleFrameLowBeamsClick_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],8)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-8
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    setLowBeamsVisible(newVal~=0)
    refreshDlg()
end

function enabledClicked_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],64)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-64
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function showStatisticsClick_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],128)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-128
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    if sim.getSimulationState()~=sim.simulation_stopped then
        simBWF.callChildScriptFunction("ext_enableDisableStats_fromCustomizationScript",model,newVal~=0)
    end
    refreshDlg()
end

function attachPartClicked_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],1024)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-1024
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function pickWithoutTargetClicked_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],2048)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-2048
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function aliasComboChange_callback(uiHandle,id,newValue)
    local newAlias=comboAlias[newValue+1][1]
    local c=readInfo()
    c['robotAlias']=newAlias
    writeInfo(c)
    simBWF.markUndoPoint()
--    updateAliasCombobox()
    updatePluginRepresentation()
    refreshDlg()
end

function deviceIdComboChange_callback(uiHandle,id,newValue)
    local newDeviceId=comboDeviceIds[newValue+1][1]
    local c=readInfo()
    c.deviceId=newDeviceId
    writeInfo(c)
    simBWF.markUndoPoint()
--    updateDeviceIdCombobox()
    updatePluginRepresentation()
    refreshDlg()
end

function adjustMaxVelocityMaxAcceleration()
    local c=readInfo()
    local mv=MOTORTYPES[c.motorType].maxVel
    local ma=MOTORTYPES[c.motorType].maxAccel
    if c['maxVel']>mv then
        c['maxVel']=mv
        simBWF.markUndoPoint()
    end
    if c['maxAccel']>ma then
        c['maxAccel']=ma
        simBWF.markUndoPoint()
    end
    writeInfo(c)
end

function motorTypeChange_callback(uiHandle,id,newIndex)
    local newType=motorType_comboboxItems[newIndex+1][2]
    local c=readInfo()
    c['motorType']=newType
    writeInfo(c)
    simBWF.markUndoPoint()
    updateMotorTypeCombobox()
    adjustMaxVelocityMaxAcceleration()
    refreshDlg()
    updatePluginRepresentation()
    updatePluginRepresentation_dynParams()
end

function updateMotorTypeCombobox()
    local c=readInfo()
    local loc={}
    for i=1,#MOTORTYPELIST,1 do
        loc[i]={MOTORTYPES[MOTORTYPELIST[i]].text,MOTORTYPELIST[i]}
    end
    motorType_comboboxItems=sim.UI_populateCombobox(ui,95,loc,{},loc[c.motorType+1][1],false,{})
end

function exteriorTypeChange_callback(uiHandle,id,newIndex)
    local newType=exteriorType_comboboxItems[newIndex+1][2]
    local c=readInfo()
    c['exteriorType']=newType
    writeInfo(c)
    
--    local col1={0.75,0.75,1}
    local col2={0.25,0.35,0.8}
--    local col3={0.35,0.55,1}
    if newType==0 then
--        col1={1,1,1}
        col2={0.32,0.32,0.32}
--        col3={0.43,0.43,0.43}
    end
    local s=sim.getObjectsInTree(model,sim.object_shape_type)
    for i=1,#s,1 do
--        sim.setShapeColor(s[i],'RAGNAR_GEAR',sim.colorcomponent_ambient_diffuse,col1)
        sim.setShapeColor(s[i],'COVER_BLACK',sim.colorcomponent_ambient_diffuse,col2)
--        sim.setShapeColor(s[i],'RAGNAR_COVER_DARKGREY',sim.colorcomponent_ambient_diffuse,col3)
    end
    
    simBWF.markUndoPoint()
    updateExteriorTypeCombobox()
    updatePluginRepresentation()
end

function updateExteriorTypeCombobox()
    local c=readInfo()
    local loc={}
    for i=1,#EXTERIORTYPELIST,1 do
        loc[i]={EXTERIORTYPES[EXTERIORTYPELIST[i]].text,EXTERIORTYPELIST[i]}
    end
    exteriorType_comboboxItems=sim.UI_populateCombobox(ui,96,loc,{},loc[c.exteriorType+1][1],false,{})
end

function frameTypeChange_callback(uiHandle,id,newIndex)
    local newType=frameType_comboboxItems[newIndex+1][2]
    local c=readInfo()
    c['frameType']=newType
    writeInfo(c)
    
    setFrameVisible(newType~=0)
    
    simBWF.markUndoPoint()
    updateFrameTypeCombobox()
    refreshDlg()
    updatePluginRepresentation()
end

function updateFrameTypeCombobox()
    local c=readInfo()
    local loc={}
    for i=1,#FRAMETYPELIST,1 do
        loc[i]={FRAMETYPES[FRAMETYPELIST[i]].text,FRAMETYPELIST[i]}
    end
    frameType_comboboxItems=sim.UI_populateCombobox(ui,97,loc,{},loc[c.frameType+1][1],false,{})
end


function simBufferSize_callback(uiHandle,id,newValue)
    local c=readInfo()
    newValue=tonumber(newValue)
    if newValue then
        if newValue<1 then newValue=1 end
        if newValue>10000 then newValue=10000 end
        if c['connectionBufferSize'][1]~=newValue then
            c['connectionBufferSize'][1]=newValue
            simBWF.markUndoPoint()
            writeInfo(c)
        end
    end
    refreshDlg()
end

function simShowRobotPlotClick_callback(ui,id,newVal)
    local c=readInfo()
    c.showPlot[1]=not c.showPlot[1]
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function simShowTrajectoryClick_callback(ui,id,newVal)
    local c=readInfo()
    c.showTrajectory[1]=not c.showTrajectory[1]
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

--[[
function gripperActionColorChangeClick_callback(ui,id,newVal)
    local c=readInfo()
    local index=1
    if id==1211 then
        index=2
    end
    c.gripperActionsWithColorChange[index]=not c.gripperActionsWithColorChange[index]
    writeInfo(c)
    simBWF.markUndoPoint()
    refreshDlg()
end
--]]

function showClearanceClick_callback(ui,id,newVal)
    local c=readInfo()
    local ind=1
    if id~=1307 then
        ind=2
    end
    c.clearance[ind]=not c.clearance[ind]
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function clearanceWithPlatformClick_callback(ui,id,newVal)
    local c=readInfo()
    local ind=1
    if id~=1308 then
        ind=2
    end
    c.clearanceWithPlatform[ind]=not c.clearanceWithPlatform[ind]
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function clearanceForEveryStepClick_callback(ui,id,newVal)
    local c=readInfo()
    local ind=1
    if id~=1309 then
        ind=2
    end
    c.clearanceForAllSteps[ind]=not c.clearanceForAllSteps[ind]
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function clearanceWarning_callback(uiHandle,id,newValue)
    local c=readInfo()
    newValue=tonumber(newValue)
    if newValue then
        newValue=newValue/1000
        if newValue<0.001 then newValue=0 end
        if newValue>1 then newValue=1 end
        if c['clearanceWarning'][1]~=newValue then
            c['clearanceWarning'][1]=newValue
            simBWF.markUndoPoint()
            writeInfo(c)
        end
    end
    refreshDlg()
end

function simVisualizeUpdateFrequChange_callback(ui,id,newIndex)
    local c=readInfo()
    c['visualizeUpdateFrequ'][1]=newIndex
    writeInfo(c)
    simBWF.markUndoPoint()
end


function realBufferSize_callback(uiHandle,id,newValue)
    local c=readInfo()
    newValue=tonumber(newValue)
    if newValue then
        if newValue<1 then newValue=1 end
        if newValue>10000 then newValue=10000 end
        if c['connectionBufferSize'][2]~=newValue then
            c['connectionBufferSize'][2]=newValue
            simBWF.markUndoPoint()
            writeInfo(c)
        end
    end
    refreshDlg()
end

function realShowRobotPlotClick_callback(ui,id,newVal)
    local c=readInfo()
    c.showPlot[2]=not c.showPlot[2]
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function realShowTrajectoryClick_callback(ui,id,newVal)
    local c=readInfo()
    c.showTrajectory[2]=not c.showTrajectory[2]
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function realVisualizeUpdateFrequChange_callback(ui,id,newIndex)
    local c=readInfo()
    c['visualizeUpdateFrequ'][2]=newIndex
    writeInfo(c)
    simBWF.markUndoPoint()
end

function getPlatformPose()
    return {sim.getObjectPosition(platform,sim.handle_parent),sim.getObjectOrientation(platform,sim.handle_parent)}
end

function setPlatformPose(pose)
    if platform>=0 then
        sim.setObjectPosition(platform,sim.handle_parent,pose[1])
        sim.setObjectOrientation(platform,sim.handle_parent,pose[2])
        executeIk()
    end
end

function attachOrDetachReferencedItem(previousItem,newItem)
    -- We keep the tracking windows and location frames as orphans, otherwise we might run into trouble with the calibration balls, etc.
    --[[
    if previousItem>=0 then
        sim.setObjectParent(previousItem,-1,true) -- detach previous item
    end
    if newItem>=0 then
        sim.setObjectParent(newItem,model,true) -- attach current item
    end
    --]]
end

function pickTrackingWindowChange_callback(ui,id,newIndex)
    local newLoc=pickTrackingWindows_comboboxItems[id-610][newIndex+1][2]
    -- Make sure no other has the same item:
    for i=1,CIC,1 do
        if i~=id-610 then
            if newLoc~=-1 and simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+i-1)==newLoc then
                attachOrDetachReferencedItem(simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+i-1),-1)
                simBWF.setReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+i-1,-1)
            end
        end
    end
    -- Clear calibration data of previous item:
    local itm=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+id-610-1)
    if itm>=0 then
        simBWF.callCustomizationScriptFunction("ext_clearCalibration",itm)
    end
    -- Clear calibration data of current item:
    if newLoc>=0 then
        simBWF.callCustomizationScriptFunction("ext_clearCalibration",newLoc)
    end
    -- Set the item:
    attachOrDetachReferencedItem(simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+id-610-1),newLoc)
    simBWF.setReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+id-610-1,newLoc)
    -- Make sure other Ragnar robots do not reference this item:
    if newLoc>=0 then
        local allRagnars=sim.getObjectsWithTag(simBWF.RAGNAR_TAG,true)
        for i=1,#allRagnars,1 do
            local m=allRagnars[i]
            if m~=model then
                for j=1,CIC,1 do
                    local item=simBWF.getReferencedObjectHandle(m,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+j-1)
                    if item==newLoc then
                        simBWF.setReferencedObjectHandle(m,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+j-1,-1) -- the item was same. We set it to -1
                    end
                end
            end
        end
    end

    simBWF.markUndoPoint()
    updatePluginRepresentation()
    updatePickTrackingWindowComboboxes()
end

function placeTrackingWindowChange_callback(ui,id,newIndex)
    local newLoc=placeTrackingWindows_comboboxItems[id-620][newIndex+1][2]
    -- Make sure no other has the same item:
    for i=1,CIC,1 do
        if i~=id-620 then
            if newLoc~=-1 and simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+i-1)==newLoc then
                attachOrDetachReferencedItem(simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+i-1),-1)
                simBWF.setReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+i-1,-1)
            end
        end
    end
    -- Clear calibration data of previous item:
    local itm=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+id-620-1)
    if itm>=0 then
        simBWF.callCustomizationScriptFunction("ext_clearCalibration",itm)
    end
    -- Clear calibration data of current item:
    if newLoc>=0 then
        simBWF.callCustomizationScriptFunction("ext_clearCalibration",newLoc)
    end
    -- Set the item:
    attachOrDetachReferencedItem(simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+id-620-1),newLoc)
    simBWF.setReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+id-620-1,newLoc)
    -- Make sure other Ragnar robots do not reference this item:
    if newLoc>=0 then
        local allRagnars=sim.getObjectsWithTag(simBWF.RAGNAR_TAG,true)
        for i=1,#allRagnars,1 do
            local m=allRagnars[i]
            if m~=model then
                for j=1,CIC,1 do
                    local item=simBWF.getReferencedObjectHandle(m,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+j-1)
                    if item==newLoc then
                        simBWF.setReferencedObjectHandle(m,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+j-1,-1) -- the item was same. We set it to -1
                    end
                end
            end
        end
    end

    simBWF.markUndoPoint()
    updatePluginRepresentation()
    updatePlaceTrackingWindowComboboxes()
end


function pickFrameChange_callback(ui,id,newIndex)
    local newLoc=pickFrames_comboboxItems[id-600][newIndex+1][2]
    -- Make sure no other has the same item:
    for i=1,CIC,1 do
        if i~=id-600 then
            if newLoc~=-1 and simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKFRAME1_REF+i-1)==newLoc then
                attachOrDetachReferencedItem(simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKFRAME1_REF+i-1),-1)
                simBWF.setReferencedObjectHandle(model,simBWF.RAGNAR_PICKFRAME1_REF+i-1,-1)
            end
        end
    end
    -- Clear calibration data of previous item:
    local itm=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKFRAME1_REF+id-600-1)
    if itm>=0 then
        simBWF.callCustomizationScriptFunction("ext_clearCalibration",itm)
    end
    -- Clear calibration data of current item:
    if newLoc>=0 then
        simBWF.callCustomizationScriptFunction("ext_clearCalibration",newLoc)
    end
    -- Set the item:
    attachOrDetachReferencedItem(simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKFRAME1_REF+id-600-1),newLoc)
    simBWF.setReferencedObjectHandle(model,simBWF.RAGNAR_PICKFRAME1_REF+id-600-1,newLoc)
    -- Make sure other Ragnar robots do not reference this item:
    if newLoc>=0 then
        local allRagnars=sim.getObjectsWithTag(simBWF.RAGNAR_TAG,true)
        for i=1,#allRagnars,1 do
            local m=allRagnars[i]
            if m~=model then
                for j=1,CIC,1 do
                    local item=simBWF.getReferencedObjectHandle(m,simBWF.RAGNAR_PICKFRAME1_REF+j-1)
                    if item==newLoc then
                        simBWF.setReferencedObjectHandle(m,simBWF.RAGNAR_PICKFRAME1_REF+j-1,-1) -- the item was same. We set it to -1
                    end
                end
            end
        end
    end

    simBWF.markUndoPoint()
    updatePluginRepresentation()
    updatePickFrameComboboxes()
end

function placeFrameChange_callback(ui,id,newIndex)
    local newLoc=placeFrames_comboboxItems[id-500][newIndex+1][2]
    -- Make sure no other has the same item:
    for i=1,CIC,1 do
        if i~=id-500 then
            if newLoc~=-1 and simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACEFRAME1_REF+i-1)==newLoc then
                attachOrDetachReferencedItem(simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACEFRAME1_REF+i-1),-1)
                simBWF.setReferencedObjectHandle(model,simBWF.RAGNAR_PLACEFRAME1_REF+i-1,-1)
            end
        end
    end
    -- Clear calibration data of previous item:
    local itm=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACEFRAME1_REF+id-500-1)
    if itm>=0 then
        simBWF.callCustomizationScriptFunction("ext_clearCalibration",itm)
    end
    -- Clear calibration data of current item:
    if newLoc>=0 then
        simBWF.callCustomizationScriptFunction("ext_clearCalibration",newLoc)
    end
    -- Set the item:
    attachOrDetachReferencedItem(simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACEFRAME1_REF+id-500-1),newLoc)
    simBWF.setReferencedObjectHandle(model,simBWF.RAGNAR_PLACEFRAME1_REF+id-500-1,newLoc)
    -- Make sure other Ragnar robots do not reference this item:
    if newLoc>=0 then
        local allRagnars=sim.getObjectsWithTag(simBWF.RAGNAR_TAG,true)
        for i=1,#allRagnars,1 do
            local m=allRagnars[i]
            if m~=model then
                for j=1,CIC,1 do
                    local item=simBWF.getReferencedObjectHandle(m,simBWF.RAGNAR_PLACEFRAME1_REF+j-1)
                    if item==newLoc then
                        simBWF.setReferencedObjectHandle(m,simBWF.RAGNAR_PLACEFRAME1_REF+j-1,-1) -- the item was same. We set it to -1
                    end
                end
            end
        end
    end

    simBWF.markUndoPoint()
    updatePluginRepresentation()
    updatePlaceFrameComboboxes()
end

function updatePickTrackingWindowComboboxes()
    pickTrackingWindows_comboboxItems={}
    local loc=getAvailableTrackingWindows(true)
    for i=1,ECIC_PiW,1 do
        pickTrackingWindows_comboboxItems[i]=sim.UI_populateCombobox(ui,611+i-1,loc,{},simBWF.getObjectAltNameOrNone(simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+i-1)),true,{{simBWF.NONE_TEXT,-1}})
    end
end

function updatePlaceTrackingWindowComboboxes()
    placeTrackingWindows_comboboxItems={}
    local loc=getAvailableTrackingWindows(false)
    for i=1,ECIC_PlW,1 do
        placeTrackingWindows_comboboxItems[i]=sim.UI_populateCombobox(ui,621+i-1,loc,{},simBWF.getObjectAltNameOrNone(simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+i-1)),true,{{simBWF.NONE_TEXT,-1}})
    end
end

function updatePickFrameComboboxes()
    pickFrames_comboboxItems={}
    local loc=getAvailableFrames(true)
    for i=1,ECIC_PiL,1 do
        pickFrames_comboboxItems[i]=sim.UI_populateCombobox(ui,601+i-1,loc,{},simBWF.getObjectAltNameOrNone(simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKFRAME1_REF+i-1)),true,{{simBWF.NONE_TEXT,-1}})
    end
end

function updatePlaceFrameComboboxes()
    placeFrames_comboboxItems={}
    local loc=getAvailableFrames(false)
    for i=1,ECIC_PlL,1 do
        placeFrames_comboboxItems[i]=sim.UI_populateCombobox(ui,501+i-1,loc,{},simBWF.getObjectAltNameOrNone(simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACEFRAME1_REF+i-1)),true,{{simBWF.NONE_TEXT,-1}})
    end
end

function conveyorChange_callback(ui,id,newIndex)
    local newLoc=conveyor_comboboxItems[id-1200][newIndex+1][2]
    -- Make sure no other has the same item:
    for i=1,2,1 do
        if i~=id-1200 then
            if simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_CONVEYOR1_REF+i-1)==newLoc then
                simBWF.setReferencedObjectHandle(model,simBWF.RAGNAR_CONVEYOR1_REF+i-1,-1)
            end
        end
    end
    -- Set the item:
    simBWF.setReferencedObjectHandle(model,simBWF.RAGNAR_CONVEYOR1_REF+id-1200-1,newLoc)
    --[[
    -- Make sure other Ragnar robots do not reference this item:
    if newLoc>=0 then
        local allRagnars=sim.getObjectsWithTag(simBWF.RAGNAR_TAG,true)
        for i=1,#allRagnars,1 do
            local m=allRagnars[i]
            if m~=model then
                for j=1,2,1 do
                    local item=simBWF.getReferencedObjectHandle(m,simBWF.RAGNAR_CONVEYOR1_REF+j-1)
                    if item==newLoc then
                        simBWF.setReferencedObjectHandle(m,simBWF.RAGNAR_CONVEYOR1_REF+j-1,-1) -- the item was same. We set it to -1
                    end
                end
            end
        end
    end
--]]
    simBWF.markUndoPoint()
    updatePluginRepresentation()
    updateConveyorComboboxes()
end

function updateConveyorComboboxes()
    conveyor_comboboxItems={}
    local loc=getAvailableConveyors()
    for i=1,2,1 do
        conveyor_comboboxItems[i]=sim.UI_populateCombobox(ui,1201+i-1,loc,{},simBWF.getObjectAltNameOrNone(simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_CONVEYOR1_REF+i-1)),true,{{simBWF.NONE_TEXT,-1}})
    end
end


function updateAliasCombobox()
    local c=readInfo()
    local resp,data
    if simBWF.isInTestMode() then
        resp='ok'
        data={}
        data.aliases={'testID-1','testID-2'}
    else
        resp,data=simBWF.query('get_ragnarAliases')
        if resp~='ok' then
            data.aliases={}
        end
    end
    
    local selected=c['robotAlias']
    local isKnown=false
    local items={}
    for i=1,#data.aliases,1 do
        if data.aliases[i]==selected then
            isKnown=true
        end
        items[#items+1]={data.aliases[i],i}
    end
    if not isKnown then
        table.insert(items,1,{selected,#items+1})
    end
    if selected~=simBWF.NONE_TEXT then
        table.insert(items,1,{simBWF.NONE_TEXT,#items+1})
    end
    comboAlias=sim.UI_populateCombobox(ui,1200,items,{},selected,false,{})
--    updatePluginRepresentation()
end

function updateDeviceIdCombobox()
    local c=readInfo()
    local resp,data
    if simBWF.isInTestMode() then
        resp='ok'
        data={}
        data.deviceIds={'RAGNAR-95426587447','RAGNAR-35426884525','CONVEYOR-35426884525-0','CONVEYOR-00:1b:63:84:45:e6-1','SENSOR-00:fa:08:46:8b:11-1','VISION-00:3b:99:34:7d:1f-0'}
    else
        resp,data=simBWF.query('get_deviceIds')
        if resp~='ok' then
            data.deviceIds={}
        end
    end
    
    local ids={}
    for i=1,#data.deviceIds,1 do
        if string.find(data.deviceIds[i],"RAGNAR-")==1 then
            ids[#ids+1]=data.deviceIds[i]
        end
    end
    
    local selected=c.deviceId
    local isKnown=false
    local items={}
    for i=1,#ids,1 do
        if ids[i]==selected then
            isKnown=true
        end
        items[#items+1]={ids[i],i}
    end
    if not isKnown then
        table.insert(items,1,{selected,#items+1})
    end
    if selected~=simBWF.NONE_TEXT then
        table.insert(items,1,{simBWF.NONE_TEXT,#items+1})
    end
    comboDeviceIds=sim.UI_populateCombobox(ui,4899,items,{},selected,false,{})
end

function identificationAndRenaming_identification_callback(ui,id,newVal)
    local c=readInfo()
    local data={}
    data.alias=c.robotAlias
    simBWF.query('identify_ragnarFromAlias',data)
    data={}
    data.deviceId=c.deviceId
    simBWF.query('identify_device',data)
end

function aliasNameEdit_callback(ui,id,newVal)
    if #newVal>2 then
        local newAlias=''
        for i=1,#newVal,1 do
            local v=newVal:sub(i,i)
            if (v>='0' and v<='9') or (v>='a' and v<='z') or (v>='A' and v<='Z') or v=='_' or v=='-' then
                newAlias=newAlias..v
            else
                newAlias=newAlias..'_'
            end
        end
        -- Check if we already have such a name:
        local valid=true
        for i=1,#comboAlias,1 do
            if comboAlias[i][1]==newAlias then
                valid=false
                break
            end
        end
        if valid then
            aliasRenaming_lastValidName=newAlias
        end
    end
    simUI.setEditValue(ui,1,aliasRenaming_lastValidName,true)
end

function aliasRenaming_cancel_callback(ui,id,newVal)
    simUI.destroy(aliasRenaming_ui)
    aliasRenaming_ui=nil
    aliasRenaming_lastValidName=nil
end

function aliasRenaming_ok_renaming_callback(ui,id,newVal)
    local c=readInfo()
    if aliasRenaming_lastValidName~=c.robotAlias then
        -- ol, the name has changed and is valid
        local data={}
        data.oldAlias=c.robotAlias
        data.newAlias=aliasRenaming_lastValidName
        simBWF.query('rename_ragnarAlias',data)
        c.robotAlias=aliasRenaming_lastValidName
        writeInfo(c)
        updateAliasCombobox() -- to reflect the change
        updatePluginRepresentation()
    end
    simUI.destroy(aliasRenaming_ui)
    aliasRenaming_ui=nil
    aliasRenaming_lastValidName=nil
end

function identificationAndRenaming_renaming_callback(ui,id,newVal)
    local c=readInfo()
    local xml =[[
    <label text="New Ragnar alias"  style="* {min-width: 120px;}"/>
    <edit on-editing-finished="aliasNameEdit_callback" style="* {min-width: 120px;}" id="1"/>
    
    <button text="Cancel"  on-click="aliasRenaming_cancel_callback"/>
    <button text="Ok"  on-click="aliasRenaming_ok_renaming_callback"/>
    ]]
    aliasRenaming_ui=simBWF.createCustomUi(xml,"Renaming Ragnar '"..c.robotAlias.."'","center",false,"",true,false,true,'layout="form"')
    aliasRenaming_lastValidName=c.robotAlias
    simUI.setEditValue(aliasRenaming_ui,1,aliasRenaming_lastValidName,true)
end

function identificationAndRenamingClose_callback()
    simUI.destroy(identificationAndRenaming_ui)
    identificationAndRenaming_ui=nil
end

function identificationAndRenaming_callback(ui,id,newVal)
    local c=readInfo()
    if c.robotAlias~=simBWF.NONE_TEXT then

        local xml =[[
        <button text="Identify"  on-click="identificationAndRenaming_identification_callback" style="* {min-width: 200px;}"/>
        <button text="Rename"  on-click="identificationAndRenaming_renaming_callback" style="* {min-width: 200px;}"/>
        ]]
        
        identificationAndRenaming_ui=simBWF.createCustomUi(xml,"Ragnar '"..c.robotAlias.."'","center",true,"identificationAndRenamingClose_callback",true,false,true)
    end
end


function updateEnabledDisabledItems()
    if ui then
        local c=readInfo()
        local simStopped=sim.getSimulationState()==sim.simulation_stopped
        simUI.setEnabled(ui,1365,simStopped,true)
        simUI.setEnabled(ui,2,simStopped,true)
        simUI.setEnabled(ui,92,simStopped,true)
        simUI.setEnabled(ui,94,simStopped,true)
 --       simUI.setEnabled(ui,300,simStopped,true)
        simUI.setEnabled(ui,95,simStopped,true)
        simUI.setEnabled(ui,96,simStopped,true)
        simUI.setEnabled(ui,97,simStopped,true)
        simUI.setEnabled(ui,301,simStopped and c.frameType==1,true)
        simUI.setEnabled(ui,303,simStopped and c.frameType==1,true)
        simUI.setEnabled(ui,611,simStopped,true)
        simUI.setEnabled(ui,612,simStopped,true)
        simUI.setEnabled(ui,621,simStopped,true)
        simUI.setEnabled(ui,501,simStopped,true)
        simUI.setEnabled(ui,502,simStopped,true)
        simUI.setEnabled(ui,503,simStopped,true)
        simUI.setEnabled(ui,504,simStopped,true)
        simUI.setEnabled(ui,601,simStopped,true)
        simUI.setEnabled(ui,602,simStopped,true)
        simUI.setEnabled(ui,603,simStopped,true)
        simUI.setEnabled(ui,604,simStopped,true)
        simUI.setEnabled(ui,2001,simStopped,true)

        
        simUI.setEnabled(ui,3,simStopped,true)
        simUI.setEnabled(ui,305,simStopped and sim.boolAnd32(c.bitCoded,256)>0,true)

        simUI.setEnabled(ui,3002,simStopped,true)
        simUI.setEnabled(ui,3003,simStopped and sim.boolAnd32(c.bitCoded,1)>0,true)
        simUI.setEnabled(ui,3000,simStopped and sim.boolAnd32(c.bitCoded,1)>0,true)
        simUI.setEnabled(ui,3001,simStopped and sim.boolAnd32(c.bitCoded,1)>0,true)
        
--        simUI.setEnabled(ui,3004,simStopped,true)
--        simUI.setEnabled(ui,3005,simStopped,true)
        
        local online=simBWF.isSystemOnline()
        simUI.setEnabled(ui,4899,simStopped,true)
        simUI.setEnabled(ui,1200,simStopped,true)
        simUI.setEnabled(ui,1201,simStopped,true)
        simUI.setEnabled(ui,1202,simStopped,true)
        simUI.setEnabled(ui,1303,simStopped,true)
        simUI.setEnabled(ui,1203,simStopped,true)
        
        local runningOnline=not simStopped and online
        local runningSim=not simStopped and not online
        
        simUI.setEnabled(ui,1304,runningSim or simStopped,true)
        simUI.setEnabled(ui,1305,runningSim or simStopped,true)
        simUI.setEnabled(ui,1306,runningSim or simStopped,true)
--        simUI.setEnabled(ui,1311,simStopped,true)
        
        simUI.setEnabled(ui,1204,runningOnline or simStopped,true)
        simUI.setEnabled(ui,1205,runningOnline or simStopped,true)
        simUI.setEnabled(ui,1206,runningOnline or simStopped,true)
--        simUI.setEnabled(ui,1211,simStopped,true)

        simUI.setEnabled(ui,1300,simStopped and ( c.robotAlias~=simBWF.NONE_TEXT or c.deviceId~=simBWF.NONE_TEXT ),true)
        
        simUI.setEnabled(ui,1307,runningSim or simStopped,true)
        simUI.setEnabled(ui,1308,(runningSim or simStopped) and c.clearance[1],true)
  --      simUI.setEnabled(ui,1309,(runningSim or simStopped) and c.clearance[1],true)
        simUI.setEnabled(ui,1310,(runningSim or simStopped) and c.clearance[1],true)
    
    end
end

function refreshDlg()
    if ui then
        local c=readInfo()
        local sel=simBWF.getSelectedEditWidget(ui)
        simUI.setEditValue(ui,1365,simBWF.getObjectAltName(model),true)
        simUI.setSliderValue(ui,2,(c['primaryArmLengthInMM']-200)/50,true)
        simUI.setSliderValue(ui,92,(c['secondaryArmLengthInMM']-400)/50,true)
        simUI.setSliderValue(ui,94,c['frameHeightInMM']/50,true)
        
        simUI.setCheckboxValue(ui,3,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],256)~=0),true)
        simUI.setCheckboxValue(ui,305,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],512)~=0),true)
        
        simUI.setCheckboxValue(ui,3002,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],1)~=0),true)
        simUI.setCheckboxValue(ui,3003,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],4)~=0),true)
        
        for i=1,2,1 do
            local wsBoxPt=c.wsBox[i]
            simUI.setEditValue(ui,3000+i-1,simBWF.format("%.0f , %.0f , %.0f",wsBoxPt[1]*1000,wsBoxPt[2]*1000,wsBoxPt[3]*1000),true)
        end
        
        
        for i=1,2,1 do
            local coord=c.waitLocAfterPickOrPlace[i]
            simUI.setEditValue(ui,3004+i-1,simBWF.format("%.0f , %.0f , %.0f",coord[1]*1000,coord[2]*1000,coord[3]*1000),true)
        end
        
        
        
        simUI.setCheckboxValue(ui,301,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],2)~=0),true)
        simUI.setCheckboxValue(ui,303,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],8)~=0),true)
        simUI.setCheckboxValue(ui,1000,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],64)~=0),true)
        simUI.setCheckboxValue(ui,304,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],128)~=0),true)
        simUI.setCheckboxValue(ui,2000,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],1024)~=0),true)
        simUI.setCheckboxValue(ui,2001,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],2048)~=0),true)
        simUI.setCheckboxValue(ui,1304,simBWF.getCheckboxValFromBool(c.showPlot[1]),true)
        simUI.setCheckboxValue(ui,1306,simBWF.getCheckboxValFromBool(c.showTrajectory[1]),true)
        simUI.setCheckboxValue(ui,1204,simBWF.getCheckboxValFromBool(c.showPlot[2]),true)
        simUI.setCheckboxValue(ui,1206,simBWF.getCheckboxValFromBool(c.showTrajectory[2]),true)
        
--        simUI.setCheckboxValue(ui,1311,simBWF.getCheckboxValFromBool(c.gripperActionsWithColorChange[1]),true)
--        simUI.setCheckboxValue(ui,1211,simBWF.getCheckboxValFromBool(c.gripperActionsWithColorChange[2]),true)
        
        
        simUI.setCheckboxValue(ui,1307,simBWF.getCheckboxValFromBool(c.clearance[1]),true)
        simUI.setCheckboxValue(ui,1308,simBWF.getCheckboxValFromBool(c.clearanceWithPlatform[1]),true)
  --      simUI.setCheckboxValue(ui,1309,simBWF.getCheckboxValFromBool(c.clearanceForAllSteps[1]),true)
        if c['clearanceWarning'][1]<0.001 then
            simUI.setEditValue(ui,1310,simBWF.NONE_TEXT,true)
        else
            simUI.setEditValue(ui,1310,simBWF.format("%i",c['clearanceWarning'][1]*1000),true)
        end

--        simUI.setEditValue(ui,1200,c['robotAlias'],true)
        simUI.setEditValue(ui,1303,simBWF.format("%i",c['connectionBufferSize'][1]),true)
        simUI.setEditValue(ui,1203,simBWF.format("%i",c['connectionBufferSize'][2]),true)
--        simUI.setCheckboxValue(ui,1208,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],8192)~=0),true)
--        simUI.setCheckboxValue(ui,1209,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],16384)~=0),true)
        simUI.setLabelText(ui,1,'Primary arm length: '..simBWF.format("%.0f",c['primaryArmLengthInMM'])..' mm')
        simUI.setLabelText(ui,91,'Secondary arm length: '..simBWF.format("%.0f",c['secondaryArmLengthInMM'])..' mm')
        simUI.setLabelText(ui,93,'Robot Z position: '..simBWF.format("%.0f",c['frameHeightInMM'])..' mm')
        simUI.setEditValue(ui,10,simBWF.format("%.0f",c['maxVel']*1000),true)
        simUI.setEditValue(ui,11,simBWF.format("%.0f",c['maxAccel']*1000),true)
        simUI.setEditValue(ui,13,simBWF.format("%.0f",c['dynamics']*180/math.pi),true)

        updatePickTrackingWindowComboboxes()
        updatePlaceTrackingWindowComboboxes()
        updatePickFrameComboboxes()
        updatePlaceFrameComboboxes()
        updateAliasCombobox()
        updateDeviceIdCombobox()
        updateMotorTypeCombobox()
        updateExteriorTypeCombobox()
        updateFrameTypeCombobox()
        updateConveyorComboboxes()
        
        local updateFrequComboItems={
            {"every 50 ms",0},
            {"every 200 ms",1},
            {"every 1000 ms",2}
        }
        sim.UI_populateCombobox(ui,1305,updateFrequComboItems,{},updateFrequComboItems[c['visualizeUpdateFrequ'][1]+1][1],false,nil)
        sim.UI_populateCombobox(ui,1205,updateFrequComboItems,{},updateFrequComboItems[c['visualizeUpdateFrequ'][2]+1][1],false,nil)
        
        updateEnabledDisabledItems()
        simBWF.setSelectedEditWidget(ui,sel)
    end
end

function nameChange(ui,id,newVal)
    if simBWF.setObjectAltName(model,newVal)>0 then
        simBWF.markUndoPoint()
        updatePluginRepresentation()
        simUI.setTitle(ui,simBWF.getUiTitleNameFromModel(model,_MODELVERSION_,_CODEVERSION_))
    end
    refreshDlg()
end

function wsBox_change(ui,id,newValue)
    local tolU=0
    local tolL=0.05
    local index=id-3000+1
    if index==1 then
        tolU=0.05
        tolL=0
    end
    local c=readInfo()
    local i=1
    local t={0,0,0}
    for token in (newValue..","):gmatch("([^,]*),") do
        t[i]=tonumber(token)
        if t[i]==nil then t[i]=0 end
        t[i]=t[i]*0.001
        
        if index==1 then
            if t[i]>c.wsBox[2][i]-tolU then t[i]=c.wsBox[2][i]-tolU end
        else
            if t[i]<c.wsBox[1][i]+tolL then t[i]=c.wsBox[1][i]+tolL end
        end
        
        if t[i]>1-tolU then t[i]=1-tolU end
        if t[i]<-1+tolL then t[i]=-1+tolL end
        i=i+1
    end
    c.wsBox[index]={t[1],t[2],t[3]}
    writeInfo(c)
    adjustWsBox()
    simBWF.markUndoPoint()
    updatePluginRepresentation()
    refreshDlg()
end

function waitingLocationAfterPickOrPlace_change(ui,id,newValue)
    local index=id-3004+1
    local c=readInfo()
    local i=1
    local t={0,0,0}
    for token in (newValue..","):gmatch("([^,]*),") do
        t[i]=tonumber(token)
        if t[i]==nil then t[i]=0 end
        t[i]=t[i]*0.001
        
        if t[i]>0.5 then t[i]=0.5 end
        if t[i]<-0.5 then t[i]=-0.5 end
        
        i=i+1
    end
    c.waitLocAfterPickOrPlace[index]={t[1],t[2],t[3]}
    writeInfo(c)
    simBWF.markUndoPoint()
    updatePluginRepresentation_dynParams()
    refreshDlg()
end

function createDlg()
    if (not ui) and simBWF.canOpenPropertyDialog() then
        local xml =[[
    <tabs id="78">
    <tab title="General">
            <group layout="form" flat="false">
                <label text="Name"/>
                <edit on-editing-finished="nameChange" id="1365"/>
                
                <label text="Enabled"/>
                <checkbox text="" on-change="enabledClicked_callback" id="1000"/>

                <label text="Maximum speed (mm/s)"/>
                <edit on-editing-finished="velocityChange_callback" id="10"/>

                <label text="Maximum acceleration (mm/s^2)"/>
                <edit on-editing-finished="accelerationChange_callback" id="11"/>

                <label text="Dynamics (deg/s)"/>
                <edit on-editing-finished="dynamicsChange_callback" id="13"/>
                
                <label text="Show statistics"/>
                <checkbox text="" checked="false" on-change="showStatisticsClick_callback" id="304"/>
            </group>
            <group layout="form" flat="false">
                <label text="Workspace" style="* {font-weight: bold;}"/>  <label text=""/>

                <label text="Show actual workspace"/>
                <checkbox text="" checked="false" on-change="visualizeWorkspaceClick_callback" id="3"/>

                <label text="Show actual workspace also when running"/>
                <checkbox text="" checked="false" on-change="visualizeWorkspaceSimClick_callback" id="305"/>

                <label text="Show workspace box"/>
                <checkbox text="" checked="false" on-change="visualizeWsBoxClick_callback" id="3002"/>

                <label text="Show workspace box also when running"/>
                <checkbox text="" checked="false" on-change="visualizeWsBoxSimClick_callback" id="3003"/>
                
                <label text="workspace box min. coordinate (X, Y, Z, in mm)"/>
                <edit on-editing-finished="wsBox_change" id="3000"/>
                
                <label text="workspace box max. coordinate (X, Y, Z, in mm)"/>
                <edit on-editing-finished="wsBox_change" id="3001"/>
                
            </group>
    </tab>
    <tab title="Pick/Place">

            <group layout="form" flat="false">
                <label text="Waiting locations" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="After pick (X, Y, Z, in mm)"/>
                <edit on-editing-finished="waitingLocationAfterPickOrPlace_change" id="3004"/>

                <label text="After place (X, Y, Z, in mm)"/>
                <edit on-editing-finished="waitingLocationAfterPickOrPlace_change" id="3005"/>

            </group>
            
            <group layout="form" flat="false">
                <label text="Other" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="Pick also without target in sight (override)"/>
                <checkbox text="" on-change="pickWithoutTargetClicked_callback" id="2001"/>

                <label text="Attach part to target"/>
                <checkbox text="" on-change="attachPartClicked_callback" id="2000"/>
            </group>
    </tab>
    <tab title="Configuration">
            <group layout="form" flat="false">
                <label text="Pick" style="* {font-weight: bold;}"/>  <label text=""/>

                <label text="Tracking window 1"/>
                <combobox id="611" on-change="pickTrackingWindowChange_callback">
                </combobox>

                <label text="Tracking window 2"/>
                <combobox id="612" on-change="pickTrackingWindowChange_callback">
                </combobox>

                <label text="Location frame 1"/>
                <combobox id="601" on-change="pickFrameChange_callback">
                </combobox>

                <label text="Location frame 2"/>
                <combobox id="602" on-change="pickFrameChange_callback">
                </combobox>

                <label text="Location frame 3"/>
                <combobox id="603" on-change="pickFrameChange_callback">
                </combobox>

                <label text="Location frame 4"/>
                <combobox id="604" on-change="pickFrameChange_callback">
                </combobox>
            </group>

            <group layout="form" flat="false">
                <label text="Place" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="Tracking window 1"/>
                <combobox id="621" on-change="placeTrackingWindowChange_callback">
                </combobox>

                <label text="Location frame 1"/>
                <combobox id="501" on-change="placeFrameChange_callback">
                </combobox>

                <label text="Location frame 2"/>
                <combobox id="502" on-change="placeFrameChange_callback">
                </combobox>

                <label text="Location frame 3"/>
                <combobox id="503" on-change="placeFrameChange_callback">
                </combobox>

                <label text="Location frame 4"/>
                <combobox id="504" on-change="placeFrameChange_callback">
                </combobox>
            </group>
    </tab>
    <tab title="Robot">
            <group layout="form" flat="false">
                <label text="Type" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="Primary arm length" id="1"/>
                <hslider tick-position="above" tick-interval="1" minimum="0" maximum="7" on-change="sizeAChange_callback" id="2"/>

                <label text="Secondary arm length" id="91"/>
                <hslider tick-position="above" tick-interval="1" minimum="0" maximum="17" on-change="sizeBChange_callback" id="92"/>

                <label text="Robot Z position" id="93"/>
                <hslider tick-position="above" tick-interval="1" minimum="24" maximum="48" on-change="frameHeightChange_callback" id="94"/>

                <label text="Motor type"/>
                <combobox id="95" on-change="motorTypeChange_callback"></combobox>

                <label text="Exterior type"/>
                <combobox id="96" on-change="exteriorTypeChange_callback"></combobox>

                <label text="Frame type"/>
                <combobox id="97" on-change="frameTypeChange_callback"></combobox>
            </group>

            <group layout="form" flat="false">
                <label text="Other" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="Frame is open"/>
                <checkbox text="" checked="false" on-change="openFrameClick_callback" id="301"/>

                <label text="Frame low beams are visible"/>
                <checkbox text="" checked="false" on-change="visibleFrameLowBeamsClick_callback" id="303"/>

            </group>
    </tab>
    <tab title="Simulation">
            <group layout="form" flat="false">
                <label text="Visualization" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="Buffer size (states)"/>
                <edit on-editing-finished="simBufferSize_callback" id="1303"/>

                <label text="Show robot plot"/>
                <checkbox text="" checked="false" on-change="simShowRobotPlotClick_callback" id="1304"/>
                
                <label text="Show trajectory"/>
                <checkbox text="" checked="false" on-change="simShowTrajectoryClick_callback" id="1306"/>

                <label text="Show robot clearance plot"/>
                <checkbox text="" checked="false" on-change="showClearanceClick_callback" id="1307"/>
 
                <label text="Include platform & gripper"/>
                <checkbox text="" checked="false" on-change="clearanceWithPlatformClick_callback" id="1308"/>
                
                <label text="Clearance warning (mm)"/>
                <edit on-editing-finished="clearanceWarning_callback" id="1310"/>
                
                <label text="Update frequency"/>
                <combobox id="1305" on-change="simVisualizeUpdateFrequChange_callback"></combobox>
            </group>
            <group layout="form" flat="true">
                <label text="" style="* {margin-left: 200px;}"/>
                <label text="" style="* {margin-left: 200px;}"/>
            </group>
    </tab>
    <tab title="Online">
            <group layout="form" flat="false">
                <label text="Visualization" style="* {font-weight: bold;}"/>  <label text=""/>

                <label text="Buffer size (states)"/>
                <edit on-editing-finished="realBufferSize_callback" id="1203"/>

                <label text="Show robot plot"/>
                <checkbox text="" checked="false" on-change="realShowRobotPlotClick_callback" id="1204"/>
                
                <label text="Show trajectory"/>
                <checkbox text="" checked="false" on-change="realShowTrajectoryClick_callback" id="1206"/>

                <label text="Update frequency"/>
                <combobox id="1205" on-change="realVisualizeUpdateFrequChange_callback"></combobox>
            </group>
            <group layout="form" flat="false">
                <label text="Real robot specific" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="Device ID"/>
                <combobox id="4899" on-change="deviceIdComboChange_callback"> </combobox>
                
                <label text="Robot serial"/>
                <combobox id="1200" on-change="aliasComboChange_callback"> </combobox>

                <label text=""/>
                <button text="Identify"  on-click="identificationAndRenaming_identification_callback" id="1300" />
                
                <label text="Conveyor 1"/>
                <combobox id="1201" on-change="conveyorChange_callback"> </combobox>
                
                <label text="Conveyor 2"/>
                <combobox id="1202" on-change="conveyorChange_callback"> </combobox>
            </group>
    </tab>
    </tabs>
        ]]
        
--[=[
                <label text="Platform color change with gripper action"/>
                <checkbox text="" checked="false" on-change="gripperActionColorChangeClick_callback" id="1311"/>

                <label text="Platform color change with gripper action"/>
                <checkbox text="" checked="false" on-change="gripperActionColorChangeClick_callback" id="1211"/>
--]=]                

        ui=simBWF.createCustomUi(xml,simBWF.getUiTitleNameFromModel(model,_MODELVERSION_,_CODEVERSION_),previousDlgPos--[[,closeable,onCloseFunction,modal,resizable,activate,additionalUiAttribute--]])
        refreshDlg()

        simUI.setCurrentTab(ui,78,dlgMainTabIndex,true)
    end
end

function showDlg()
    if not ui then
        createDlg()
    end
end

function removeDlg()
    if ui then
        local x,y=simUI.getPosition(ui)
        previousDlgPos={x,y}
        dlgMainTabIndex=simUI.getCurrentTab(ui,78)
        simUI.destroy(ui)
        ui=nil
    end
end

function executeIk(platformInNominalConfig)
    if platform>=0 then
        if platformInNominalConfig then
            local inf=readInfo()
            local primaryArmLengthInMM=inf['primaryArmLengthInMM']
            local secondaryArmLengthInMM=inf['secondaryArmLengthInMM']
            sim.setObjectPosition(platform,sim.handle_parent,{0,0,-(secondaryArmLengthInMM-primaryArmLengthInMM)/1000-0.2})
            sim.setObjectOrientation(platform,sim.handle_parent,{0,0,0})
        end

        for i=1,4,1 do
            -- We handle each branch individually:
            local ld=sim.getLinkDummy(ikTips[i])
            if ld>=0 then
                -- We make sure we don't perform too large jumps:
                local p=sim.getObjectPosition(ikTips[i],ld)
                local l=math.sqrt(p[1]*p[1]+p[2]*p[2]+p[3]*p[3])
                local steps=math.ceil(0.00001+l/0.05)
                local start=sim.getObjectPosition(ikTips[i],-1)
                local goal=sim.getObjectPosition(ld,-1)
                for j=1,steps,1 do
                    local t=j/steps
                    local pos={start[1]*(1-t)+goal[1]*t,start[2]*(1-t)+goal[2]*t,start[3]*(1-t)+goal[3]*t}
                    sim.setObjectPosition(ld,-1,pos)
                    sim.handleIkGroup(ikGroups[i])
                end
            end
        end
    end
end

function checkPlatformAttachment()
    -- Check if there is already a platform attached:
    local objs=sim.getObjectsInTree(ragnarGripperPlatformAttachment,sim.handle_all,1+2)
    local platf=nil
    for i=1,#objs,1 do
        if sim.readCustomDataBlock(objs[i],simBWF.RAGNARGRIPPERPLATFORM_TAG) then
            platf=objs[i]
            platform=platf
            break
        end
    end
    -- Check if a previous platform was detached but is still linked via IK:
    if not platf then
        for i=1,4,1 do
            local ld=sim.getLinkDummy(ikTips[i])
            if ld>=0 then
                -- Yes, we delete the linked dummy on that old platform:
                sim.removeObject(ld)
            end
        end
    end
    -- Now check if we want to attach a new platform to Ragnar:
    local objs=sim.getObjectsInTree(model,sim.handle_all,1+2)
    local nPlatf=nil
    for i=1,#objs,1 do
        if sim.readCustomDataBlock(objs[i],simBWF.RAGNARGRIPPERPLATFORM_TAG) then
            nPlatf=objs[i]
            break
        end
    end
    if nPlatf then
        -- yes! First remove a possible old platform:
        if platf then
            sim.removeModel(platf)
        end
        -- Set the IK joints into nominal position
        for i=1,4,1 do
            local objs=sim.getObjectsInTree(motorJoints[i],sim.object_joint_type,0)
            for j=1,#objs,1 do
                if sim.getJointMode(objs[j])==sim.jointmode_ik then
                    sim.setJointPosition(objs[j],0)
                end
            end
        end
        -- Now correctly attach the new platform and create target dummies
        sim.setObjectParent(nPlatf,ragnarGripperPlatformAttachment,true)
        local objs=sim.getObjectsInTree(nPlatf,sim.object_dummy_type,1)
        for i=1,#objs,1 do
            local data=sim.readCustomDataBlock(objs[i],simBWF.RAGNARGRIPPERPLATFORMIKPT_TAG)
            if data then
                data=sim.unpackTable(data)
                local dum=sim.copyPasteObjects({objs[i]},0)[1]
                sim.setObjectParent(dum,objs[i],true)
                sim.setLinkDummy(ikTips[data.index],dum)
                sim.setObjectInt32Parameter(dum,sim.dummyintparam_link_type,sim.dummy_linktype_ik_tip_target)
            end
        end
        platform=nPlatf
        executeIk(true)
        updateEnabledDisabledItems()
    else
        if not platf then
            local platformRemoved=(platform~=-1)
            platform=-1
            -- Set the IK joints into nominal position
            for i=1,4,1 do
                local objs=sim.getObjectsInTree(motorJoints[i],sim.object_joint_type,0)
                for j=1,#objs,1 do
                    if sim.getJointMode(objs[j])==sim.jointmode_ik then
                        sim.setJointPosition(objs[j],0)
                    end
                end
            end
            if platformRemoved then
                updateEnabledDisabledItems()
            end
        end
    end
end

function sysCall_init()
    CIC=4 -- Connected Item Count (for each category: pick tracking window, place tracking window, pick location frame, place location frame)
    ECIC_PiW= 2 -- Exposed Connected Item Count, Pick Window
    ECIC_PlW= 1 -- Exposed Connected Item Count, Place Window
    ECIC_PiL= 4 -- Exposed Connected Item Count, Pick Location
    ECIC_PlL= 4 -- Exposed Connected Item Count, Place Location
    
    MOTORTYPELIST={0,1,2}
    MOTORTYPES={}
    MOTORTYPES[MOTORTYPELIST[1]]={text='standard',pricingText='standard',maxVel=5,maxAccel=35}
    MOTORTYPES[MOTORTYPELIST[2]]={text='high-power',pricingText='high-power',maxVel=2.5,maxAccel=25}
    MOTORTYPES[MOTORTYPELIST[3]]={text='high-torque',pricingText='high-torque',maxVel=2.5,maxAccel=25}

    EXTERIORTYPELIST={0,1}
    EXTERIORTYPES={}
    EXTERIORTYPES[EXTERIORTYPELIST[1]]={text='standard',pricingText='std'}
    EXTERIORTYPES[EXTERIORTYPELIST[2]]={text='wash-down',pricingText='wd'}

    FRAMETYPELIST={0,1}
    FRAMETYPES={}
    FRAMETYPES[FRAMETYPELIST[1]]={text='experimental',pricingText='experimental'}
    FRAMETYPES[FRAMETYPELIST[2]]={text='industrial',pricingText='industrial'}

    
    
    
    
    version=sim.getInt32Parameter(sim.intparam_program_version)
    revision=sim.getInt32Parameter(sim.intparam_program_revision)

    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    _MODELVERSION_=1
    _CODEVERSION_=1
    local _info=readInfo()
    simBWF.checkIfCodeAndModelMatch(model,_CODEVERSION_,_info['version'])
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    writeInfo(_info)

    adjustMaxVelocityMaxAcceleration()

    ragnarRef=sim.getObjectHandle('Ragnar_ref')
    ragnarGripperPlatformAttachment=sim.getObjectHandle('Ragnar_gripperPlatformAttachment')
    ragnarWs=sim.getObjectHandle('Ragnar_ws')
    ragnarWsBox=sim.getObjectHandle('Ragnar_wsBox')
    
    alphaOffsetJ1=sim.getObjectHandle('Ragnar_zRotLeftFront')
    betaOffsetJ1=sim.getObjectHandle('Ragnar_xRotLeftFront')
    xOffsetJ1=sim.getObjectHandle('Ragnar_yOffsetLeft')
    yOffsetJ1=sim.getObjectHandle('Ragnar_xOffsetLeftFront')
 
    
    
    ikTips={}
    for i=1,4,1 do
        ikTips[i]=sim.getObjectHandle('Ragnar_secondaryArm'..i..'a_tip')
    end

    motorJoints={}
    for i=1,4,1 do
        motorJoints[i]=sim.getObjectHandle('Ragnar_motor'..i)
    end
    
    tiltAdjustmentAngles={}
    tiltAdjustmentAngles[1]=-sim.getJointPosition(sim.getObjectHandle('Ragnar_xRotLeftFront'))
    tiltAdjustmentAngles[2]=sim.getJointPosition(sim.getObjectHandle('Ragnar_xRotRightFront'))
    tiltAdjustmentAngles[3]=sim.getJointPosition(sim.getObjectHandle('Ragnar_xRotRightRear'))
    tiltAdjustmentAngles[4]=-sim.getJointPosition(sim.getObjectHandle('Ragnar_xRotLeftRear'))
    panAdjustmentAngles={}
    panAdjustmentAngles[1]=-sim.getJointPosition(sim.getObjectHandle('Ragnar_zRotLeftFront'))
    panAdjustmentAngles[2]=sim.getJointPosition(sim.getObjectHandle('Ragnar_zRotRightFront'))
    panAdjustmentAngles[3]=-sim.getJointPosition(sim.getObjectHandle('Ragnar_zRotRightRear'))
    panAdjustmentAngles[4]=sim.getJointPosition(sim.getObjectHandle('Ragnar_zRotLeftRear'))
    

    ikGroups={}
    for i=1,4,1 do
        ikGroups[i]=sim.getIkGroupHandle('ragnarIk_arm'..i)
    end

    dlgMainTabIndex=0

    primaryArms={}
    secondaryArms={}

    primaryArmsEndAdjust={}
    secondaryArmsEndAdjust={}

    primaryArmsLAdjust={}
    secondaryArmsLAdjust={}

    leftAndRightSideAdjust={sim.getObjectHandle('Ragnar_yOffsetLeft'),sim.getObjectHandle('Ragnar_yOffsetRight')}
    middleCoverParts={}

    for i=1,4,1 do
        primaryArms[#primaryArms+1]=sim.getObjectHandle('Ragnar_primaryArm'..i..'_part2')
        secondaryArms[#secondaryArms+1]=sim.getObjectHandle('Ragnar_secondaryArm'..i..'a_part2')
        secondaryArms[#secondaryArms+1]=sim.getObjectHandle('Ragnar_secondaryArm'..i..'b_part2')

        primaryArmsEndAdjust[#primaryArmsEndAdjust+1]=sim.getObjectHandle('Ragnar_primaryArm'..i..'_adjustJ2')
        secondaryArmsEndAdjust[#secondaryArmsEndAdjust+1]=sim.getObjectHandle('Ragnar_secondaryArm'..i..'a_adjustJ2')
        secondaryArmsEndAdjust[#secondaryArmsEndAdjust+1]=sim.getObjectHandle('Ragnar_secondaryArm'..i..'b_adjustJ2')

        primaryArmsLAdjust[#primaryArmsLAdjust+1]=sim.getObjectHandle('Ragnar_primaryArm'..i..'_adjustJ1')
        secondaryArmsLAdjust[#secondaryArmsLAdjust+1]=sim.getObjectHandle('Ragnar_secondaryArm'..i..'a_adjustJ1')
        secondaryArmsLAdjust[#secondaryArmsLAdjust+1]=sim.getObjectHandle('Ragnar_secondaryArm'..i..'b_adjustJ1')
    end

    centralCover={}
    centralCover[1]=sim.getObjectHandle('Ragnar_centralCover1')
    centralCover[2]=sim.getObjectHandle('Ragnar_centralCover2')
    centralCover[3]=sim.getObjectHandle('Ragnar_centralCover3')
    nameElement={}
    nameElement[1]=sim.getObjectHandle('Ragnar_frontName')
    nameElement[2]=sim.getObjectHandle('Ragnar_rearName')

    frameModel=sim.getObjectHandle('Ragnar_frame')
    frameBeams={}
    for i=1,8,1 do
        frameBeams[i]=sim.getObjectHandle('Ragnar_frame_beam'..i)
    end
    frameJoints={}
    frameJoints[1]=sim.getObjectHandle('Ragnar_frame_widthJ1')
    frameJoints[2]=sim.getObjectHandle('Ragnar_frame_widthJ2')
    frameJoints[3]=sim.getObjectHandle('Ragnar_frame_heightJ1')
    frameJoints[4]=sim.getObjectHandle('Ragnar_frame_heightJ2')
    frameJoints[5]=sim.getObjectHandle('Ragnar_frame_heightJ3')
    frameJoints[6]=sim.getObjectHandle('Ragnar_frame_heightJ4')
    frameJoints[7]=sim.getObjectHandle('Ragnar_frame_lengthJ1')
    frameJoints[8]=sim.getObjectHandle('Ragnar_frame_lengthJ2')
    frameJoints[9]=sim.getObjectHandle('Ragnar_frame_lengthJ3')
    frameJoints[10]=sim.getObjectHandle('Ragnar_frame_lengthJ4')

    frameOpenClose={}
    for i=1,3,1 do
        frameOpenClose[i]=sim.getObjectHandle('Ragnar_frame_openCloseJ'..i)
    end

    checkPlatformAttachment()
    updatePluginRepresentation()
    previousDlgPos,algoDlgSize,algoDlgPos,distributionDlgSize,distributionDlgPos,previousDlg1Pos=simBWF.readSessionPersistentObjectData(model,"dlgPosAndSize")
end

function showOrHideUiIfNeeded()
    local s=sim.getObjectSelection()
    if s and #s>=1 and s[#s]==model then
        showDlg()
    else
        removeDlg()
    end
end

function applyCalibrationData()
    -- We basically need to adjust the position and orientation of Ragnar, if it is connected to
    -- at least one calibrated tracking window:

    local info=readInfo()
    local windAndCal={}
    for i=1,CIC,1 do
        local id=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF+i-1)
        if id>=0 then
            local m=simBWF.callCustomizationScriptFunction('ext_getCalibrationMatrix',id)
            if m~=nil then
                windAndCal[#windAndCal+1]={id,m}
            end
        end
        local id=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF+i-1)
        if id>=0 then
            local m=simBWF.callCustomizationScriptFunction('ext_getCalibrationMatrix',id)
            if m~=nil then
                windAndCal[#windAndCal+1]={id,m}
            end
        end
    end
    if #windAndCal>0 then
        for i=1,#windAndCal,1 do
            local winId=windAndCal[i][1]
            local m=windAndCal[i][2]
            -- Here we keep the tracking window in place (i.e. its red calibration ball), and adjust the position/orientation of the robot instead:
            sim.invertMatrix(m)
            local mWindow=sim.getObjectMatrix(winId,-1)
            local newAbsRefM=sim.multiplyMatrices(mWindow,m)
            windAndCal[i][3]=newAbsRefM -- this is the desired abs transf. of the Ragnar ref. (for this tracking window)
        end

        local m
        for i=1,#windAndCal,1 do
            local winId=windAndCal[i][1]
            local matr=windAndCal[i][3]
            if i==1 then
                m=matr
            else
--                m=matr
                m=sim.interpolateMatrices(m,matr,1/i)
            end
        end

        -- If we just want to slightly adjust the X/Y position of the robot (no orientation, nor Z change):
        local allowFullAdjustment=true
        local allowZAdjustment=true
        if allowFullAdjustment then
            local locRefMInv=sim.getObjectMatrix(ragnarRef,model)
            sim.invertMatrix(locRefMInv)
            local toApplyM=sim.multiplyMatrices(m,locRefMInv)
            sim.setObjectMatrix(model,-1,toApplyM)
        else
            local absRefV=sim.getObjectPosition(ragnarRef,-1)
            local p=sim.getObjectPosition(model,-1)
            local nAbsRefV={m[4],m[8],absRefV[3]}
            if allowZAdjustment then
                nAbsRefV[3]=m[12]
                p[3]=p[3]+nAbsRefV[3]-absRefV[3]
            end
            p[1]=p[1]+nAbsRefV[1]-absRefV[1]
            p[2]=p[2]+nAbsRefV[2]-absRefV[2]
            sim.setObjectPosition(model,-1,p)
        end

--        local r,p=sim.getObjectInt32Parameter(model,sim.objintparam_manipulation_permissions)
--        r=sim.boolOr32(r,1+4+16+32)-(1+4) -- forbid rotation and translation when simulation is not running
--        sim.setObjectInt32Parameter(model,sim.objintparam_manipulation_permissions,r)
--    else
--        local r,p=sim.getObjectInt32Parameter(model,sim.objintparam_manipulation_permissions)
--        r=sim.boolOr32(r,1+4+16+32) -- allow rotation and translation when simulation is not running
--        sim.setObjectInt32Parameter(model,sim.objintparam_manipulation_permissions,r)
    end
end

function setAttachedLocationFramesIntoCalibrationPose()
    for i=1,CIC,1 do
        local frameHandle=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PICKFRAME1_REF+i-1)
        if frameHandle>=0 then
            simBWF.callCustomizationScriptFunction('ext_setLocationFrameIntoOnlineCalibrationPose',frameHandle)
        end
        local frameHandle=simBWF.getReferencedObjectHandle(model,simBWF.RAGNAR_PLACEFRAME1_REF+i-1)
        if frameHandle>=0 then
            simBWF.callCustomizationScriptFunction('ext_setLocationFrameIntoOnlineCalibrationPose',frameHandle)
        end
    end
end

function sysCall_nonSimulation()
    showOrHideUiIfNeeded()
    checkPlatformAttachment()
    updatePluginRepresentation_ifNeeded()
    if workspaceUpdateRequest and sim.getSystemTimeInMs(workspaceUpdateRequest)>2000 then
        workspaceUpdateRequest=nil
        updateWs()
    end
--    applyCalibrationData() -- can potentially change the position/orientation of the robot
end

function sysCall_sensing()
    if simJustStarted then
        updateEnabledDisabledItems()
    end
    simJustStarted=nil
    showOrHideUiIfNeeded()
    ext_outputPluginRuntimeMessages()
end

function sysCall_suspended()
    showOrHideUiIfNeeded()
end

function sysCall_afterSimulation()
    if ragnarNormalM then
        sim.setObjectMatrix(model,-1,ragnarNormalM)
        ragnarNormalM=nil
    end
    updateEnabledDisabledItems()
    local c=readInfo()
    if sim.boolAnd32(c['bitCoded'],256)==256 then
        sim.setObjectInt32Parameter(ragnarWs,sim.objintparam_visibility_layer,1)
    else
        sim.setObjectInt32Parameter(ragnarWs,sim.objintparam_visibility_layer,0)
    end
    if sim.boolAnd32(c['bitCoded'],1)==1 then
        sim.setObjectInt32Parameter(ragnarWsBox,sim.objintparam_visibility_layer,1)
    else
        sim.setObjectInt32Parameter(ragnarWsBox,sim.objintparam_visibility_layer,0)
    end
end

function sysCall_beforeSimulation()
    simJustStarted=true
    ext_outputBrSetupMessages()
    ext_outputPluginSetupMessages()
    local c=readInfo()
    local showWs=simBWF.modifyAuxVisualizationItems(sim.boolAnd32(c['bitCoded'],256+512)==256+512)
    if showWs then
        sim.setObjectInt32Parameter(ragnarWs,sim.objintparam_visibility_layer,1)
    else
        sim.setObjectInt32Parameter(ragnarWs,sim.objintparam_visibility_layer,0)
    end
    local showWsBox=simBWF.modifyAuxVisualizationItems(sim.boolAnd32(c['bitCoded'],1+4)==1+4)
    if showWsBox then
        sim.setObjectInt32Parameter(ragnarWsBox,sim.objintparam_visibility_layer,1)
    else
        sim.setObjectInt32Parameter(ragnarWsBox,sim.objintparam_visibility_layer,0)
    end
    if sim.getBoolParameter(sim.boolparam_online_mode) then
        ragnarNormalM=sim.getObjectMatrix(model,-1)
        applyCalibrationData() -- can potentially change the position/orientation of the robot
        setAttachedLocationFramesIntoCalibrationPose()
    end
end

function sysCall_beforeInstanceSwitch()
    removeDlg()
    removeFromPluginRepresentation()
end

function sysCall_afterInstanceSwitch()
    updatePluginRepresentation()
end

function sysCall_cleanup()
    removeDlg()
    removeFromPluginRepresentation()
    simBWF.writeSessionPersistentObjectData(model,"dlgPosAndSize",previousDlgPos,algoDlgSize,algoDlgPos,distributionDlgSize,distributionDlgPos,previousDlg1Pos)
end

