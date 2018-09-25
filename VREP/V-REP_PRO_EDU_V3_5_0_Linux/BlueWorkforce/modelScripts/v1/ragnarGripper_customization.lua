function ext_getItemData_pricing()
    local obj={}
    obj.name=simBWF.getObjectAltName(model)
    obj.type='ragnarGripper'
    local c=readInfo()
    obj.gripperType=c.subtype
    obj.brVersion=1
    return obj
end

function ext_attachOrDetachDetectedPart(dat)
    local gripperAction=dat[1]
    -- gripperAction: 0=opened (place all items), 1=closed (pick new item. Previously picked items will remain attached)
    local platform=dat[5]
    local robotRef=dat[6]
    
    local platformM=sim.getObjectMatrix(platform,-1)

    local attach=gripperAction==1
    local parts={}
    local newParent=attachPt
    if attach then
        local allParts=getAllParts()
        for i=1,#allParts,1 do
            local part=allParts[i]
            local data=sim.readCustomDataBlock(part,simBWF.PART_TAG)
            data=sim.unpackTable(data)
            
            -- Put the platform into its picking pose (part velocity corrected):
            sim.setObjectPosition(platform,robotRef,dat[2])
            sim.setObjectOrientation(platform,robotRef,dat[3])
            local p=sim.getObjectPosition(platform,-1)
            p={p[1]+data.vel[1]*dat[4],p[2]+data.vel[2]*dat[4],p[3]+data.vel[3]*dat[4]}
            sim.setObjectPosition(platform,-1,p)
            
            if isPartDetected(part) then
                parts[1]=part
                -- Remember the previous part parent:
                data.previousParentParent=sim.getObjectParent(part)
                sim.writeCustomDataBlock(part,simBWF.PART_TAG,sim.packTable(data))
                break
            end
        end
    else
        parts=sim.getObjectsInTree(attachPt,sim.handle_all,1+2) -- get all first-level children of the attachPt
    end
    for i=1,#parts,1 do
        local part=parts[i]
        local p=sim.getModelProperty(part)
        local isModel=sim.boolAnd32(p,sim.modelproperty_not_model)==0
        -- Make the item dynamic, respondable and detectable again (detaching), or disable those flags (attaching):
        if isModel then
            p=sim.boolOr32(p,sim.modelproperty_not_dynamic+sim.modelproperty_not_respondable+sim.modelproperty_not_detectable)
            if not attach then
                p=p-(sim.modelproperty_not_dynamic+sim.modelproperty_not_respondable+sim.modelproperty_not_detectable)
            end
            sim.setModelProperty(part,p)
        else
            p=sim.getObjectSpecialProperty(part)
            local dynStatic=0
            local dynResp=1
            p=sim.boolOr32(p,sim.objectspecialproperty_detectable_all)
            if attach then
                p=p-sim.objectspecialproperty_detectable_all
                dynStatic=1
                dynResp=0
            end
            sim.setObjectSpecialProperty(part,p)
            sim.setObjectInt32Parameter(part,sim.shapeintparam_static,dynStatic)
            sim.setObjectInt32Parameter(part,sim.shapeintparam_respondable,dynResp)
        end
        if not attach then
            local data=sim.readCustomDataBlock(part,simBWF.PART_TAG)
            data=sim.unpackTable(data)
            newParent=data.previousParentParent
            data.previousParentParent=nil
            sim.writeCustomDataBlock(part,simBWF.PART_TAG,sim.packTable(data))
            -- Set platform into actual drop pose:
            sim.setObjectPosition(platform,robotRef,dat[2])
            sim.setObjectOrientation(platform,robotRef,dat[3])
        else
            -- Put the platform into its picking pose (part velocity corrected):
            local data=sim.readCustomDataBlock(part,simBWF.PART_TAG)
            data=sim.unpackTable(data)
            sim.setObjectPosition(platform,robotRef,dat[2])
            sim.setObjectOrientation(platform,robotRef,dat[3])
            local p=sim.getObjectPosition(platform,-1)
            p={p[1]+data.vel[1]*dat[4],p[2]+data.vel[2]*dat[4],p[3]+data.vel[3]*dat[4]}
            sim.setObjectPosition(platform,-1,p)
        end
        sim.setObjectParent(part,newParent,true)
    end
    sim.setObjectMatrix(platform,-1,platformM) -- restore the original platform pose
    return #parts>0
end

function ext_outputBrSetupMessages()
    local nm=' ['..simBWF.getObjectAltName(model)..']'
    local platforms=sim.getObjectsWithTag(simBWF.RAGNARGRIPPERPLATFORM_TAG,true)
    local present=false
    for i=1,#platforms,1 do
        if simBWF.callCustomizationScriptFunction_noError('ext_checkIfPlatformIsAssociatedWithGripper',platforms[i],model) then
            present=true
            break
        end
    end
    local msg=""
    if not present then
        msg="WARNING (set-up): Not attached to any gripper platform"..nm
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
        data.type=c.subtype
        data.stacking=c.stacking
        data.speed=c.pickAndPlaceInfo.speed
        data.accel=c.pickAndPlaceInfo.accel
        data.dynamics=c.pickAndPlaceInfo.dynamics
        data.dwellTime=c.pickAndPlaceInfo.dwellTime
        data.approachHeight=c.pickAndPlaceInfo.approachHeight
        data.departHeight=c.pickAndPlaceInfo.departHeight
        data.offset=c.pickAndPlaceInfo.offset
        data.rounding=c.pickAndPlaceInfo.rounding
        data.nullingAccuracy=c.pickAndPlaceInfo.nullingAccuracy
        --data.freeModeTiming=c.pickAndPlaceInfo.freeModeTiming
        --data.actionModeTiming=c.pickAndPlaceInfo.actionModeTiming
        data.pickActions={}
        for i=1,#c.pickAndPlaceInfo.pickActions,1 do
            local v=c.pickAndPlaceInfo.pickActions[i]
            data.pickActions[i]={cmd=c.pickAndPlaceInfo.actionTemplates[v.name].cmd,dt=v.dt}
        end
        data.placeActions={}
        for i=1,#c.pickAndPlaceInfo.placeActions,1 do
            local v=c.pickAndPlaceInfo.placeActions[i]
            data.placeActions[i]={cmd=c.pickAndPlaceInfo.actionTemplates[v.name].cmd,dt=v.dt}
        end
        data.relativeToBelt=c.pickAndPlaceInfo.relativeToBelt
        simBWF.query('gripper_update',data)
    end
end

function getAllParts()
    local l=sim.getObjectsInTree(sim.handle_scene,sim.object_shape_type,0)
    local retL={}
    for i=1,#l,1 do
        local isPart,isInstanciated,data=simBWF.isObjectPartAndInstanciated(l[i])
        if isInstanciated then
            retL[#retL+1]=l[i]
        end
    end
    return retL
end

function isPartDetected(partHandle)
    local shapesToTest={}
    if sim.boolAnd32(sim.getModelProperty(partHandle),sim.modelproperty_not_model)>0 then
        -- We have a single shape which is not a model. Is the shape detectable?
        if sim.boolAnd32(sim.getObjectSpecialProperty(partHandle),sim.objectspecialproperty_detectable_all)>0 then
            shapesToTest[1]=partHandle -- yes, it is detectable
        end
    else
        -- We have a model. Does the model have the detectable flags overridden?
        if sim.boolAnd32(sim.getModelProperty(partHandle),sim.modelproperty_not_detectable)==0 then
            -- No, now take all model shapes that are detectable:
            local t=sim.getObjectsInTree(partHandle,sim.object_shape_type,0)
            for i=1,#t,1 do
                if sim.boolAnd32(sim.getObjectSpecialProperty(t[i]),sim.objectspecialproperty_detectable_all)>0 then
                    shapesToTest[#shapesToTest+1]=t[i]
                end
            end
        end
    end
    for i=1,#shapesToTest,1 do
        if sim.checkProximitySensor(sensor,shapesToTest[i])>0 then
            return true
        end
    end
    return false
end


function getDefaultInfoForNonExistingFields(info)
    info['size']=nil
    
    if not info['version'] then
        info['version']=_MODELVERSION_
    end
    if not info['gripperType'] then
        info['gripperType']={0,0,3,0,0,1,2,0,1} -- == xxx.yyy.abc = xxx=type (3=4fingers), yyy=notUsed, a=material, b=0, c=nails/noNails (1=steel nails)
    end
    if not info['subtype'] then
        info['subtype']=getGripperTypeString(info['gripperType'])
    end
    if not info['stacking'] then
        info['stacking']=1
    end
    if not info['stackingShift'] then
        info['stackingShift']=0.01
    end
    if not info['kinematricsParams'] then
        info['kinematricsParams']={0.15,30*math.pi/180,120*math.pi/180} -- i.e. r, gamma1 and gamma2 (needed to compute the workspace for instance)
    end
    -- Following groups part pick/place settings. both can be overridden by a part or pallet item
    if not info['pickAndPlaceInfo'] then
        info['pickAndPlaceInfo']={}
    end
    simBWF._getPickPlaceSettingsDefaultInfoForNonExistingFields(info.pickAndPlaceInfo)
end

function readInfo()
    local data=sim.readCustomDataBlock(model,simBWF.RAGNARGRIPPER_TAG)
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
        sim.writeCustomDataBlock(model,simBWF.RAGNARGRIPPER_TAG,sim.packTable(data))
    else
        sim.writeCustomDataBlock(model,simBWF.RAGNARGRIPPER_TAG,'')
    end
end

function getGripperTypeString(data)
    return (data[1]..data[2]..data[3]..'.'..data[4]..data[5]..data[6]..'.'..data[7]..data[8]..data[9])
end

function pickAndPlaceSettingsClose_cb(dlgPos)
    previousPickPlaceDlgPos=dlgPos
end

function pickAndPlaceSettingsApply_cb(pickAndPlaceInfo)
    local c=readInfo()
    c.pickAndPlaceInfo.overrideGripperSettings=pickAndPlaceInfo.overrideGripperSettings
    c.pickAndPlaceInfo.speed=pickAndPlaceInfo.speed
    c.pickAndPlaceInfo.accel=pickAndPlaceInfo.accel
    c.pickAndPlaceInfo.dynamics=pickAndPlaceInfo.dynamics
    for i=1,2,1 do
        c.pickAndPlaceInfo.dwellTime[i]=pickAndPlaceInfo.dwellTime[i]
        c.pickAndPlaceInfo.approachHeight[i]=pickAndPlaceInfo.approachHeight[i]
        c.pickAndPlaceInfo.departHeight[i]=pickAndPlaceInfo.departHeight[i]
        c.pickAndPlaceInfo.rounding[i]=pickAndPlaceInfo.rounding[i]
        c.pickAndPlaceInfo.nullingAccuracy[i]=pickAndPlaceInfo.nullingAccuracy[i]
        for j=1,3,1 do
            c.pickAndPlaceInfo.offset[i][j]=pickAndPlaceInfo.offset[i][j]
        end
        --c.pickAndPlaceInfo.freeModeTiming[i]=pickAndPlaceInfo.freeModeTiming[i]
        --c.pickAndPlaceInfo.actionModeTiming[i]=pickAndPlaceInfo.actionModeTiming[i]
        c.pickAndPlaceInfo.relativeToBelt[i]=pickAndPlaceInfo.relativeToBelt[i]
    end
    c.pickAndPlaceInfo.actionTemplates=pickAndPlaceInfo.actionTemplates
    c.pickAndPlaceInfo.pickActions=pickAndPlaceInfo.pickActions
    c.pickAndPlaceInfo.placeActions=pickAndPlaceInfo.placeActions
    
    writeInfo(c)
    updatePluginRepresentation()
    simBWF.markUndoPoint()
end

function pickAndPlaceSettings_callback()
    local c=readInfo()
    pickPlaceSettings_display(c.pickAndPlaceInfo,"'"..simBWF.getObjectAltName(model).."' pick & place settings",true,pickAndPlaceSettingsApply_cb,pickAndPlaceSettingsClose_cb,previousPickPlaceDlgPos)
end

function stackingChange_callback(uiHandle,id,newValue)
    local c=readInfo()
    newValue=tonumber(newValue)
    if newValue then
        newValue=math.floor(newValue)
        if newValue<1 then newValue=1 end
        if newValue>20 then newValue=20 end
        if newValue~=c['stacking'] then
            c['stacking']=newValue
            writeInfo(c)
            simBWF.markUndoPoint()
            updatePluginRepresentation()
        end
    end
    refreshDlg()
end

function stackingShiftChange_callback(uiHandle,id,newValue)
    local c=readInfo()
    newValue=tonumber(newValue)
    if newValue then
        newValue=newValue/1000
        if newValue<0 then newValue=0 end
        if newValue>0.1 then newValue=0.1 end
        if newValue~=c['stackingShift'] then
            c['stackingShift']=newValue
            writeInfo(c)
            simBWF.markUndoPoint()
        end
    end
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

function nailComboChange_callback(ui,id,newIndex)
    local c=readInfo()
    c['gripperType'][9]=newIndex-0
    c['subtype']=getGripperTypeString(c['gripperType'])
    writeInfo(c)
    if c['gripperType'][9]==0 then
        sim.setObjectInt32Parameter(nails,sim.objintparam_visibility_layer,0)
    else
        sim.setObjectInt32Parameter(nails,sim.objintparam_visibility_layer,1)
    end
    refreshDlg()
    simBWF.markUndoPoint()
end

function refreshDlg()
    if ui then
        local c=readInfo()
        local sel=simBWF.getSelectedEditWidget(ui)
        simUI.setEditValue(ui,1365,simBWF.getObjectAltName(model),true)
        simUI.setEditValue(ui,1,simBWF.format("%.0f",c['stacking']),true)
        simUI.setEditValue(ui,3,simBWF.format("%.0f",c['stackingShift']*1000),true)
        simUI.setEditValue(ui,5,c['subtype'],true)

        local nailComboItems={
            {"none",0},
            {"steel",1},
            {"plastic",2}
        }
        sim.UI_populateCombobox(ui,2,nailComboItems,{},nailComboItems[c['gripperType'][9]+1][1],false,nil)

        updateEnabledDisabledItems()
        simBWF.setSelectedEditWidget(ui,sel)
    end
end

function updateEnabledDisabledItems()
    if ui then
        local c=readInfo()
        local simStopped=sim.getSimulationState()==sim.simulation_stopped
        simUI.setEnabled(ui,1365,simStopped,true)
        simUI.setEnabled(ui,2,simStopped,true)
        simUI.setEnabled(ui,5,false,true)
    end
end

function createDlg()
    if (not ui) and simBWF.canOpenPropertyDialog() then
        local xml =[[
            <group layout="form" flat="false">
                <label text="Name"/>
                <edit on-editing-finished="nameChange" id="1365"/>
                
                <label text="Type"/>
                <edit id="5"/>
                
                <label text="Nails"/>
                <combobox id="2" on-change="nailComboChange_callback"></combobox>
                
                <label text="Stacking"/>
                <edit on-editing-finished="stackingChange_callback" id="1"/>

                <label text="Stacking shift (mm)"/>
                <edit on-editing-finished="stackingShiftChange_callback" id="3"/>
                
                <label text="Pick & place settings"/>
                <button text="Edit" on-click="pickAndPlaceSettings_callback" id="4" />
                
            <label text="" style="* {margin-left: 150px;}"/>
            <label text="" style="* {margin-left: 150px;}"/>
            </group>
        ]]
        ui=simBWF.createCustomUi(xml,simBWF.getUiTitleNameFromModel(model,_MODELVERSION_,_CODEVERSION_),previousDlgPos,false,nil,false,false,false,'')
        
        refreshDlg()
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
        simUI.destroy(ui)
        ui=nil
    end
end

function sysCall_init()
    require("/BlueWorkforce/modelScripts/v1/pickAndPlaceSettings_include")
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    _MODELVERSION_=1
    _CODEVERSION_=1
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    local _info=readInfo()
    simBWF.checkIfCodeAndModelMatch(model,_CODEVERSION_,_info['version'])
    writeInfo(_info)
    hand=sim.getObjectHandle('RagnarGripper_hand')
    nails=sim.getObjectHandle('RagnarGripper_nails')
    sensor=sim.getObjectHandle('RagnarGripper_sensor')
    attachPt=sim.getObjectHandle('RagnarGripper_attachPt')
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
end

function sysCall_beforeSimulation()
    simJustStarted=true
    ext_outputBrSetupMessages()
    ext_outputPluginSetupMessages()
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
    updateEnabledDisabledItems()
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

