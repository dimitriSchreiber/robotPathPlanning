function ext_clearCalibration()
    local c=readInfo()
    c.calibration=nil
    c.calibrationMatrix=nil
    writeInfo(c)
    applyCalibrationColor()
    updatePluginRepresentation()
end

function ext_getItemData_pricing()
    local obj={}
    obj.name=simBWF.getObjectAltName(model)
    obj.type='locationFrame'
    obj.frameType='place'
    obj.brVersion=1
    if isPick then
        obj.frameType='pick'
    end
    return obj
end

function ext_announcePalletWasRenamed()
    refreshDlg()
end

function ext_announcePalletWasCreated()
    refreshDlg()
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
        if simBWF.getReferencedObjectHandle(model,simBWF.LOCATIONFRAME_PALLET_REF)==-1 then
            msg="WARNING (set-up): Has no associated pallet"..nm
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

function ext_announceOnlineModeChanged(isNowOnline)
    updatePluginRepresentation()
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

function ext_setLocationFrameIntoOnlineCalibrationPose()
    locationFrameNormalM=sim.getObjectMatrix(model,-1)
    applyCalibrationData(false)
end

function sysCall_beforeDelete(data)
    -- Check if the pallet this frame depends on will be deleted
    local pallet=simBWF.getReferencedObjectHandle(model,simBWF.LOCATIONFRAME_PALLET_REF)
    if pallet>=0 and data.objectHandles[pallet] then
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
        data.version=1
        data.name=simBWF.getObjectAltName(model)
        data.palletId=simBWF.getReferencedObjectHandle(model,simBWF.LOCATIONFRAME_PALLET_REF)
        local dt=ext_getCalibrationDataForCurrentMode()
        data.realCalibration=dt.realCalibration
        data.ball1=dt.ball1
        data.ball2=dt.ball2
        data.ball3=dt.ball3
        data.type=c['type']
        data.pickWithoutTarget=sim.boolAnd32(c['bitCoded'],32)>0
        simBWF.query('locationFrame_update',data)

        lastTransmittedData={}
        lastTransmittedData.pos=sim.getObjectPosition(model,-1)
        lastTransmittedData.quaternion=sim.getObjectQuaternion(model,-1)
        lastTransmittedData.calibration=dt
    end
end

function updatePluginRepresentation_ifNeeded()
    -- To track general type data change that might be modified by V-REP directly:
    if lastTransmittedData then
        local update=false
        local calData=ext_getCalibrationDataForCurrentMode()
        local quat=sim.getObjectQuaternion(model,-1)
        for i=1,4,1 do
            if quat[i]~=lastTransmittedData.quaternion[i] then
                update=true
                break
            end
        end
        local pos=sim.getObjectPosition(model,-1)
        for i=1,3,1 do
            if pos[i]~=lastTransmittedData.pos[i] then
                update=true
                break
            end
            if calData.ball1[i]~=lastTransmittedData.calibration.ball1[i] then
                update=true
                break
            end
            if calData.ball2[i]~=lastTransmittedData.calibration.ball2[i] then
                update=true
                break
            end
            if calData.ball3[i]~=lastTransmittedData.calibration.ball3[i] then
                update=true
                break
            end
            if calData.realCalibration~=lastTransmittedData.calibration.realCalibration then
                update=true
                break
            end
        end
        if update then
            updatePluginRepresentation()
        end
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

function getDefaultInfoForNonExistingFields(info)
    if not info['version'] then
        info['version']=_MODELVERSION_
    end
    if not info['subtype'] then
        info['subtype']='pick'
    end
    if not info['type'] then
        info['type']=0 -- 0=pick, 1=place
    end
    info['palletId']=nil
--    if not info['palletId'] then
--        info['palletId']=-1 -- -1=none
--    end
    if not info['bitCoded'] then
        info['bitCoded']=1 -- 1=hidden during sim, 2=calibration balls hidden during sim, 4=free, 8=create parts (online mode), 16=show associated pallet, 32=pick also without target in sight
    end
    if not info['calibration'] then
        info['calibration']=nil -- either nil, or {ball1RelPos,ball2RelPos,ball3RelPos}
    end
    if not info['calibrationMatrix'] then
        info['calibrationMatrix']=nil -- either nil, or the calibration matrix
    end
end

function readInfo()
    local data=sim.readCustomDataBlock(model,simBWF.LOCATIONFRAME_TAG)
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
        sim.writeCustomDataBlock(model,simBWF.LOCATIONFRAME_TAG,sim.packTable(data))
    else
        sim.writeCustomDataBlock(model,simBWF.LOCATIONFRAME_TAG,'')
    end
end

function updateEnabledDisabledItemsDlg()
    if ui then
        local simStopped=sim.getSimulationState()==sim.simulation_stopped
        local config=readInfo()
        simUI.setEnabled(ui,1365,simStopped,true)
        simUI.setEnabled(ui,5,simStopped,true) -- simBWF.getReferencedObjectHandle(model,simBWF.LOCATIONFRAME_PALLET_REF)>=0,true)
        if isPick then
            simUI.setEnabled(ui,6,not getIsPickWithoutTargetOverridden(),true)
        end
    end
end

function refreshDlg()
    if ui then
        local config=readInfo()
        local sel=simBWF.getSelectedEditWidget(ui)
        simUI.setEditValue(ui,1365,simBWF.getObjectAltName(model),true)
        simUI.setCheckboxValue(ui,1,simBWF.getCheckboxValFromBool(sim.boolAnd32(config['bitCoded'],1)~=0),true)
        simUI.setCheckboxValue(ui,3,simBWF.getCheckboxValFromBool(sim.boolAnd32(config['bitCoded'],2)~=0),true)
        simUI.setCheckboxValue(ui,4,simBWF.getCheckboxValFromBool(sim.boolAnd32(config['bitCoded'],8)~=0),true)
        simUI.setCheckboxValue(ui,5,simBWF.getCheckboxValFromBool(sim.boolAnd32(config['bitCoded'],16)~=0),true)
        if isPick then
            local val=sim.boolAnd32(config['bitCoded'],32)~=0
            if getIsPickWithoutTargetOverridden() then
                val=true
            end
            simUI.setCheckboxValue(ui,6,simBWF.getCheckboxValFromBool(val),true)
        end
        
        local pallets=simBWF.getAvailablePallets()
        local refPallet=simBWF.getReferencedObjectHandle(model,simBWF.LOCATIONFRAME_PALLET_REF)
        local selected=simBWF.NONE_TEXT
        for i=1,#pallets,1 do
            if pallets[i][2]==refPallet then
                selected=pallets[i][1]
                break
            end
        end
        comboPallet=sim.UI_populateCombobox(ui,2,pallets,{},selected,true,{{simBWF.NONE_TEXT,-1}})
        
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

function palletChange_callback(ui,id,newIndex)
    simBWF.setReferencedObjectHandle(model,simBWF.LOCATIONFRAME_PALLET_REF,comboPallet[newIndex+1][2])
    simBWF.markUndoPoint()
    updatePluginRepresentation()
    updateEnabledDisabledItemsDlg()
--    updatePalletVisualization()
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

function showPallet_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],16)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-16
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    refreshDlg()
end

function showOrHideCalibrationBalls(show)
    if show then
        sim.setModelProperty(calibrationBalls[1],0)
    else
        sim.setModelProperty(calibrationBalls[1],sim.modelproperty_not_showasinsidemodel+sim.modelproperty_not_visible)
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

function onCalibrationUiClose()
    local data={}
    data.idRobot=getAssociatedRobotHandle()
    data.id=model
    simBWF.query('locationFrame_trainEnd',data)
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
        local reply,replyData=simBWF.query('locationFrame_train',data)
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
            local reply,replyData=simBWF.query('locationFrame_train',data)
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
            local reply,replyData=simBWF.query('locationFrame_train',data)
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
                        simBWF.query('locationFrame_trainEnd',data)
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
        simBWF.query('locationFrame_trainEnd',data)
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
        sim.msgBox(sim.msgbox_type_info,sim.msgbox_buttons_ok,'Calibration','The location frame is not associated with any robot.')
    else
        local data={}
        data.idRobot=getAssociatedRobotHandle()
        data.id=model
        local reply=simBWF.query('locationFrame_trainStart',data)
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
            calibrationData.relativeBallPositions={}
            calibrationData.ui=simBWF.createCustomUi(xml,"Calibration","center",true,"onCalibrationUiClose",true,false,true)
        end
    end
end

function getAssociatedRobotHandle()
    local ragnars=sim.getObjectsWithTag(simBWF.RAGNAR_TAG,true)
    for i=1,#ragnars,1 do
        if simBWF.callCustomizationScriptFunction_noError('ext_checkIfRobotIsAssociatedWithLocationFrameOrTrackingWindow',ragnars[i],model) then
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
                
                <label text="Associated pallet"/>
                <combobox id="2" on-change="palletChange_callback"/>]]
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
                <checkbox text="" on-change="hidden_callback" id="1" />

                 <label text="Calibration balls hidden during simulation" />
                <checkbox text="" on-change="calibrationBallsHidden_callback" id="3" />
                
                <label text="Show associated pallet" />
                <checkbox text="" on-change="showPallet_callback" id="5" />

                <label text="Create parts (online mode)"/>
                <checkbox text="" on-change="createParts_callback" id="4" />
            </group>
            </tab>
       </tabs>
        ]]

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
    local tmp=_info.calibration
    if tmp and not _info.calibrationMatrix then -- to correct a bug (6/12/2017)
        local m=simBWF.getMatrixFromCalibrationBallPositions(tmp[1],tmp[2],tmp[3])
        _info.calibrationMatrix=m
    end
    writeInfo(_info)
    isPick=(_info['type']==0)
    if isPick then
        frameShape=sim.getObjectHandle('pickLocationFrame_shape')
    else
        frameShape=sim.getObjectHandle('placeLocationFrame_shape')
    end
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    calibrationBalls={}
    for i=1,3,1 do
        if isPick then
            calibrationBalls[i]=sim.getObjectHandle('pickLocationFrame_calibrationBall'..i)
        else
            calibrationBalls[i]=sim.getObjectHandle('placeLocationFrame_calibrationBall'..i)
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

function applyCalibrationData(attach)
    local retVal=false
    local associatedRobot=getAssociatedRobotHandle()
    local c=readInfo()
    local calData=c['calibration']
    if associatedRobot>=0 then
        local associatedRobotRef=simBWF.callCustomizationScriptFunction('ext_getReferenceObject',associatedRobot)
        if calData then
            -- Find the matrix:
            local m=simBWF.getMatrixFromCalibrationBallPositions(calData[1],calData[2],calData[3])
            -- Apply it to this model:
            sim.setObjectMatrix(model,associatedRobotRef,m)
            -- Place the green and blue balls:
            sim.invertMatrix(m)
            sim.setObjectPosition(calibrationBalls[2],model,sim.multiplyVector(m,calData[2]))
            sim.setObjectPosition(calibrationBalls[3],model,sim.multiplyVector(m,calData[3]))
            retVal=true
            if attach then
                sim.setObjectParent(model,associatedRobotRef,true)
            end
        end
    else
        if calData then
            c['calibration']=nil
            c['calibrationMatrix']=nil
            writeInfo(c)
        end
    end
    if not attach then
        sim.setObjectParent(model,-1,true)
    end
    return retVal
end

function applyCalibrationColor()
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
    setGreenAndBlueCalibrationBallsInPlace()
    showOrHideCalibrationBalls(not hideBalls)
    updatePluginRepresentation_ifNeeded()
end

function sysCall_sensing()
    if simJustStarted then
        updateEnabledDisabledItemsDlg()
    end
    simJustStarted=nil
    ext_outputPluginRuntimeMessages()
end

function sysCall_afterSimulation()
    if locationFrameNormalM then
        applyCalibrationData(false)
        sim.setObjectMatrix(model,-1,locationFrameNormalM)
        locationFrameNormalM=nil
    end
    sim.setObjectInt32Parameter(frameShape,sim.objintparam_visibility_layer,1)
    showOrHideUiIfNeeded()
    updateEnabledDisabledItemsDlg()
    updatePluginRepresentation()
end

function sysCall_beforeSimulation()
    simJustStarted=true
    ext_outputBrSetupMessages()
    ext_outputPluginSetupMessages()
    removeDlg()
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

