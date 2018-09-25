function ext_getItemData_pricing()
    local obj={}
    obj.name=simBWF.getObjectAltName(model)
    obj.type='ragnarDetector'
    obj.brVersion=1
    local dep={}
    local id=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_CONVEYOR_REF)
    if id>=0 then
        dep[#dep+1]=id
    end
    local id=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_INPUT_REF)
    if id>=0 then
        dep[#dep+1]=id
    end
    if #dep>0 then
        obj.dependencies=dep
    end
    return obj
end

function ext_avoidCircularInput(inputItem)
    -- We have: ragnarDetector --> item1 --> item2 ... --> itemN
    -- None of the above item's input should be 'inputItem'
    -- If 'inputItem' is -1, then none of the above item's input should be 'model'
    -- A. Check this ragnarDetector:
    if inputItem>0 then
        local h=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_INPUT_REF)
        if h==inputItem then
            simBWF.setReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_INPUT_REF,-1) -- this input closed the loop. We open it here.
            updatePluginRepresentation()
        end
    end
    
    if inputItem==-1 then
        inputItem=model
    end

    -- B. Check connected items:
    local h=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_INPUT_REF)
    if h>=0 then
        simBWF.callCustomizationScriptFunction("ext_avoidCircularInput",h,inputItem)
    end
end

function ext_forbidInput(inputItem)
    local h=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_INPUT_REF)
    if h==inputItem then
        simBWF.setReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_INPUT_REF,-1)
        updatePluginRepresentation()
    end
end

function ext_getInputObjectHande()
    return simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_INPUT_REF)
end

function sysCall_beforeDelete(data)
    local conveyor=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_CONVEYOR_REF)
    if conveyor>=0 and data.objectHandles[conveyor] then
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

function ext_getAssociatedConveyorHandle()
    return simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_CONVEYOR_REF)
end

function ext_alignCalibrationBallsWithInput()
    local conveyorHandle=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_CONVEYOR_REF)
    if conveyorHandle>=0 then
        -- Make the calibration balls visible:
    --    sim.setModelProperty(calibrationBalls[1],0)

        -- Work with thresholds here, otherwise the scene modifies itself continuously little by little:
        local c=readInfo()
        local flipped=sim.boolAnd32(c.bitCoded,2)>0
        local p=sim.getObjectOrientation(calibrationBalls[1],conveyorHandle)
        if flipped then
            local correct=(math.abs(p[1])>0.1*math.pi/180) or (math.abs(p[2])>0.1*math.pi/180)
            if (math.abs(p[3]-math.pi)>0.1*math.pi/180) and (math.abs(p[3]+math.pi)>0.1*math.pi/180) then
                correct=true
            end
            if correct then
                sim.setObjectOrientation(calibrationBalls[1],conveyorHandle,{0,0,math.pi})
            end
        else
            local correct=(math.abs(p[1])>0.1*math.pi/180) or (math.abs(p[2])>0.1*math.pi/180) or (math.abs(p[3])>0.1*math.pi/180)
            if correct then
                sim.setObjectOrientation(calibrationBalls[1],conveyorHandle,{0,0,0})
            end
        end
    else
        local h=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_INPUT_REF)
        
        -- First align the ragnar vision with its input item:
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
    
    setDetectorBoxSizeAndPos()
end

function ext_outputBrSetupMessages()
    local nm=' ['..simBWF.getObjectAltName(model)..']'
    local msg=""
    if simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_CONVEYOR_REF)<0 and simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_INPUT_REF)<0 then
        msg="WARNING (set-up): Not associated with any conveyor belt, and has no input"..nm
    else
        local h=simBWF.getModelThatUsesThisModelAsInput(model)
        if h==-1 then
            msg="WARNING (set-up): Not used as input (e.g. by a tracking window)"..nm
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
        data.conveyorId=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_CONVEYOR_REF)
        data.inputObjectId=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_INPUT_REF)
        data.calibrationBallDistance=c.calibrationBallDistance
        simBWF.query('ragnarDetector_update',data)
    end
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

function getAvailableInputs()
    local thisInfo=readInfo()
    local l=sim.getObjectsInTree(sim.handle_scene,sim.handle_all,0)
    local retL={}
    for i=1,#l,1 do
        if l[i]~=model then
            local data1=sim.readCustomDataBlock(l[i],simBWF.RAGNARDETECTOR_TAG)
            local data2=sim.readCustomDataBlock(l[i],simBWF.RAGNARVISION_TAG)
            local data3=sim.readCustomDataBlock(l[i],simBWF.RAGNARSENSOR_TAG)
            if data1 or data2 or data3 then
                retL[#retL+1]={simBWF.getObjectAltName(l[i]),l[i]}
            end
        end
    end
    return retL
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

function getDefaultInfoForNonExistingFields(info)
    if not info['version'] then
        info['version']=_MODELVERSION_
    end
    if not info['subtype'] then
        info['subtype']='window'
    end
    if not info['bitCoded'] then
        info['bitCoded']=1 -- 1=hide detector box during simulation, 2=flipped 180 in rel. to conveyor frame, 4=show detections
    end
    if not info['detectorDiameter'] then
        info['detectorDiameter']=0.001
    end
    if not info['detectorHeight'] then
        info['detectorHeight']=0.3
    end
    if not info['detectorHeightOffset'] then
        info['detectorHeightOffset']=-0.025
    end
    if not info['calibrationBallDistance'] then
        info['calibrationBallDistance']=1
    end
end

function readInfo()
    local data=sim.readCustomDataBlock(model,simBWF.RAGNARDETECTOR_TAG)
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
        sim.writeCustomDataBlock(model,simBWF.RAGNARDETECTOR_TAG,sim.packTable(data))
    else
        sim.writeCustomDataBlock(model,simBWF.RAGNARDETECTOR_TAG,'')
    end
end

function setDetectorBoxSizeAndPos()
    local c=readInfo()
    local relGreenBallPos=sim.getObjectPosition(calibrationBalls[2],calibrationBalls[1])
    local relBlueBallPos=sim.getObjectPosition(calibrationBalls[3],calibrationBalls[1])
    local s={relGreenBallPos[1],math.abs(relBlueBallPos[2]),c.detectorHeight}
    
    local p={s[1]*0.5,relBlueBallPos[2]*0.5,s[3]*0.5+c.detectorHeightOffset}
    -- Do the change only if something will be different:
    local correctIt=false
    local ds=getObjectSize(detectorBox)
    local pp=sim.getObjectPosition(detectorBox,calibrationBalls[1])
    for i=1,3,1 do
        if math.abs(ds[i]-s[i])>0.001 or math.abs(pp[i]-p[i])>0.001 then
            correctIt=true
            break
        end
    end
    local ss=getObjectSize(detectorSensor)
    if math.abs(ss[3]-s[3])>0.001 then
        correctIt=true
    end
    if correctIt then
        setObjectSize(detectorBox,s[1],s[2],s[3])
        setObjectSize(detectorSensor,ss[1],ss[2],s[3])
        sim.setObjectPosition(detectorBox,calibrationBalls[1],p)
        sim.setObjectPosition(detectorSensor,calibrationBalls[1],{p[1],p[2],s[3]+c.detectorHeightOffset})
    end
end

function refreshDlg()
    if ui then
        local config=readInfo()
        local sel=simBWF.getSelectedEditWidget(ui)
        
        local loc=getAvailableConveyors()
        comboConveyor=sim.UI_populateCombobox(ui,11,loc,{},simBWF.getObjectAltNameOrNone(simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_CONVEYOR_REF)),true,{{simBWF.NONE_TEXT,-1}})

        local d=config['calibrationBallDistance']
        simUI.setEditValue(ui,233,simBWF.format("%.0f",d/0.001),true)
        
        local loc=getAvailableInputs()
        comboInput=sim.UI_populateCombobox(ui,232,loc,{},simBWF.getObjectAltNameOrNone(simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_INPUT_REF)),true,{{simBWF.NONE_TEXT,-1}})

        simUI.setCheckboxValue(ui,28,simBWF.getCheckboxValFromBool(sim.boolAnd32(config.bitCoded,4)>0))
        simUI.setCheckboxValue(ui,24,simBWF.getCheckboxValFromBool(sim.boolAnd32(config.bitCoded,2)>0))
        simUI.setCheckboxValue(ui,23,simBWF.getCheckboxValFromBool(sim.boolAnd32(config.bitCoded,1)>0))
        simUI.setEditValue(ui,25,simBWF.format("%.0f",config.detectorDiameter/0.001),true)
        simUI.setEditValue(ui,27,simBWF.format("%.0f",config.detectorHeight/0.001),true)
        simUI.setEditValue(ui,26,simBWF.format("%.0f",config.detectorHeightOffset/0.001),true)

        simUI.setEditValue(ui,1365,simBWF.getObjectAltName(model),true)
        simBWF.setSelectedEditWidget(ui,sel)
        updateEnabledDisabledItemsDlg()
    end
end

function updateEnabledDisabledItemsDlg()
    if ui then
        local c=readInfo()
        local simStopped=sim.getSimulationState()==sim.simulation_stopped
        simUI.setEnabled(ui,1365,simStopped,true)
        simUI.setEnabled(ui,11,simStopped,true)
        simUI.setEnabled(ui,24,simStopped and simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_CONVEYOR_REF)>=0,true)
        simUI.setEnabled(ui,23,simStopped,true)
        simUI.setEnabled(ui,25,simStopped,true)
        simUI.setEnabled(ui,27,simStopped,true)
        simUI.setEnabled(ui,26,simStopped,true)
        simUI.setEnabled(ui,28,simStopped,true)
        simUI.setEnabled(ui,232,simStopped,true)
        simUI.setEnabled(ui,233,simStopped and simBWF.getReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_INPUT_REF)>=0,true)

        local notOnline=not simBWF.isSystemOnline()
    end
end


function conveyorChange_callback(ui,id,newIndex)
    local newLoc=comboConveyor[newIndex+1][2]
    simBWF.setReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_INPUT_REF,-1)
    simBWF.setReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_CONVEYOR_REF,newLoc)
    sim.setObjectParent(model,newLoc,true) -- attach/detach the detector to/from the conveyor
    simBWF.markUndoPoint()
    updatePluginRepresentation()
    refreshDlg()
end

function sensorDiameterChange(ui,id,newValue)
    local c=readInfo()
    newValue=tonumber(newValue)
    if newValue then
        newValue=newValue/1000
        if newValue<0.001 then newValue=0.001 end
        if newValue>0.2 then newValue=0.2 end
        if c.detectorDiameter~=newValue then
            c.detectorDiameter=newValue
            writeInfo(c)
            local s=getObjectSize(detectorSensor)
            setObjectSize(detectorSensor,newValue,newValue,s[3])
            simBWF.markUndoPoint()
        end
    end
    refreshDlg()
end

function detectorHeightOffsetChange(ui,id,newValue)
    local c=readInfo()
    newValue=tonumber(newValue)
    if newValue then
        newValue=newValue/1000
        if newValue<-0.2 then newValue=-0.2 end
        if newValue>0.2 then newValue=0.2 end
        if c.detectorHeightOffset~=newValue then
            c.detectorHeightOffset=newValue
            writeInfo(c)
            setDetectorBoxSizeAndPos()
            simBWF.markUndoPoint()
        end
    end
    refreshDlg()
end

function detectorHeightChange(ui,id,newValue)
    local c=readInfo()
    newValue=tonumber(newValue)
    if newValue then
        newValue=newValue/1000
        if newValue<0.05 then newValue=0.05 end
        if newValue>0.8 then newValue=0.8 end
        if c.detectorHeight~=newValue then
            c.detectorHeight=newValue
            writeInfo(c)
            setDetectorBoxSizeAndPos()
            simBWF.markUndoPoint()
        end
    end
    refreshDlg()
end

function hideDetectorBoxClick_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],1)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-1
    end
    writeInfo(c)
    simBWF.markUndoPoint()
    refreshDlg()
end

function flipped180Click_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],2)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-2
    end
    writeInfo(c)
    ext_alignCalibrationBallsWithInput()
    simBWF.markUndoPoint()
    refreshDlg()
end

function showDetectionsClick_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],4)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-4
    end
    writeInfo(c)
    simBWF.markUndoPoint()
    refreshDlg()
end

function nameChange(ui,id,newVal)
    if simBWF.setObjectAltName(model,newVal)>0 then
        simBWF.markUndoPoint()
        updatePluginRepresentation()
        simUI.setTitle(ui,simBWF.getUiTitleNameFromModel(model,_MODELVERSION_,_CODEVERSION_))
    end
    refreshDlg()
end

function inputChange_callback(ui,id,newIndex)
    local newLoc=comboInput[newIndex+1][2]
    if newLoc>=0 then
        simBWF.forbidInputForTrackingWindowChainItems(newLoc)
    end
    simBWF.setReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_INPUT_REF,newLoc)
    simBWF.setReferencedObjectHandle(model,simBWF.RAGNARDETECTOR_CONVEYOR_REF,-1) -- no conveyor in that case
    sim.setObjectParent(model,-1,true) -- detach the vision system from the conveyor
    ext_avoidCircularInput(-1)
    ext_alignCalibrationBallsWithInput()
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

function createDlg()
    if (not ui) and simBWF.canOpenPropertyDialog() then
        local xml =[[
        <tabs id="77">
            <tab title="General">
            <group layout="form" flat="false">

                <label text="Name"/>
                <edit on-editing-finished="nameChange" id="1365"/>

                <label text="Conveyor belt"/>
                <combobox id="11" on-change="conveyorChange_callback"/>

                <label text="Flipped 180 deg. w.r. to conveyor" style="* {margin-left: 20px;}"/>
                <checkbox text="" checked="false" on-change="flipped180Click_callback" id="24"/>
                
                <label text="Input"/>
                <combobox id="232" on-change="inputChange_callback">
                </combobox>

                <label text="Calibration ball distance (mm)" style="* {margin-left: 20px;}"/>
                <edit on-editing-finished="calibrationBallDistanceChange_callback" id="233"/>
            </group>
            </tab>

            <tab title="More">
            <group layout="form" flat="false">
                <label text="Hide when running"/>
                <checkbox text="" checked="false" on-change="hideDetectorBoxClick_callback" id="23"/>
                
                <label text="Show detections in scene"/>
                <checkbox text="" checked="false" on-change="showDetectionsClick_callback" id="28"/>
                
                <label text="Detection diameter (mm)"/>
                <edit on-editing-finished="sensorDiameterChange" id="25"/>
                
                <label text="Detection Z-axis size (mm)"/>
                <edit on-editing-finished="detectorHeightChange" id="27"/>
                
                <label text="Detection Z-axis offset (mm)"/>
                <edit on-editing-finished="detectorHeightOffsetChange" id="26"/>
            </group>
            </tab>
       </tabs>
        ]]
        ui=simBWF.createCustomUi(xml,simBWF.getUiTitleNameFromModel(model,_MODELVERSION_,_CODEVERSION_),previousDlgPos)        
       
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
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    calibrationBalls={model}
    for i=2,3,1 do
        calibrationBalls[i]=sim.getObjectHandle('RagnarDetector_calibrationBall'..i)
    end
    detectorBox=sim.getObjectHandle('RagnarDetector_detectorBox')
    detectorSensor=sim.getObjectHandle('RagnarDetector_detectorSensor')
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

function sysCall_nonSimulation()
    showOrHideUiIfNeeded()
    ext_alignCalibrationBallsWithInput()
    setGreenAndBlueCalibrationBallsInPlace()
end

function sysCall_sensing()
    if simJustStarted then
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
    updateEnabledDisabledItemsDlg()
    local c=readInfo()
    if sim.boolAnd32(c.bitCoded,1)>0 then
        sim.setObjectInt32Parameter(detectorBox,sim.objintparam_visibility_layer,1)
    end
end

function sysCall_beforeSimulation()
    simJustStarted=true
    ext_outputBrSetupMessages()
    ext_outputPluginSetupMessages()
    local c=readInfo()
    if sim.boolAnd32(c.bitCoded,1)>0 then
        sim.setObjectInt32Parameter(detectorBox,sim.objintparam_visibility_layer,0)
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
    simBWF.writeSessionPersistentObjectData(model,"dlgPosAndSize",previousDlgPos)
end

