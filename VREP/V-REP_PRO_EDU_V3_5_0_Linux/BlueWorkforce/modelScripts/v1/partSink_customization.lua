function ext_outputBrSetupMessages()
    local nm=' ['..simBWF.getObjectAltName(model)..']'
    local msg=""
    if #msg>0 then
        simBWF.outputMessage(msg)
    end
end

function ext_outputPluginSetupMessages()
    --[[
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
    --]]
end

function ext_outputPluginRuntimeMessages()
    --[[
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
    --]]
end

function removeFromPluginRepresentation()

end

function updatePluginRepresentation()

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
        info['subtype']='sink'
    end
    if not info['width'] then
        info['width']=0.5
    end
    if not info['length'] then
        info['length']=0.5
    end
    if not info['height'] then
        info['height']=0.1
    end
    if not info['status'] then
        info['status']='operational'
    end
    if not info['bitCoded'] then
        info['bitCoded']=1 -- 1=visibleDuringSimulation, 128=show statistics
    end
    if not info['destroyedCnt'] then
        info['destroyedCnt']=0
    end
end

function readInfo()
    local data=sim.readCustomDataBlock(model,simBWF.PARTSINK_TAG)
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
        sim.writeCustomDataBlock(model,simBWF.PARTSINK_TAG,sim.packTable(data))
    else
        sim.writeCustomDataBlock(model,simBWF.PARTSINK_TAG,'')
    end
end

function setSizes()
    local c=readInfo()
    local w=c['width']
    local l=c['length']
    local h=c['height']
    setObjectSize(frame,w,l,h)
    setObjectSize(cross,w-0.002,l-0.002,h-0.002)
    setObjectSize(sensor,w,l,h)
    sim.setObjectPosition(frame,model,{0,0,h*0.5+0.001})
    sim.setObjectPosition(cross,frame,{0,0,0})
    sim.setObjectPosition(sensor,model,{0,0,0.001})
end

function setDlgItemContent()
    if ui then
        local config=readInfo()
        local sel=simBWF.getSelectedEditWidget(ui)
        simUI.setEditValue(ui,1365,simBWF.getObjectAltName(model),true)

        simUI.setEditValue(ui,20,simBWF.format("%.0f , %.0f , %.0f",config.width*1000,config.length*1000,config.height*1000),true)
        simUI.setCheckboxValue(ui,3,simBWF.getCheckboxValFromBool(sim.boolAnd32(config['bitCoded'],1)~=0),true)
        simUI.setCheckboxValue(ui,4,simBWF.getCheckboxValFromBool(config['status']~='disabled'),true)
        simUI.setCheckboxValue(ui,6,simBWF.getCheckboxValFromBool(sim.boolAnd32(config['bitCoded'],128)~=0),true)
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
    setDlgItemContent()
end

function showStatisticsClick_callback(ui,id,newVal)
    local c=readInfo()
    c['bitCoded']=sim.boolOr32(c['bitCoded'],128)
    if newVal==0 then
        c['bitCoded']=c['bitCoded']-128
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    setDlgItemContent()
end

function enabled_callback(ui,id,newVal)
    local c=readInfo()
    if newVal==0 then
        c['status']='disabled'
    else
        c['status']='operational'
    end
    simBWF.markUndoPoint()
    writeInfo(c)
    setDlgItemContent()
end


function sizeChange_callback(ui,id,newValue)
    local c=readInfo()
    local i=1
    local t={c.width,c.length,c.height}
    for token in (newValue..","):gmatch("([^,]*),") do
        t[i]=tonumber(token)
        if t[i]==nil then t[i]=0 end
        t[i]=t[i]*0.001
        if i==1 or i==2 then
            if t[i]<0.2 then t[i]=0.2 end
            if t[i]>5 then t[i]=5 end
        end
        if i==3 then
            if t[i]<0.01 then t[i]=0.01 end
            if t[i]>1 then t[i]=1 end
        end
        i=i+1
    end
    c.width=t[1]
    c.length=t[2]
    c.height=t[3]
    writeInfo(c)
    setSizes()
    simBWF.markUndoPoint()
    setDlgItemContent()
end

function nameChange(ui,id,newVal)
    if simBWF.setObjectAltName(model,newVal)>0 then
        simBWF.markUndoPoint()
        simUI.setTitle(ui,simBWF.getUiTitleNameFromModel(model,_MODELVERSION_,_CODEVERSION_))
    end
    setDlgItemContent()
end

function getAvailableSensors()
    local l=sim.getObjectsInTree(sim.handle_scene,sim.handle_all,0)
    local retL={}
    for i=1,#l,1 do
        local data=sim.readCustomDataBlock(l[i],simBWF.BINARYSENSOR_TAG)
        if data then
            retL[#retL+1]={sim.getObjectName(l[i]),l[i]}
        end
        if not data then
            data=sim.readCustomDataBlock(l[i],simBWF.OLDSTATICPICKWINDOW_TAG)
            if data then
                retL[#retL+1]={sim.getObjectName(l[i]),l[i]}
            end
        end
        if not data then
            data=sim.readCustomDataBlock(l[i],simBWF.OLDSTATICPLACEWINDOW_TAG)
            if data then
                retL[#retL+1]={sim.getObjectName(l[i]),l[i]}
            end
        end
    end
    return retL
end

function triggerChange_callback(ui,id,newIndex)
    local sens=comboTrigger[newIndex+1][2]
    simBWF.setReferencedObjectHandle(model,simBWF.PARTSINK_TRIGGER_REF,sens)
    simBWF.markUndoPoint()
    updateTriggerComboboxes()
end

function updateTriggerComboboxes()
    local c=readInfo()
    local loc=getAvailableSensors()
    comboTrigger=sim.UI_populateCombobox(ui,101,loc,{},simBWF.getObjectNameOrNone(simBWF.getReferencedObjectHandle(model,simBWF.PARTSINK_TRIGGER_REF)),true,{{"<Always active>",-1}})
end

function createDlg()
    if (not ui) and simBWF.canOpenPropertyDialog() then
        local xml =[[
            <group layout="form" flat="false">
                <label text="Name"/>
                <edit on-editing-finished="nameChange" id="1365"/>
                
                <label text="Size (X, Y, Z, in mm)"/>
                <edit on-editing-finished="sizeChange_callback" id="20"/>
                
                <label text="Active on trigger"/>
                <combobox id="101" on-change="triggerChange_callback">
                </combobox>


                <label text="Enabled"/>
                <checkbox text="" on-change="enabled_callback" id="4" />

                <label text="Hidden during simulation"/>
                <checkbox text="" on-change="hidden_callback" id="3" />

                <label text="Show statistics"/>
                 <checkbox text="" checked="false" on-change="showStatisticsClick_callback" id="6"/>
             </group>
        ]]
        ui=simBWF.createCustomUi(xml,simBWF.getUiTitleNameFromModel(model,_MODELVERSION_,_CODEVERSION_),previousDlgPos,false,nil,false,false,false,'')

        updateTriggerComboboxes()
        
        setDlgItemContent()
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
    local _info=readInfo()
    simBWF.checkIfCodeAndModelMatch(model,_CODEVERSION_,_info['version'])
    writeInfo(_info)
    sensor=sim.getObjectHandle('partSink_sensor')
    frame=sim.getObjectHandle('partSink_frame')
    cross=sim.getObjectHandle('partSink_cross')
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

function sysCall_afterSimulation()
    local c=readInfo()
    if wasDisabledBeforeSimulation then
        c['status']='disabled'
    else
        c['status']='operational'
    end
    c['destroyedCnt']=0
    writeInfo(c)

    sim.setObjectInt32Parameter(frame,sim.objintparam_visibility_layer,1)
    sim.setObjectInt32Parameter(cross,sim.objintparam_visibility_layer,1)
    
    sim.setModelProperty(model,0)
    showOrHideUiIfNeeded()
end

function sysCall_beforeSimulation()
    ext_outputBrSetupMessages()
    ext_outputPluginSetupMessages()
    removeDlg()
    local c=readInfo()
    wasDisabledBeforeSimulation=c['status']=='disabled'
    local hide=simBWF.modifyAuxVisualizationItems(sim.boolAnd32(c['bitCoded'],1)~=0)
    if hide then
        sim.setObjectInt32Parameter(frame,sim.objintparam_visibility_layer,256)
        sim.setObjectInt32Parameter(cross,sim.objintparam_visibility_layer,256)
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

