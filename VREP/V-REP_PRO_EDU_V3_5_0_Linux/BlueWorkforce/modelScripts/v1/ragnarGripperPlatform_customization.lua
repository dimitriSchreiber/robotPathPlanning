function ext_getItemData_pricing()
    local obj={}
    obj.name=simBWF.getObjectAltName(model)
    obj.type='ragnarGripperPlatform'
    obj.platformType='default'
    obj.brVersion=1
    local depCnt=1
    local ob=sim.getObjectsInTree(model)
    local dep={}
    for i=1,#ob,1 do
        local data=sim.readCustomDataBlock(ob[i],simBWF.RAGNARGRIPPER_TAG)
        if data then
            dep[#dep+1]=simBWF.getObjectAltName(ob[i])
            break
        end
    end
    if #dep>0 then
        obj.dependencies=dep
    end
    return obj
end

function ext_checkIfPlatformIsAssociatedWithGripper(id)
    if id>=0 then
        return id==sim.getObjectChild(gripperAttachmentPoint,0)
    end
    return false
end

function ext_outputBrSetupMessages()
    local nm=' ['..simBWF.getObjectAltName(model)..']'
    local robots=sim.getObjectsWithTag(simBWF.RAGNAR_TAG,true)
    local present=false
    for i=1,#robots,1 do
        if simBWF.callCustomizationScriptFunction_noError('ext_checkIfRobotIsAssociatedWithGripperPlatform',robots[i],model) then
            present=true
            break
        end
    end
    local msg=""
    if not present then
        msg="WARNING (set-up): Not attached to any robot"..nm
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
        data.type=c['subtype']
        data.gripperId=sim.getObjectChild(gripperAttachmentPoint,0)
        
        simBWF.query('gripperPlatform_update',data)
        
        lastTransmittedData={}
        lastTransmittedData.gripperId=data.gripperId
    end
end

function updatePluginRepresentation_ifNeeded()
    -- To track general type data change that might be modified by V-REP directly:
    if lastTransmittedData then
        local update=false
        if sim.getObjectChild(gripperAttachmentPoint,0)~=lastTransmittedData.gripperId then
            update=true
        end
        if update then
            updatePluginRepresentation()
        end
    end
end

function getDefaultInfoForNonExistingFields(info)
    if not info['version'] then
        info['version']=_MODELVERSION_
    end
    if not info['subtype'] then
        info['subtype']='platform'
    end
    if not info['bitCoded'] then
        info['bitCoded']=0 -- 1=visualize the gripper state with a different gripper platform color
    end
end

function readInfo()
    local data=sim.readCustomDataBlock(model,simBWF.RAGNARGRIPPERPLATFORM_TAG)
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
        sim.writeCustomDataBlock(model,simBWF.RAGNARGRIPPERPLATFORM_TAG,sim.packTable(data))
    else
        sim.writeCustomDataBlock(model,simBWF.RAGNARGRIPPERPLATFORM_TAG,'')
    end
end

function refreshDlg()
    if ui then
        local c=readInfo()
        local sel=simBWF.getSelectedEditWidget(ui)
        simUI.setEditValue(ui,1365,simBWF.getObjectAltName(model),true)
        simUI.setCheckboxValue(ui,1,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],1)~=0),true)

        updateEnabledDisabledItemsDlg()
        
        simBWF.setSelectedEditWidget(ui,sel)
    end
end

function updateEnabledDisabledItemsDlg()
    if ui then
        local c=readInfo()
        local enabled=sim.getSimulationState()==sim.simulation_stopped
        simUI.setEnabled(ui,1365,enabled)
        simUI.setEnabled(ui,1,enabled)
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

function gripperActionColorChangeClick_callback(ui,id,newVal)
    local c=readInfo()
    c.bitCoded=sim.boolXor32(c.bitCoded,1)
    writeInfo(c)
    simBWF.markUndoPoint()
    refreshDlg()
end

function createDlg()
    if (not ui) and simBWF.canOpenPropertyDialog() then
        local xml=[[
            <group layout="form" flat="false">
                <label text="Name"/>
                <edit on-editing-finished="nameChange" id="1365"/>
                
                <label text="Change platform color with gripper action" />
                <checkbox text="" checked="false" on-change="gripperActionColorChangeClick_callback" id="1"/>
                
                <label text="" style="* {margin-left: 150px;}"/>
                <label text="" style="* {margin-left: 150px;}"/>
            </group>
        ]]
        ui=simBWF.createCustomUi(xml,simBWF.getUiTitleNameFromModel(model,_MODELVERSION_,_CODEVERSION_),previousDlgPos--[[,closeable,onCloseFunction,modal,resizable,activate,additionalUiAttribute--]])

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
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    _MODELVERSION_=1
    _CODEVERSION_=1
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    local _info=readInfo()
    simBWF.checkIfCodeAndModelMatch(model,_CODEVERSION_,_info['version'])
    writeInfo(_info)
    ikPts={}
    for i=1,4,1 do
        ikPts[i]=sim.getObjectHandle('RagnarGripperPlatform_ikPt'..i)
        local data={}
        data.index=i
        sim.writeCustomDataBlock(ikPts[i],simBWF.RAGNARGRIPPERPLATFORMIKPT_TAG,sim.packTable(data))
    end
    
    gripperAttachmentPoint=sim.getObjectHandle('RagnarGripperPlatform_toolAttachment')

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
    updatePluginRepresentation_ifNeeded()
end

function sysCall_beforeSimulation()
    ext_outputBrSetupMessages()
    ext_outputPluginSetupMessages()
    removeDlg()
end

function sysCall_sensing()
    ext_outputPluginRuntimeMessages()
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

