function ext_getItemData_pricing()
    local obj={}
    obj.name=simBWF.getObjectAltName(model)
    obj.type='ragnarSensor'
    obj.visionType='default'
    obj.brVersion=1
    local dep={}
    local id=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_CONVEYOR_REF)
    if id>=0 then
        dep[#dep+1]=id
    end
    local id=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_INPUT_REF)
    if id>=0 then
        dep[#dep+1]=id
    end
    if #dep>0 then
        obj.dependencies=dep
    end
    return obj
end

function sysCall_beforeDelete(data)
    local conveyor=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_CONVEYOR_REF)
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
    return simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_CONVEYOR_REF)
end

function ext_alignCalibrationBallsWithInput()
    local conveyorHandle=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_CONVEYOR_REF)
    if conveyorHandle>=0 then
        -- Work with thresholds here, otherwise the scene modifies itself continuously little by little:
        local c=readInfo()
        local flipped=sim.boolAnd32(c.bitCoded,2)>0
        local p=sim.getObjectOrientation(model,conveyorHandle)
        if flipped then
            local correct=(math.abs(p[1])>0.1*math.pi/180) or (math.abs(p[2])>0.1*math.pi/180)
            if (math.abs(p[3]-math.pi)>0.1*math.pi/180) and (math.abs(p[3]+math.pi)>0.1*math.pi/180) then
                correct=true
            end
            if correct then
                sim.setObjectOrientation(model,conveyorHandle,{0,0,math.pi})
            end
        else
            local correct=(math.abs(p[1])>0.1*math.pi/180) or (math.abs(p[2])>0.1*math.pi/180) or (math.abs(p[3])>0.1*math.pi/180)
            if correct then
                sim.setObjectOrientation(model,conveyorHandle,{0,0,0})
            end
        end
    else
        local h=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_INPUT_REF)
        
        -- First align the ragnar sensor with its input item:
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
        data.conveyorId=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_CONVEYOR_REF)
        data.inputObjectId=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_INPUT_REF)
        data.calibrationBallDistance=c.calibrationBallDistance
        data.deviceId=''
        if c.deviceId~=simBWF.NONE_TEXT then
            data.deviceId=c.deviceId
        end
        if sim.getBoolParameter(sim.boolparam_online_mode) then
            data.detectionOffset=c.detectionOffset[2]
        else
            data.detectionOffset=c.detectionOffset[1]
        end

        simBWF.query('ragnarSensor_update',data)
    end
end

function getDefaultInfoForNonExistingFields(info)
    if not info.version then
        info.version=_MODELVERSION_
    end
    if not info.subtype then
        info.subtype='sensor'
    end
    if not info.bitCoded then
        info.bitCoded=0 -- 2=flipped 180 in rel. to conveyor frame
    end

    info.measurementLength=nil
--    if not info.measurementLength then
--        info.measurementLength=0.2
--    end

    if not info.detectionOffset then
        info.detectionOffset={{0,0.1,0},{0,0.1,0}} -- first is simulation, next is online
    end
    if not info.showPlot then
        info.showPlot={false,false} -- first is simulation, next is online
    end
    if not info.plotUpdateFrequ then
        info.plotUpdateFrequ={0,0} -- simulation and real parameters. 0=always, 1=medium (every 200ms), 2=rare (every 1s)
    end
    if not info.deviceId then
        info.deviceId=simBWF.NONE_TEXT
    end
    if not info.calibrationBallDistance then
        info.calibrationBallDistance=1
    end
end

function readInfo()
    local data=sim.readCustomDataBlock(model,simBWF.RAGNARSENSOR_TAG)
    if data then
        data=sim.unpackTable(data)
    else
        data={}
    end
    getDefaultInfoForNonExistingFields(data)
    --sim.writeCustomDataBlock(model,simBWF.CALIBRATIONBALL1_TAG,sim.packTable({}))
    return data
end

function writeInfo(data)
    if data then
        sim.writeCustomDataBlock(model,simBWF.RAGNARSENSOR_TAG,sim.packTable(data))
    else
        sim.writeCustomDataBlock(model,simBWF.RAGNARSENSOR_TAG,'')
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

function refreshDlg()
    if ui then
        local config=readInfo()
        local sel=simBWF.getSelectedEditWidget(ui)

        local loc=getAvailableConveyors()
        comboConveyor=sim.UI_populateCombobox(ui,3,loc,{},simBWF.getObjectAltNameOrNone(simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_CONVEYOR_REF)),true,{{simBWF.NONE_TEXT,-1}})
        
        local updateFrequComboItems={
            {"every 50 ms",0},
            {"every 200 ms",1},
            {"every 1000 ms",2}
        }
        sim.UI_populateCombobox(ui,103,updateFrequComboItems,{},updateFrequComboItems[config.plotUpdateFrequ[1]+1][1],false,nil)
        sim.UI_populateCombobox(ui,104,updateFrequComboItems,{},updateFrequComboItems[config.plotUpdateFrequ[2]+1][1],false,nil)
        updateDeviceIdCombobox()

        local loc=getAvailableInputs()
        comboInput=sim.UI_populateCombobox(ui,232,loc,{},simBWF.getObjectAltNameOrNone(simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_INPUT_REF)),true,{{simBWF.NONE_TEXT,-1}})
        
        local d=config['calibrationBallDistance']
        simUI.setEditValue(ui,233,simBWF.format("%.0f",d/0.001),true)
        
        simUI.setCheckboxValue(ui,24,simBWF.getCheckboxValFromBool(sim.boolAnd32(config.bitCoded,2)>0))
        
        simUI.setEditValue(ui,1365,simBWF.getObjectAltName(model),true)
--        simUI.setEditValue(ui,1,simBWF.format("%.0f",config.measurementLength/0.001),true)
        for i=1,2,1 do
            local off=config.detectionOffset[i]
            simUI.setEditValue(ui,4+i-1,simBWF.format("%.0f , %.0f , %.0f",off[1]*1000,off[2]*1000,off[3]*1000),true)
            simUI.setCheckboxValue(ui,100+i,simBWF.getCheckboxValFromBool(config.showPlot[i]),true)
        end
        simBWF.setSelectedEditWidget(ui,sel)
        updateEnabledDisabledItemsDlg()
    end
end

function updateEnabledDisabledItemsDlg()
    if ui then
        local c=readInfo()
        local simStopped=sim.getSimulationState()==sim.simulation_stopped
        simUI.setEnabled(ui,1365,simStopped,true)
--        simUI.setEnabled(ui,1,simStopped,true)
        simUI.setEnabled(ui,3,simStopped,true)
        simUI.setEnabled(ui,24,simStopped and simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_CONVEYOR_REF)>=0,true)
        simUI.setEnabled(ui,4899,simStopped,true)
        simUI.setEnabled(ui,232,simStopped,true)
        simUI.setEnabled(ui,233,simStopped and simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_INPUT_REF)>=0,true)
        local notOnline=not simBWF.isSystemOnline()
    end
end

function conveyorChange_callback(ui,id,newIndex)
    local newLoc=comboConveyor[newIndex+1][2]
    simBWF.setReferencedObjectHandle(model,simBWF.RAGNARSENSOR_INPUT_REF,-1)
    simBWF.setReferencedObjectHandle(model,simBWF.RAGNARSENSOR_CONVEYOR_REF,newLoc)
    sim.setObjectParent(model,newLoc,true) -- attach/detach the vision system to/from the conveyor
    simBWF.markUndoPoint()
    updatePluginRepresentation()
    refreshDlg()
end

--[[
function oppositeSideMeasurement_callback(ui,id,newVal)
    local c=readInfo()
    c.bitCoded=sim.boolOr32(c.bitCoded,1)
    if newVal==0 then
        c.bitCoded=c.bitCoded-1
        sim.setObjectOrientation(sensor,model,{-math.pi/2,0,0})
    else
        sim.setObjectOrientation(sensor,model,{math.pi/2,0,0})
    end
    writeInfo(c)
    simBWF.markUndoPoint()
    refreshDlg()
end
--]]

--[[
function measurementLength_callback(uiHandle,id,newValue)
    local c=readInfo()
    newValue=tonumber(newValue)
    if newValue then
        newValue=newValue/1000
        if newValue<0.05 then newValue=0.05 end
        if newValue>2 then newValue=2 end
        if c.measurementLength~=newValue then
            c.measurementLength=newValue
            local r,minZ=sim.getObjectFloatParameter(sensor,sim.objfloatparam_objbbox_min_z)
            local r,maxZ=sim.getObjectFloatParameter(sensor,sim.objfloatparam_objbbox_max_z)
            local s=maxZ-minZ
            sim.scaleObject(sensor,1,1,newValue/s)
            writeInfo(c)
            simBWF.markUndoPoint()
            updatePluginRepresentation()
        end
    end
    refreshDlg()
end
--]]

function detectionOffsetChange_callback(ui,id,newValue)
    local index=id-4+1
    local c=readInfo()
    local i=1
    local t={0,0,0}
    for token in (newValue..","):gmatch("([^,]*),") do
        t[i]=tonumber(token)
        if t[i]==nil then t[i]=0 end
        t[i]=t[i]*0.001
        if t[i]>2 then t[i]=2 end
        if t[i]<-2 then t[i]=-2 end
        i=i+1
    end
    c.detectionOffset[index]={t[1],t[2],t[3]}
    writeInfo(c)
    simBWF.markUndoPoint()
    updatePluginRepresentation()
    refreshDlg()
end

function showSensorPlotClick_callback(ui,id,newVal)
    local index=id-101+1
    local c=readInfo()
    c.showPlot[index]=(newVal~=0)
    writeInfo(c)
    simBWF.markUndoPoint()
    refreshDlg()
end

function plotUpdateFrequChange_callback(ui,id,newIndex)
    local index=id-103+1
    local c=readInfo()
    c.plotUpdateFrequ[index]=newIndex
    writeInfo(c)
    simBWF.markUndoPoint()
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

function nameChange(ui,id,newVal)
    if simBWF.setObjectAltName(model,newVal)>0 then
        simBWF.markUndoPoint()
        updatePluginRepresentation()
        simUI.setTitle(ui,simBWF.getUiTitleNameFromModel(model,_MODELVERSION_,_CODEVERSION_))
    end
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
        if string.find(data.deviceIds[i],"SENSOR-")==1 then
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

function ext_avoidCircularInput(inputItem)
    -- We have: ragnarSensor --> item1 --> item2 ... --> itemN
    -- None of the above item's input should be 'inputItem'
    -- If 'inputItem' is -1, then none of the above item's input should be 'model'
    -- A. Check this ragnarSensor:
    if inputItem>0 then
        local h=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_INPUT_REF)
        if h==inputItem then
            simBWF.setReferencedObjectHandle(model,simBWF.RAGNARSENSOR_INPUT_REF,-1) -- this input closed the loop. We open it here.
            updatePluginRepresentation()
        end
    end
    
    if inputItem==-1 then
        inputItem=model
    end

    -- B. Check connected items:
    local h=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_INPUT_REF)
    if h>=0 then
        simBWF.callCustomizationScriptFunction("ext_avoidCircularInput",h,inputItem)
    end
end

function ext_forbidInput(inputItem)
    local h=simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_INPUT_REF)
    if h==inputItem then
        simBWF.setReferencedObjectHandle(model,simBWF.RAGNARSENSOR_INPUT_REF,-1)
        updatePluginRepresentation()
    end
end

function ext_getInputObjectHande()
    return simBWF.getReferencedObjectHandle(model,simBWF.RAGNARSENSOR_INPUT_REF)
end

function inputChange_callback(ui,id,newIndex)
    local newLoc=comboInput[newIndex+1][2]
    if newLoc>=0 then
        simBWF.forbidInputForTrackingWindowChainItems(newLoc)
    end
    simBWF.setReferencedObjectHandle(model,simBWF.RAGNARSENSOR_INPUT_REF,newLoc)
    simBWF.setReferencedObjectHandle(model,simBWF.RAGNARSENSOR_CONVEYOR_REF,-1) -- no conveyor in that case
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
                <combobox id="3" on-change="conveyorChange_callback"/>
                
                <label text="Flipped 180 deg. w.r. to conveyor" style="* {margin-left: 20px;}"/>
                <checkbox text="" checked="false" on-change="flipped180Click_callback" id="24"/>
                
                <label text="Input"/>
                <combobox id="232" on-change="inputChange_callback">
                </combobox>

                <label text="Calibration ball distance (mm)" style="* {margin-left: 20px;}"/>
                <edit on-editing-finished="calibrationBallDistanceChange_callback" id="233"/>
            </group>
            </tab>
            
            <tab title="Simulation">
            <group layout="form" flat="false">
                <label text="Visualization" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="Show sensor plot"/>
                <checkbox text="" checked="false" on-change="showSensorPlotClick_callback" id="101"/>
                
                <label text="Visualization update freq."/>
                <combobox id="103" on-change="plotUpdateFrequChange_callback"></combobox>
            </group>
            <group layout="form" flat="false">
                <label text="Simulated sensor specific" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="Detection offset (X, Y, Z, in mm)"/>
                <edit on-editing-finished="detectionOffsetChange_callback" id="4"/>
            </group>
            </tab>

            <tab title="Online">
            <group layout="form" flat="false">
                <label text="Visualization" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="Show sensor plot"/>
                <checkbox text="" checked="false" on-change="showSensorPlotClick_callback" id="102"/>
                
                <label text="Visualization update freq."/>
                <combobox id="104" on-change="plotUpdateFrequChange_callback"></combobox>
            </group>
            <group layout="form" flat="false">
                <label text="Real sensor specific" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="Device ID"/>
                <combobox id="4899" on-change="deviceIdComboChange_callback"> </combobox>
                
                <label text="Detection offset (X, Y, Z, in mm)"/>
                <edit on-editing-finished="detectionOffsetChange_callback" id="5"/>
                
            </group>
            
            </tab>

       </tabs>
        ]]
        
        ui=simBWF.createCustomUi(xml,simBWF.getUiTitleNameFromModel(model,_MODELVERSION_,_CODEVERSION_),previousDlgPos--[[,closeable,onCloseFunction,modal,resizable,activate,additionalUiAttribute--]])
        
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

function setBlueBallInPlace()

    -- The blue ball should be in the Y axis of the sensor's frame, and within +- 0.5 of the origin:
    local p=sim.getObjectPosition(blueBall,model)
    local correct=(math.abs(p[1])>0.0005)or(math.abs(p[3])>0.0005)
    if p[2]>-0.1 and p[2]<0 then
        p[2]=0.11
        correct=true
    end
    if p[2]<0.1 and p[2]>=0 then
        p[2]=-0.11
        correct=true
    end
    if p[2]<-1.01 then 
        p[2]=-1.0
        correct=true
    end
    if p[2]>1.01 then 
        p[2]=1.0
        correct=true
    end
    local r,minZ=sim.getObjectFloatParameter(sensor,sim.objfloatparam_objbbox_min_z)
    local r,maxZ=sim.getObjectFloatParameter(sensor,sim.objfloatparam_objbbox_max_z)
    local s=maxZ-minZ
    if math.abs(p[2]-s)>0.001 then
        correct=true
    end
    if correct then
        sim.setObjectPosition(blueBall,model,{0,p[2],0})
        sim.scaleObject(sensor,1,1,math.abs(p[2])/s)
        if p[2]>=0 then
            sim.setObjectOrientation(sensor,model,{-math.pi/2,0,0})
        else
            sim.setObjectOrientation(sensor,model,{math.pi/2,0,0})
        end
        simBWF.markUndoPoint()
    end
    
end

function sysCall_init()
    dlgMainTabIndex=0
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    _MODELVERSION_=1
    _CODEVERSION_=1
    local _info=readInfo()
    simBWF.checkIfCodeAndModelMatch(model,_CODEVERSION_,_info.version)
    writeInfo(_info)
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    sensor=sim.getObjectHandle('RagnarSensor_sensor')
    blueBall=sim.getObjectHandle('RagnarSensor_blueBall')
    updatePluginRepresentation()
    previousDlgPos=simBWF.readSessionPersistentObjectData(model,"dlgPosAndSize")
    previousOnlineModeSwitch=sim.getBoolParameter(sim.boolparam_online_mode)
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
    if previousOnlineModeSwitch~=sim.getBoolParameter(sim.boolparam_online_mode) then
        previousOnlineModeSwitch=not previousOnlineModeSwitch
        updatePluginRepresentation()
    end
    setBlueBallInPlace()
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
end

function sysCall_beforeSimulation()
    simJustStarted=true
    ext_outputBrSetupMessages()
    ext_outputPluginSetupMessages()
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

