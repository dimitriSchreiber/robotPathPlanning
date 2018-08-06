function ext_clearCalibration()
    local c=readInfo()
    c.calibration=nil
    c.calibrationMatrix=nil
    writeInfo(c)
    applyCalibrationColor()
    updatePluginRepresentation()
end

function ext_associatedRobotChangedPose()
    updatePluginRepresentation()
end

function ext_getItemData_pricing()
    local obj={}
    obj.name=simBWF.getObjectAltName(model)
    obj.type='trackingWindow'
    obj.windowType='place'
    obj.brVersion=1
    if isPick then
        obj.frameType='pick'
    end
    local dep={}
    local id=simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_INPUT_REF)
    if id>=0 then
        dep[#dep+1]=id
    end
    if #dep>0 then
        obj.dependencies=dep
    end
    return obj
end

function ext_announceOnlineModeChanged(isNowOnline)
    updatePluginRepresentation()
end

function ext_announcePalletWasRenamed()
    refreshDlg()
end

function ext_announcePalletWasCreated()
    refreshDlg()
end

function ext_getAssociatedSensorDetectorOrVisionHandle()
    local h=simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_INPUT_REF)
    while h>=0 do
        local data=sim.readCustomDataBlock(h,simBWF.RAGNARVISION_TAG)
        if data then
            return h
        else
            data=sim.readCustomDataBlock(h,simBWF.RAGNARSENSOR_TAG)
            if data then
                return h
            else
                data=sim.readCustomDataBlock(h,simBWF.RAGNARDETECTOR_TAG)
                if data then
                    return h
                else
                    data=sim.readCustomDataBlock(h,simBWF.TRACKINGWINDOW_TAG)
                    if data then
                        h=simBWF.getReferencedObjectHandle(h,simBWF.TRACKINGWINDOW_INPUT_REF)
                    else
                        h=-1
                    end
                end
            end
        end
    end
    return -1
end

function ext_getCalibrationMatrix()
    local c=readInfo()
    return c['calibrationMatrix']
end

function ext_avoidCircularInput(inputItem)
    -- We have: trackWind --> item1 --> item2 ... --> itemN
    -- None of the above item's input should be 'inputItem'
    -- If 'inputItem' is -1, then none of the above item's input should be 'model'
    -- A. Check this tracking window:
    if inputItem>0 then
        local h=simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_INPUT_REF)
        if h==inputItem then
            simBWF.setReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_INPUT_REF,-1) -- this input closed the loop. We open it here.
            updatePluginRepresentation()
        end
    end
    
    if inputItem==-1 then
        inputItem=model
    end

    -- B. Check connected items:
    local h=simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_INPUT_REF)
    if h>=0 then
        simBWF.callCustomizationScriptFunction("ext_avoidCircularInput",h,inputItem)
    end
end

function ext_forbidInput(inputItem)
    local h=simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_INPUT_REF)
    if h==inputItem then
        simBWF.setReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_INPUT_REF,-1)
        updatePluginRepresentation()
    end
end

function ext_getInputObjectHande()
    return simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_INPUT_REF)
end

function ext_alignCalibrationBallsWithInput()
    local h=simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_INPUT_REF)
    
    -- First align the tracking window with its input item:
    if h>=0 then
        simBWF.callCustomizationScriptFunction("ext_alignCalibrationBallsWithInput",h)

        local p=sim.getObjectOrientation(model,h)
        local correct=(math.abs(p[1])>0.1*math.pi/180) or (math.abs(p[2])>0.1*math.pi/180) or (math.abs(p[3])>0.1*math.pi/180)
        local p=sim.getObjectPosition(model,h)
        correct=correct or (math.abs(p[2])>0.0001) or (math.abs(p[3])>0.0001)

        -- Ball1 should be distant by the calibration ball distance from the connected item's ball1:
        local c=readInfo()
        local d=c['calibrationBallDistance']
        if math.abs(p[1]-d)>0.001 then
            p[1]=d
            correct=true
        end
        if correct then
            sim.setObjectOrientation(model,h,{0,0,0})
            sim.setObjectPosition(model,h,{p[1],0,0})
        end
        
        local r,p=sim.getObjectInt32Parameter(model,sim.objintparam_manipulation_permissions)
        r=sim.boolOr32(r,1+4)-(1+4) -- forbid rotation and translation when simulation is not running
        sim.setObjectInt32Parameter(model,sim.objintparam_manipulation_permissions,r)
    else
        local r,p=sim.getObjectInt32Parameter(model,sim.objintparam_manipulation_permissions)
        r=sim.boolOr32(r,1+4) -- allow rotation and translation when simulation is not running
        sim.setObjectInt32Parameter(model,sim.objintparam_manipulation_permissions,r)
    end
end

function ext_outputBrSetupMessages()
    local nm=' ['..simBWF.getObjectAltName(model)..']'
    local robots=sim.getObjectsWithTag(simBWF.RAGNAR_TAG,true)
    local present=false
    for i=1,#robots,1 do
        if simBWF.callCustomizationScriptFunction_noError('ext_checkIfRobotIsAssociatedWithLocationFrameOrTrackingWindow',robots[i],model) then
            present=true
            break
        end
    end
    local msg=""
    if not present then
        msg="WARNING (set-up): Not referenced by any robot"..nm
    else
        if simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_INPUT_REF)==-1 then
            msg="WARNING (set-up): Has no associated input"..nm
        else
            local c=readInfo()
            if simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_PALLET_REF)==-1 then
                msg="WARNING (set-up): Has no associated pallet"..nm
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

function ext_getCalibrationDataForCurrentMode()
    local data={}
    local c=readInfo()
    local onlSw=sim.getBoolParameter(sim.boolparam_online_mode)
    if c.calibration and onlSw then
        data.realCalibration=true
        data.ball1=c.calibration[1]
        data.ball2=c.calibration[2]
        data.ball3=c.calibration[3]
        data.matrix=c.calibrationMatrix
    else
        data.realCalibration=false
        local rob=getAssociatedRobotHandle()
        if rob>=0 then
            local associatedRobotRef=simBWF.callCustomizationScriptFunction('ext_getReferenceObject',rob)
            data.ball1=sim.getObjectPosition(calibrationBalls[1],associatedRobotRef)
            data.ball2=sim.getObjectPosition(calibrationBalls[2],associatedRobotRef)
            data.ball3=sim.getObjectPosition(calibrationBalls[3],associatedRobotRef)
            data.matrix=sim.getObjectMatrix(calibrationBalls[1],associatedRobotRef)
        end
    end
    return data
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
        data.type=c['type']
        local dt=ext_getCalibrationDataForCurrentMode()
        data.realCalibration=dt.realCalibration
        data.ball1=dt.ball1
        data.ball2=dt.ball2
        data.ball3=dt.ball3
        local val=sim.boolAnd32(c['bitCoded'],32)>0
        if getIsPickWithoutTargetOverridden() then
            val=true
        end
        data.pickWithoutTarget=val
        data.sizes=c['sizes']
        data.offsets=c['offsets']
        data.stopLineDist=c['stopLinePos']
        data.upstreamMarginDist=-c['upstreamMarginPos']
        data.stopLine=sim.boolAnd32(c['bitCoded'],16)>0
        data.inputObjectId=simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_INPUT_REF)
        data.calibrationBallDistance=c['calibrationBallDistance']
        data.palletId=simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_PALLET_REF)
        
        simBWF.query('trackingWindow_update',data)
    end
end

function sysCall_beforeDelete(data)
    local pallet=simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_PALLET_REF)
    if pallet>=0 and data.objectHandles[pallet] then
        updateAfterObjectDeletion=true
    end
    local input=simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_INPUT_REF)
    if input>=0 and data.objectHandles[input] then
        updateAfterObjectDeletion=true
    end
end

function sysCall_afterDelete(data)
    if updateAfterObjectDeletion then
        updatePluginRepresentation()
        refreshDlg()
    end
    updateAfterObjectDeletion=nil
end

function setGreenAndBlueCalibrationBallsInPlace()
    -- Ball2 should be on the X axis of ball1's frame, and between [-0.1 and 0.5]:
    local p=sim.getObjectPosition(calibrationBalls[2],calibrationBalls[1])
    local correct=(math.abs(p[2])>0.0005) or (math.abs(p[3])>0.0005)
    if p[1]<0.09 then 
        p[1]=0.1
        correct=true
    end
    if p[1]>0.51 then 
        p[1]=0.5
        correct=true
    end
    if correct then
        sim.setObjectPosition(calibrationBalls[2],calibrationBalls[1],{p[1],0,0})
    end

    -- Ball3 should be in the X/Y plane of ball1's frame, and within +- 0.5 of the x/y origin:
    local p=sim.getObjectPosition(calibrationBalls[3],calibrationBalls[1])
    local correct=(math.abs(p[3])>0.0005)
    if p[2]>-0.1 and p[2]<0 then
        p[2]=0.11
        correct=true
    end
    if p[2]<0.1 and p[2]>=0 then
        p[2]=-0.11
        correct=true
    end
    if p[1]<-0.51 then 
        p[1]=-0.5
        correct=true
    end
    if p[1]>0.51 then 
        p[1]=0.5
        correct=true
    end
    if p[2]<-0.51 then 
        p[2]=-0.5
        correct=true
    end
    if p[2]>0.51 then 
        p[2]=0.5
        correct=true
    end
    if correct then
        sim.setObjectPosition(calibrationBalls[3],calibrationBalls[1],{p[1],p[2],0})
    end
end

function getIsPickWithoutTargetOverridden()
    local associatedRobot=getAssociatedRobotHandle()
    if associatedRobot>=0 then
        local overridden=simBWF.callCustomizationScriptFunction('ext_isPickWithoutTargetOverridden',associatedRobot,model)
        return overridden
    end
    return false
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

function getDefaultInfoForNonExistingFields(info)
    if not info['version'] then
        info['version']=_MODELVERSION_
    end
    if not info['subtype'] then
        info['subtype']='pick'
    end
    if not info['type'] then
        info['type']=0 -- 0 is pick, 1 is place
    end
    if not info['sizes'] then
        info['sizes']={0.4,0.3,0.4}
    end
    if not info['offsets'] then
        info['offsets']={-0.2,0,0}
    end
    if not info['stopLinePos'] then
        info['stopLinePos']=0.1
    end
    if not info['upstreamMarginPos'] then
        info['upstreamMarginPos']=0.1
    end
    info['palletId']=nil
--    if not info['palletId'] then
--        info['palletId']=-1 -- -1=none
--    end
    if not info['calibrationBallDistance'] then
        info['calibrationBallDistance']=1
    end
    if not info['bitCoded'] then
        info['bitCoded']=1 -- 1=hidden during sim, 2=calibration balls hidden during sim, 4=showPts, 8=create parts (online mode), 16=stopLine enable, 32=pick also without target in sight
    end
    if not info['calibration'] then
        info['calibration']=nil -- either nil, or {ball1RelPos,ball2RelPos,ball3RelPos}
    end
    if not info['calibrationMatrix'] then
        info['calibrationMatrix']=nil -- either nil, or the calibration matrix
    end
end

function readInfo()
    local data=sim.readCustomDataBlock(model,simBWF.TRACKINGWINDOW_TAG)
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
        sim.writeCustomDataBlock(model,simBWF.TRACKINGWINDOW_TAG,sim.packTable(data))
    else
        sim.writeCustomDataBlock(model,simBWF.TRACKINGWINDOW_TAG,'')
    end
end

function getAvailableInputs()
    local thisInfo=readInfo()
    local l=sim.getObjectsInTree(sim.handle_scene,sim.handle_all,0)
    local retL={}
    for i=1,#l,1 do
        if l[i]~=model then
            local data1=sim.readCustomDataBlock(l[i],simBWF.TRACKINGWINDOW_TAG)
            local data2=sim.readCustomDataBlock(l[i],simBWF.RAGNARVISION_TAG)
            local data3=sim.readCustomDataBlock(l[i],simBWF.RAGNARSENSOR_TAG)
            local data4=sim.readCustomDataBlock(l[i],simBWF.RAGNARDETECTOR_TAG)
            if data1 or data2 or data3 or data4 then
                retL[#retL+1]={simBWF.getObjectAltName(l[i]),l[i]}
            end
        end
    end
    return retL
end

function setSizes()
    local c=readInfo()
    local sl=c['stopLinePos']
    local ump=c['upstreamMarginPos']
    local w=c['sizes'][2]
    local h=c['sizes'][3]
    local offsets=c['offsets']
    local l={offsets[1]+c['sizes'][1],offsets[1]}
    local slEnabled=sim.boolAnd32(c['bitCoded'],16)>0
    if slEnabled then
        local r,lay=sim.getObjectInt32Parameter(trackBox1,sim.objintparam_visibility_layer)
        sim.setObjectInt32Parameter(stopLineBox,sim.objintparam_visibility_layer,lay)
    else
        sim.setObjectInt32Parameter(stopLineBox,sim.objintparam_visibility_layer,0)
    end
    if isPick then
        setObjectSize(trackBox1,0.1,w,h)
        sim.setObjectPosition(trackBox1,model,{l[1]-0.1*0.5,offsets[2]+w*0.5,offsets[3]+h*0.5})

        setObjectSize(trackBox2,0.1,w,h)
        sim.setObjectPosition(trackBox2,model,{l[2]+0.1*0.5,offsets[2]+w*0.5,offsets[3]+h*0.5})

        setObjectSize(stopLineBox,w+0.005,0.005,h+0.005)
        setObjectSize(upstreamMarginBox,w+0.005,0.005,h+0.005)
    else
        setObjectSize(trackBox1,0.1-0.005,w-0.005,h-0.005) -- so that we can still see when two same sized pick and place windows overlap
        sim.setObjectPosition(trackBox1,model,{l[1]-0.1*0.5,offsets[2]+w*0.5,offsets[3]+h*0.5})

        setObjectSize(trackBox2,0.1-0.005,w-0.005,h-0.005) -- so that we can still see when two same sized pick and place windows overlap
        sim.setObjectPosition(trackBox2,model,{l[2]+0.1*0.5,offsets[2]+w*0.5,offsets[3]+h*0.5})

        setObjectSize(stopLineBox,w+0.005-0.005,0.005+0.003,h+0.005-0.005)
        setObjectSize(upstreamMarginBox,w+0.005-0.005,0.005+0.003,h+0.005-0.005)
    end
    sim.setObjectPosition(stopLineBox,model,{l[2]+sl,offsets[2]+w*0.5,offsets[3]+h*0.5})
    sim.setObjectPosition(upstreamMarginBox,model,{l[2]-ump,offsets[2]+w*0.5,offsets[3]+h*0.5})
end

function updateEnabledDisabledItemsDlg()
    if ui then
        local config=readInfo()
        local stopLine=sim.boolAnd32(config['bitCoded'],16)~=0
        local simStopped=sim.getSimulationState()==sim.simulation_stopped
        simUI.setEnabled(ui,1365,simStopped,true)
        simUI.setEnabled(ui,23,simStopped,true)
        simUI.setEnabled(ui,1,simStopped,true)
        simUI.setEnabled(ui,2,simStopped,true)
        simUI.setEnabled(ui,3,simStopped,true)
        simUI.setEnabled(ui,5,simStopped,true)
        simUI.setEnabled(ui,51,stopLine,true)
        simUI.setEnabled(ui,11,simStopped,true)
        simUI.setEnabled(ui,12,simStopped,true)
        simUI.setEnabled(ui,100,simStopped,true)
        simUI.setEnabled(ui,101,simStopped,true)
        if isPick then
            simUI.setEnabled(ui,6,true and not getIsPickWithoutTargetOverridden(),true)
        end
    end
end

function refreshDlg()
    if ui then
        local config=readInfo()
        local sel=simBWF.getSelectedEditWidget(ui)
        simUI.setEditValue(ui,1365,simBWF.getObjectAltName(model),true)

        simUI.setEditValue(ui,21,simBWF.format("%.0f , %.0f , %.0f",config.sizes[1]*1000,config.sizes[2]*1000,config.sizes[3]*1000),true)
        simUI.setEditValue(ui,24,simBWF.format("%.0f , %.0f , %.0f",config.offsets[1]*1000,config.offsets[2]*1000,config.offsets[3]*1000),true)
        
        local d=config['calibrationBallDistance']
        simUI.setEditValue(ui,23,simBWF.format("%.0f",d/0.001),true)
        
        simUI.setCheckboxValue(ui,50,simBWF.getCheckboxValFromBool(sim.boolAnd32(config['bitCoded'],16)~=0),true)
        simUI.setEditValue(ui,51,simBWF.format("%.0f",config['stopLinePos']/0.001),true)
        simUI.setEditValue(ui,61,simBWF.format("%.0f",config['upstreamMarginPos']/0.001),true)
        simUI.setCheckboxValue(ui,3,simBWF.getCheckboxValFromBool(sim.boolAnd32(config['bitCoded'],1)~=0),true)
        simUI.setCheckboxValue(ui,1,simBWF.getCheckboxValFromBool(sim.boolAnd32(config['bitCoded'],2)~=0),true)
        simUI.setCheckboxValue(ui,2,simBWF.getCheckboxValFromBool(sim.boolAnd32(config['bitCoded'],8)~=0),true)
        simUI.setCheckboxValue(ui,5,simBWF.getCheckboxValFromBool(sim.boolAnd32(config['bitCoded'],4)~=0),true)
        if isPick then
            local val=sim.boolAnd32(config['bitCoded'],32)~=0
            if getIsPickWithoutTargetOverridden() then
                val=true
            end
            simUI.setCheckboxValue(ui,6,simBWF.getCheckboxValFromBool(val),true)
        end
        
        local c=readInfo()
        local loc=getAvailableInputs()
        comboInput=sim.UI_populateCombobox(ui,11,loc,{},simBWF.getObjectAltNameOrNone(simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_INPUT_REF)),true,{{simBWF.NONE_TEXT,-1}})
        
        local pallets=simBWF.getAvailablePallets()
        local refPallet=simBWF.getReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_PALLET_REF)
        local selected=simBWF.NONE_TEXT
        for i=1,#pallets,1 do
            if pallets[i][2]==refPallet then
                selected=pallets[i][1]
                break
            end
        end
        comboPallet=sim.UI_populateCombobox(ui,12,pallets,{},selected,true,{{simBWF.NONE_TEXT,-1}})
        
        updateEnabledDisabledItemsDlg()
        simBWF.setSelectedEditWidget(ui,sel)
    end
end

function hidden_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],1)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-1
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function calibrationBallsHidden_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],2)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-2
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function createParts_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],8)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-8
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function showOrHideCalibrationBalls(show)
    if show~=nil then
        if show then
            sim.setModelProperty(calibrationBalls[1],0)
        else
            sim.setModelProperty(calibrationBalls[1],sim.modelproperty_not_showasinsidemodel+sim.modelproperty_not_visible)
        end
    end
end

function showPoints_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],4)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-4
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function sizeChange_callback(ui,id,newValue)
    local c=readInfo()
    local i=1
    local t=c.sizes
    for token in (newValue..","):gmatch("([^,]*),") do
        t[i]=tonumber(token)
        if t[i]==nil then t[i]=0 end
        t[i]=t[i]*0.001
        if i==1 then
            if t[i]<0.1 then t[i]=0.1 end
            if t[i]>1 then t[i]=1 end
        end
        if i==2 then
            if t[i]<0.1 then t[i]=0.1 end
            if t[i]>1 then t[i]=1 end
        end
        if i==3 then
            if t[i]<0.1 then t[i]=0.1 end
            if t[i]>1 then t[i]=1 end
        end
        i=i+1
    end
    c.sizes=t
    writeInfo(c)
    setSizes()
    updatePluginRepresentation()
    simBWF.markUndoPoint()
    refreshDlg()
end

function offsetChange_callback(ui,id,newValue)
    local c=readInfo()
    local i=1
    local t=c.offsets
    for token in (newValue..","):gmatch("([^,]*),") do
        t[i]=tonumber(token)
        if t[i]==nil then t[i]=0 end
        t[i]=t[i]*0.001
        if i==1 then
            if t[i]<-0.5 then t[i]=-0.5 end
            if t[i]>0.5 then t[i]=0.5 end
        end
        if i==2 then
            if t[i]<-0.5 then t[i]=-0.5 end
            if t[i]>0.5 then t[i]=0.5 end
        end
        if i==3 then
            if t[i]<-0.5 then t[i]=-0.5 end
            if t[i]>0.5 then t[i]=0.5 end
        end
        i=i+1
    end
    c.offsets=t
    writeInfo(c)
    setSizes()
    updatePluginRepresentation()
    simBWF.markUndoPoint()
    refreshDlg()
end

function stopLine_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],16)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-16
    end
    writeInfo(c)
    setSizes()
    updatePluginRepresentation()
    simBWF.markUndoPoint()
    refreshDlg()
end


function stopLineChange_callback(ui,id,newVal)
    local c=readInfo()
    local v=tonumber(newVal)
    if v then
        v=v*0.001
        if v>1 then v=1 end
        if v<0.05 then v=0.05 end
        if v~=c['stopLinePos'] then
            c['stopLinePos']=v
            writeInfo(c)
            setSizes()
            updatePluginRepresentation()
            simBWF.markUndoPoint()
        end
    end
    refreshDlg()
end

function upstreamMarginChange_callback(ui,id,newVal)
    local c=readInfo()
    local v=tonumber(newVal)
    if v then
        v=v*0.001
        if v>1 then v=1 end
        if v<0 then v=0 end
        if v~=c['upstreamMarginPos'] then
            c['upstreamMarginPos']=v
            writeInfo(c)
            setSizes()
            updatePluginRepresentation()
            simBWF.markUndoPoint()
        end
    end
    refreshDlg()
end

function palletChange_callback(ui,id,newIndex)
    simBWF.setReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_PALLET_REF,comboPallet[newIndex+1][2])
    simBWF.markUndoPoint()
    updatePluginRepresentation()
    updateEnabledDisabledItemsDlg()
--    updatePalletVisualization()
end

function pickWithoutTarget_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],32)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-32
    end
    writeInfo(c)
    updatePluginRepresentation()
    simBWF.markUndoPoint()
    refreshDlg()
end

function calibrationBallDistanceChange_callback(ui,id,newVal)
    local c=readInfo()
    local v=tonumber(newVal)
    if v then
        v=v*0.001
        if v<0.05 then v=0.05 end
        if v>5 then v=5 end
        if v~=c['calibrationBallDistance'] then
            c['calibrationBallDistance']=v
            writeInfo(c)
            ext_alignCalibrationBallsWithInput()
            updatePluginRepresentation()
            simBWF.markUndoPoint()
        end
    end
    refreshDlg()
end

function inputChange_callback(ui,id,newIndex)
    local newLoc=comboInput[newIndex+1][2]
    if newLoc>=0 then
        simBWF.forbidInputForTrackingWindowChainItems(newLoc)
    end
    simBWF.setReferencedObjectHandle(model,simBWF.TRACKINGWINDOW_INPUT_REF,newLoc)
    ext_avoidCircularInput(-1)
    ext_alignCalibrationBallsWithInput()
    simBWF.markUndoPoint()
    updatePluginRepresentation()
    refreshDlg()
end

function onCalibrationUiClose()
    local data={}
    data.idRobot=getAssociatedRobotHandle()
    data.id=model
    simBWF.query('trackingWindow_trainEnd',data)
    simUI.destroy(calibrationData.ui)
    calibrationData=nil
    sim.msgBox(sim.msgbox_type_info,sim.msgbox_buttons_ok,"Calibration","Calibration procedure aborted")
end

function calibrationBallClick_callback(ui,id,newVal)
    local toleranceTesting=0.1
    local weHaveAProblem=false
    local associatedRobot=getAssociatedRobotHandle()
    local associatedRobotRef=simBWF.callCustomizationScriptFunction('ext_getReferenceObject',associatedRobot)
    if #calibrationData.relativeBallPositions==0 then
        -- just clicked red.
        simUI.setEnabled(calibrationData.ui,2,false)
        simUI.setEnabled(calibrationData.ui,3,true)
        simUI.setLabelText(calibrationData.ui,1,"Move the gripper platform to the green ball, then click 'Green' below")

        local data={}
        data.idRobot=getAssociatedRobotHandle()
        data.id=model
        data.ballIndex=0
        local reply,replyData=simBWF.query('trackingWindow_train',data)
        if simBWF.isInTestMode() then
            reply='ok'
            local dat=sim.getObjectPosition(calibrationBalls[1],associatedRobotRef)
            replyData.pos={dat[1]-toleranceTesting*math.random()*toleranceTesting*2,dat[2]-toleranceTesting*math.random()*toleranceTesting*2,dat[3]-toleranceTesting*math.random()*toleranceTesting*2}
            replyData.ballIndex=data.ballIndex
        end
        if reply=='ok' then
            if replyData.ballIndex==data.ballIndex then
                calibrationData.relativeBallPositions[1]=replyData.pos        
            else
                weHaveAProblem="Strange reply from the plugin"
            end
        else
            if reply then
                weHaveAProblem=reply.error
            else
                weHaveAProblem="Problem with the plugin"
            end
        end
    else
        if #calibrationData.relativeBallPositions==1 then
            -- just clicked green.
            simUI.setEnabled(calibrationData.ui,3,false)
            simUI.setEnabled(calibrationData.ui,4,true)
            simUI.setLabelText(calibrationData.ui,1,"Move the gripper platform to the blue ball, then click 'Blue' below")
 
            local data={}
            data.idRobot=getAssociatedRobotHandle()
            data.id=model
            data.ballIndex=1
            local reply,replyData=simBWF.query('trackingWindow_train',data)
            if simBWF.isInTestMode() then
                reply='ok'
                local dat=sim.getObjectPosition(calibrationBalls[2],associatedRobotRef)
                replyData.pos={dat[1]-toleranceTesting*math.random()*toleranceTesting*2,dat[2]-toleranceTesting*math.random()*toleranceTesting*2,dat[3]-toleranceTesting*math.random()*toleranceTesting*2}
                replyData.ballIndex=data.ballIndex
            end
            if reply=='ok' then
                if replyData.ballIndex==data.ballIndex then
                    calibrationData.relativeBallPositions[2]=replyData.pos        
                    local d=simBWF.getPtPtDistance(calibrationData.relativeBallPositions[1],calibrationData.relativeBallPositions[2])
                    if d<0.08 then
                        weHaveAProblem='The green ball is too close to the red ball.' 
                    end
                else
                    weHaveAProblem="Strange reply from the plugin"
                end
            else
                if reply then
                    weHaveAProblem=reply.error
                else
                    weHaveAProblem="Problem with the plugin"
                end
            end
        else
            -- just clicked blue.
            local data={}
            data.idRobot=associatedRobot
            data.id=model
            data.ballIndex=2
            local reply,replyData=simBWF.query('trackingWindow_train',data)
            if simBWF.isInTestMode() then
                reply='ok'
                local dat=sim.getObjectPosition(calibrationBalls[3],associatedRobotRef)
                replyData.pos={dat[1]-toleranceTesting*math.random()*toleranceTesting*2,dat[2]-toleranceTesting*math.random()*toleranceTesting*2,dat[3]-toleranceTesting*math.random()*toleranceTesting*2}
                replyData.ballIndex=data.ballIndex
            end
            if reply=='ok' then
                if replyData.ballIndex==data.ballIndex then
                    calibrationData.relativeBallPositions[3]=replyData.pos
                    local d1=simBWF.getPtPtDistance(calibrationData.relativeBallPositions[1],calibrationData.relativeBallPositions[3])
                    local d2=simBWF.getPtPtDistance(calibrationData.relativeBallPositions[2],calibrationData.relativeBallPositions[3])
                    if d1<0.08 or d2<0.08 then
                        weHaveAProblem='The blue ball is too close to the red or green ball.'
                    else
                        local c=readInfo()
                        local calData=calibrationData.relativeBallPositions
                        c['calibration']=calData
                        -- Find the matrix:
                        local m=simBWF.getMatrixFromCalibrationBallPositions(calData[1],calData[2],calData[3])
                        c['calibrationMatrix']=m
                        writeInfo(c)
                        simUI.destroy(calibrationData.ui)
                        calibrationData=nil
                        applyCalibrationColor()
                        local data={}
                        data.idRobot=getAssociatedRobotHandle()
                        data.id=model
                        simBWF.query('trackingWindow_trainEnd',data)
                        updatePluginRepresentation()
                    end
                else
                    weHaveAProblem="Strange reply from the plugin"
                end
            else
                if reply then
                    weHaveAProblem=reply.error
                else
                    weHaveAProblem="Problem with the plugin"
                end
            end
        end
    end
    if weHaveAProblem then
        local data={}
        data.idRobot=getAssociatedRobotHandle()
        data.id=model
        simBWF.query('trackingWindow_trainEnd',data)
        sim.msgBox(sim.msgbox_type_warning,sim.msgbox_buttons_ok,"Calibration",weHaveAProblem)
        simUI.destroy(calibrationData.ui)
        calibrationData=nil
    end
end

function clearCalibrationDataClick_callback()
    ext_clearCalibration()
end

function trainCalibrationBallsClick_callback()
    if getAssociatedRobotHandle()==-1 then
        sim.msgBox(sim.msgbox_type_info,sim.msgbox_buttons_ok,'Calibration','The tracking window is not associated with any robot.')
    else
        local data={}
        data.idRobot=getAssociatedRobotHandle()
        data.id=model
        local reply=simBWF.query('trackingWindow_trainStart',data)
        if reply=='ok' or simBWF.isInTestMode() then
            local xml =[[
                <group layout="hbox" flat="true">
                     <label text="Move the gripper platform to the red ball, then click 'Red' below" id="1"/>
                </group>
                <group layout="hbox" flat="true">
                    <button text="Red"  style="* {min-width: 150px; background-color: #ff8888}" on-click="calibrationBallClick_callback" id="2" />
                    <button text="Green"  style="* {min-width: 150px; background-color: #88ff88}" enabled="false" on-click="calibrationBallClick_callback" id="3" />
                    <button text="Blue"  style="* {min-width: 150px; background-color: #8888ff}" enabled="false" on-click="calibrationBallClick_callback" id="4" />
                </group>
            ]]
            calibrationData={}
            calibrationData.ui=simBWF.createCustomUi(xml,"Calibration","center",true,"onCalibrationUiClose",true,false,true)
            calibrationData.relativeBallPositions={}
        end
    end
end

function getAssociatedRobotHandle()
    local ragnars=sim.getObjectsWithTag(simBWF.RAGNAR_TAG,true)
    for i=1,#ragnars,1 do
        if simBWF.callCustomizationScriptFunction('ext_checkIfRobotIsAssociatedWithLocationFrameOrTrackingWindow',ragnars[i],model) then
            return ragnars[i]
        end
    end
    return -1
end

function nameChange(ui,id,newVal)
    if simBWF.setObjectAltName(model,newVal)>0 then
        simBWF.markUndoPoint()
        updatePluginRepresentation()
        simUI.setTitle(ui,simBWF.getUiTitleNameFromModel(model,_MODELVERSION_,_CODEVERSION_))
    end
    refreshDlg()
end

function createDlg()
    if (not ui) and simBWF.canOpenPropertyDialog() then
        local xml =[[
        <tabs id="77">
            <tab title="General">
                <group layout="form" flat="false">
                
                <label text="Name"/>
                <edit on-editing-finished="nameChange" id="1365"/>

                <label text="Offset (X, Y, Z, in mm)"/>
                <edit on-editing-finished="offsetChange_callback" id="24"/>

                <label text="Size (X, Y, Z, in mm)"/>
                <edit on-editing-finished="sizeChange_callback" id="21"/>

                <label text="Upstream margin (mm)"/>
                <edit on-editing-finished="upstreamMarginChange_callback" id="61"/>
                
                <checkbox text="Stop line (mm)" on-change="stopLine_callback" id="50" />
                <edit on-editing-finished="stopLineChange_callback" id="51"/>

                <label text="Associated pallet"/>
                <combobox id="12" on-change="palletChange_callback"/>

                <label text="Input"/>
                <combobox id="11" on-change="inputChange_callback">
                </combobox>

                <label text="Calibration ball distance (mm)"/>
                <edit on-editing-finished="calibrationBallDistanceChange_callback" id="23"/>]]
        if isPick then
            xml=xml..[[
                <label text="Pick also without target" />
                <checkbox text="" on-change="pickWithoutTarget_callback" id="6" />]]
        end
        xml=xml..[[
            </group>
            </tab>
            <tab title="Online">
                <button text="Train calibration balls"  style="* {min-width: 300px;}" on-click="trainCalibrationBallsClick_callback" id="100" />
                <button text="Clear calibration data"  style="* {min-width: 300px;}" on-click="clearCalibrationDataClick_callback" id="101" />
            </tab>
            <tab title="More">
            <group layout="form" flat="false">
                
                <label text="Hidden during simulation" />
                <checkbox text="" on-change="hidden_callback" id="3" />

                 <label text="Calibration balls hidden during simulation" />
                <checkbox text="" on-change="calibrationBallsHidden_callback" id="1" />
                

                <label text="Visualize tracked items"/>
                <checkbox text="" on-change="showPoints_callback" id="5" />

                <label text="Create parts (online mode)"/>
                <checkbox text="" on-change="createParts_callback" id="2" />
                
                <label text="" style="* {margin-left: 175px;}"/>
                <label text="" style="* {margin-left: 175px;}"/>
            </group>
            </tab>
       </tabs>
        ]]
        --[[
                 <label text="Calibration balls always hidden" />
                <checkbox text="" on-change="calibrationBallsAlwaysHidden_callback" id="2" />
--]]
        ui=simBWF.createCustomUi(xml,simBWF.getUiTitleNameFromModel(model,_MODELVERSION_,_CODEVERSION_),previousDlgPos,false,nil,false,false,false)

        
        refreshDlg()
        simUI.setCurrentTab(ui,77,dlgMainTabIndex,true)
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
        dlgMainTabIndex=simUI.getCurrentTab(ui,77)
        simUI.destroy(ui)
        ui=nil
    end
end

function sysCall_init()
    dlgMainTabIndex=0
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    _MODELVERSION_=1
    _CODEVERSION_=1
    local _info=readInfo()
    simBWF.checkIfCodeAndModelMatch(model,_CODEVERSION_,_info['version'])
    writeInfo(_info)
    isPick=(_info['type']==0)
    if isPick then
        trackBox1=sim.getObjectHandle('pickTrackingWindow_box1')
        trackBox2=sim.getObjectHandle('pickTrackingWindow_box2')
        stopLineBox=sim.getObjectHandle('pickTrackingWindow_stopLine')
        refFrame=sim.getObjectHandle('pickTrackingWindow_refFrame')
        upstreamMarginBox=sim.getObjectHandle('pickTrackingWindow_upstreamMargin')
    else
        trackBox1=sim.getObjectHandle('placeTrackingWindow_box1')
        trackBox2=sim.getObjectHandle('placeTrackingWindow_box2')
        stopLineBox=sim.getObjectHandle('placeTrackingWindow_stopLine')
        refFrame=sim.getObjectHandle('placeTrackingWindow_refFrame')
        upstreamMarginBox=sim.getObjectHandle('placeTrackingWindow_upstreamMargin')
    end
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    calibrationBalls={}
    for i=1,3,1 do
        if isPick then
            calibrationBalls[i]=sim.getObjectHandle('pickTrackingWindow_calibrationBall'..i)
        else
            calibrationBalls[i]=sim.getObjectHandle('placeTrackingWindow_calibrationBall'..i)
        end
    end
    updatePluginRepresentation()
    previousDlgPos=simBWF.readSessionPersistentObjectData(model,"dlgPosAndSize")
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
    -- (we do not modify the pose of the red calibration ball!!)
    local associatedRobot=getAssociatedRobotHandle()
    local c=readInfo()
    local calData=c['calibration']
    if associatedRobot>=0 then
        local associatedRobotRef=simBWF.callCustomizationScriptFunction('ext_getReferenceObject',associatedRobot)
        if calData then
            -- now set the location frame green and blue balls in place:
            local mi=c['calibrationMatrix']
            sim.invertMatrix(mi)
            sim.setObjectPosition(calibrationBalls[2],model,sim.multiplyVector(mi,calData[2]))
            sim.setObjectPosition(calibrationBalls[3],model,sim.multiplyVector(mi,calData[3]))
        end
    else
        if calData then
            c['calibration']=nil
            c['calibrationMatrix']=nil
            writeInfo(c)
        end
    end
end

function applyCalibrationColor()
    -- (we do not modify the pose of the red calibration ball!!)
    local associatedRobot=getAssociatedRobotHandle()
    local c=readInfo()
    local calData=c['calibration']
    local col
    if isPick then
        col={0.5,1,0.5}
    else
        col={1,0.5,0.5}
    end
    if associatedRobot>=0 then
        if calData then
            col={1,1,0}
        end
    end
    local obj=sim.getObjectsInTree(calibrationBalls[1],sim.object_shape_type,1)
    for i=1,#obj,1 do
        sim.setShapeColor(obj[i],'CALAUX',sim.colorcomponent_ambient_diffuse,col)
    end
end

function sysCall_nonSimulation()
    showOrHideUiIfNeeded()
    local c=readInfo()
    local hideBalls=false
    if sim.getSimulationState()~=sim.simulation_stopped then
        hideBalls=simBWF.modifyAuxVisualizationItems(sim.boolAnd32(c['bitCoded'],2)~=0)
    end
    showOrHideCalibrationBalls(not hideBalls)
    ext_alignCalibrationBallsWithInput()
    setGreenAndBlueCalibrationBallsInPlace()
end

function sysCall_sensing()
    if simJustStarted then
        if simBWF.isSystemOnline() then
            applyCalibrationData() -- can potentially change the position/orientation of the robot
        end
        updateEnabledDisabledItemsDlg()
    end
    simJustStarted=nil
    showOrHideUiIfNeeded()
    ext_outputPluginRuntimeMessages()
end

function sysCall_suspended()
    showOrHideUiIfNeeded()
end

function sysCall_afterSimulation()
    sim.setObjectInt32Parameter(trackBox1,sim.objintparam_visibility_layer,1)
    sim.setObjectInt32Parameter(trackBox2,sim.objintparam_visibility_layer,1)
    sim.setObjectInt32Parameter(refFrame,sim.objintparam_visibility_layer,1)
    sim.setObjectInt32Parameter(upstreamMarginBox,sim.objintparam_visibility_layer,1)
    local c=readInfo()
    local showStopLine=simBWF.modifyAuxVisualizationItems(sim.boolAnd32(c['bitCoded'],16)~=0)
    if showStopLine then
        sim.setObjectInt32Parameter(stopLineBox,sim.objintparam_visibility_layer,1)
    end
    showOrHideUiIfNeeded()
    updateEnabledDisabledItemsDlg()
end

function sysCall_beforeSimulation()
    simJustStarted=true
    ext_outputBrSetupMessages()
    ext_outputPluginSetupMessages()
    local c=readInfo()
    local show=simBWF.modifyAuxVisualizationItems(sim.boolAnd32(c['bitCoded'],1)==0)
    if not show then
        sim.setObjectInt32Parameter(trackBox1,sim.objintparam_visibility_layer,256)
        sim.setObjectInt32Parameter(trackBox2,sim.objintparam_visibility_layer,256)
        sim.setObjectInt32Parameter(refFrame,sim.objintparam_visibility_layer,256)
        sim.setObjectInt32Parameter(stopLineBox,sim.objintparam_visibility_layer,256)
        sim.setObjectInt32Parameter(upstreamMarginBox,sim.objintparam_visibility_layer,256)
    end
    local hideBalls=false
    hideBalls=simBWF.modifyAuxVisualizationItems(sim.boolAnd32(c['bitCoded'],2)~=0)
    showOrHideCalibrationBalls(not hideBalls)
--    ext_alignCalibrationBallsWithInput()
--    setGreenAndBlueCalibrationBallsInPlace()
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
    simBWF.writeSessionPersistentObjectData(model,"dlgPosAndSize",previousDlgPos)
end

