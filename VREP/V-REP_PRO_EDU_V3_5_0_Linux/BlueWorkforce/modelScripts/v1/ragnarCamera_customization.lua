function ext_getItemData_pricing()
    local obj={}
    obj.name=simBWF.getObjectAltName(model)
    obj.type='ragnarCamera'
    obj.cameraType='default'
    obj.brVersion=1
    return obj
end

function ext_outputBrSetupMessages()
    local nm=' ['..simBWF.getObjectAltName(model)..']'
    local msg=""
    local ragnarVisionItems=sim.getObjectsWithTag(simBWF.RAGNARVISION_TAG,true)
    local present=false
    for i=1,#ragnarVisionItems,1 do
        if simBWF.callCustomizationScriptFunction_noError('ext_checkIfIfModelIsUsedAsCamera',ragnarVisionItems[i],model) then
            present=true
            break
        end
    end
    if not present then
        msg="WARNING (set-up): Not associated with any RagnarVision object"..nm
    else
        local c=readInfo()
        if sim.boolAnd32(c.bitCoded,1)>0 then
            msg="WARNING (set-up): Operating in fake detection mode"..nm
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
        data.resolution=c['resolution']
        data.fieldOfView=c['fov']*180/math.pi
        data.deviceId=''
        if c.deviceId~=simBWF.NONE_TEXT then
            data.deviceId=c.deviceId
        end
        simBWF.query('ragnarCamera_update',data)
    end
end

function getDefaultInfoForNonExistingFields(info)
    info['width']=nil
    info['depth']=nil
    info['height']=nil
    if not info['version'] then
        info['version']=_MODELVERSION_
    end
    if not info['subtype'] then
        info['subtype']='camera'
    end
    if not info['size'] then
        info['size']={0.03,0.12,0.03}
    end
    if not info['resolution'] then
        info['resolution']={640,480}
    end
    if not info['clippPlanes'] then
        info['clippPlanes']={0.04,0.75}
    end
    if not info['fov'] then
        info['fov']=60*math.pi/180
    end
    if not info['bitCoded'] then
        info['bitCoded']=0 -- not used
    end
    if not info['imgToDisplay'] then
        info['imgToDisplay']={0,0} -- simulation and real parameters. 0=none, 1=rgb, 2=depth, 3=processed
    end
    if not info['imgSizeToDisplay'] then
        info['imgSizeToDisplay']={0,0} -- simulation and real parameters. 0=small, 1=medium, 2=large
    end
    if not info['imgUpdateFrequ'] then
        info['imgUpdateFrequ']={0,0} -- simulation and real parameters. 0=always, 1=medium (every 200ms), 2=rare (every 1s)
    end
    if not info['deviceId'] then
        info['deviceId']=simBWF.NONE_TEXT
    end
end

function readInfo()
    local data=sim.readCustomDataBlock(model,simBWF.RAGNARCAMERA_TAG)
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
        sim.writeCustomDataBlock(model,simBWF.RAGNARCAMERA_TAG,sim.packTable(data))
    else
        sim.writeCustomDataBlock(model,simBWF.RAGNARCAMERA_TAG,'')
    end
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

function setCameraBodySizes()
    local c=readInfo()
    local w=c['size'][2]
    local l=c['size'][1]
    local h=c['size'][3]
    setObjectSize(body,w,h,l)
end

function setResolutionAndFov(res,fov)
    sim.setObjectInt32Parameter(sensor,sim.visionintparam_resolution_x,res[1])
    sim.setObjectInt32Parameter(sensor,sim.visionintparam_resolution_y,res[2])
    local ratio=res[1]/res[2]
    if ratio>1 then
        fov=2*math.atan(math.tan(fov/2)*ratio)
        print(180*2*math.atan(math.tan(60*math.pi/360)/ratio)/math.pi)
    end
    sim.setObjectFloatParameter(sensor,sim.visionfloatparam_perspective_angle,fov)
end

function setClippingPlanes(clipp)
    sim.setObjectFloatParameter(sensor,sim.visionfloatparam_near_clipping,clipp[1])
    sim.setObjectFloatParameter(sensor,sim.visionfloatparam_far_clipping,clipp[2])
end

function refreshDlg()
    if ui then
        local config=readInfo()
        local sel=simBWF.getSelectedEditWidget(ui)
        
        local typeComboItems={
            {"none",0},
            {"color",1},
            {"depth",2},
--            {"processed",3},
        }
        sim.UI_populateCombobox(ui,1001,typeComboItems,{},typeComboItems[config['imgToDisplay'][1]+1][1],false,nil)
        local sizeComboItems={
            {"small",0},
            {"medium",1},
            {"large",2}
        }
        sim.UI_populateCombobox(ui,1002,sizeComboItems,{},sizeComboItems[config['imgSizeToDisplay'][1]+1][1],false,nil)
        local updateFrequComboItems={
            {"every 50 ms",0},
            {"every 200 ms",1},
            {"every 1000 ms",2}
        }
        sim.UI_populateCombobox(ui,1003,updateFrequComboItems,{},updateFrequComboItems[config['imgUpdateFrequ'][1]+1][1],false,nil)
        sim.UI_populateCombobox(ui,1101,typeComboItems,{},typeComboItems[config['imgToDisplay'][2]+1][1],false,nil)
        sim.UI_populateCombobox(ui,1102,sizeComboItems,{},sizeComboItems[config['imgSizeToDisplay'][2]+1][1],false,nil)
        sim.UI_populateCombobox(ui,1103,updateFrequComboItems,{},updateFrequComboItems[config['imgUpdateFrequ'][2]+1][1],false,nil)

        updateDeviceIdCombobox()

        simUI.setEditValue(ui,1365,simBWF.getObjectAltName(model),true)
        simUI.setEditValue(ui,1,simBWF.format("%.0f , %.0f , %.0f",config.size[1]*1000,config.size[2]*1000,config.size[3]*1000),true)
        simUI.setEditValue(ui,4,simBWF.format("%i",config['resolution'][1]),true)
        simUI.setEditValue(ui,5,simBWF.format("%i",config['resolution'][2]),true)
        simUI.setEditValue(ui,6,simBWF.format("%.0f",config['clippPlanes'][1]/0.001),true)
        simUI.setEditValue(ui,7,simBWF.format("%.0f",config['clippPlanes'][2]/0.001),true)
        simUI.setEditValue(ui,8,simBWF.format("%.1f",config['fov']*180/math.pi),true)
        simBWF.setSelectedEditWidget(ui,sel)
        updateEnabledDisabledItemsDlg()
    end
end

function updateEnabledDisabledItemsDlg()
    if ui then
        local c=readInfo()
        local simStopped=sim.getSimulationState()==sim.simulation_stopped
        simUI.setEnabled(ui,1365,simStopped,true)
        simUI.setEnabled(ui,1,simStopped,true)
        simUI.setEnabled(ui,4,simStopped,true)
        simUI.setEnabled(ui,5,simStopped,true)
        simUI.setEnabled(ui,6,simStopped,true)
        simUI.setEnabled(ui,7,simStopped,true)
        simUI.setEnabled(ui,8,simStopped,true)
        simUI.setEnabled(ui,4899,simStopped,true)
    end
end

function sizeChange_callback(ui,id,newValue)
    local c=readInfo()
    local i=1
    local t=c.size
    for token in (newValue..","):gmatch("([^,]*),") do
        t[i]=tonumber(token)
        if t[i]==nil then t[i]=0 end
        t[i]=t[i]*0.001
        if i==1 then
            if t[i]<0.005 then t[i]=0.005 end
            if t[i]>0.15 then t[i]=0.15 end
        end
        if i==2 then
            if t[i]<0.01 then t[i]=0.01 end
            if t[i]>0.3 then t[i]=0.3 end
        end
        if i==3 then
            if t[i]<0.005 then t[i]=0.005 end
            if t[i]>0.15 then t[i]=0.15 end
        end
        i=i+1
    end
    c.size=t
    writeInfo(c)
    setCameraBodySizes()
    simBWF.markUndoPoint()
    refreshDlg()
end

function fovChange_callback(ui,id,newVal)
    local c=readInfo()
    local v=tonumber(newVal)
    if v then
        if v<45 then v=45 end
        if v>110 then v=110 end
        v=v*math.pi/180
        if v~=c.fov then
            c.fov=v
            writeInfo(c)
            setResolutionAndFov(c.resolution,c.fov)
            simBWF.markUndoPoint()
            updatePluginRepresentation()
        end
    end
    refreshDlg()
end

function resXChange_callback(ui,id,newVal)
    local c=readInfo()
    local v=tonumber(newVal)
    if v then
        v=math.floor(v)
        if v<128 then v=128 end
        if v>1024 then v=1024 end
        if v~=c.resolution[1] then
            c.resolution[1]=v
--            c.detectionPolygonSimulation={}
            writeInfo(c)
            setResolutionAndFov(c.resolution,c.fov)
            simBWF.markUndoPoint()
            updatePluginRepresentation()
        end
    end
    refreshDlg()
end

function resYChange_callback(ui,id,newVal)
    local c=readInfo()
    local v=tonumber(newVal)
    if v then
        v=math.floor(v)
        if v<128 then v=128 end
        if v>1024 then v=1024 end
        if v~=c.resolution[2] then
            c.resolution[2]=v
--            c.detectionPolygonSimulation={}
            writeInfo(c)
            setResolutionAndFov(c.resolution,c.fov)
            simBWF.markUndoPoint()
            updatePluginRepresentation()
        end
    end
    refreshDlg()
end

function nearClippingPlaneChange_callback(ui,id,newVal)
    local c=readInfo()
    local v=tonumber(newVal)
    if v then
        v=v*0.001
        if v<0.02 then v=0.02 end
        if v>0.5 then v=0.5 end
        if v>(c['clippPlanes'][2]-0.01) then v=c['clippPlanes'][2]-0.01 end
        if v~=c['clippPlanes'][1] then
            c['clippPlanes'][1]=v
            writeInfo(c)
            setClippingPlanes(c['clippPlanes'])
            simBWF.markUndoPoint()
        end
    end
    refreshDlg()
end

function farClippingPlaneChange_callback(ui,id,newVal)
    local c=readInfo()
    local v=tonumber(newVal)
    if v then
        v=v*0.001
        if v<0.1 then v=0.1 end
        if v>2 then v=2 end
        if v<(c['clippPlanes'][1]+0.01) then v=c['clippPlanes'][1]+0.01 end
        if v~=c['clippPlanes'][2] then
            c['clippPlanes'][2]=v
            writeInfo(c)
            setClippingPlanes(c['clippPlanes'])
            simBWF.markUndoPoint()
        end
    end
    refreshDlg()
end

function simImageChange_callback(ui,id,newIndex)
    local c=readInfo()
    c['imgToDisplay'][1]=newIndex
    writeInfo(c)
    simBWF.markUndoPoint()
end

function simVisualizationSizeChange_callback(ui,id,newIndex)
    local c=readInfo()
    c['imgSizeToDisplay'][1]=newIndex
    writeInfo(c)
    simBWF.markUndoPoint()
end

function simImgUpdateFrequChange_callback(ui,id,newIndex)
    local c=readInfo()
    c['imgUpdateFrequ'][1]=newIndex
    writeInfo(c)
    simBWF.markUndoPoint()
end

function realImageChange_callback(ui,id,newIndex)
    local c=readInfo()
    c['imgToDisplay'][2]=newIndex
    writeInfo(c)
    simBWF.markUndoPoint()
end

function realVisualizationSizeChange_callback(ui,id,newIndex)
    local c=readInfo()
    c['imgSizeToDisplay'][2]=newIndex
    writeInfo(c)
    simBWF.markUndoPoint()
end

function realImgUpdateFrequChange_callback(ui,id,newIndex)
    local c=readInfo()
    c['imgUpdateFrequ'][2]=newIndex
    writeInfo(c)
    simBWF.markUndoPoint()
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
        if string.find(data.deviceIds[i],"VISION-")==1 then
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

function createDlg()
    if (not ui) and simBWF.canOpenPropertyDialog() then
        local xml =[[
        <tabs id="77">
            <tab title="General">
            <group layout="form" flat="false">

                <label text="Name"/>
                <edit on-editing-finished="nameChange" id="1365"/>

            </group>
            </tab>

            <tab title="Simulation">
            <group layout="form" flat="false">
                <label text="Visualization" style="* {font-weight: bold;}"/>  <label text=""/>

                <label text="Camera image to show"/>
                <combobox id="1001" on-change="simImageChange_callback"></combobox>
                
                <label text="Visualization size"/>
                <combobox id="1002" on-change="simVisualizationSizeChange_callback"></combobox>
                
                <label text="Visualization update freq."/>
                <combobox id="1003" on-change="simImgUpdateFrequChange_callback"></combobox>
            </group>
            <group layout="form" flat="false">
                <label text="Simulated camera specific" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="Vertical field of view (deg)"/>
                <edit on-editing-finished="fovChange_callback" id="8"/>

                <label text="resolution X"/>
                <edit on-editing-finished="resXChange_callback" id="4"/>

                <label text="resolution Y"/>
                <edit on-editing-finished="resYChange_callback" id="5"/>
            </group>
            </tab>
             <tab title="Online">

            <group layout="form" flat="false">
                <label text="Visualization" style="* {font-weight: bold;}"/>  <label text=""/>

                <label text="Camera image to show"/>
                <combobox id="1101" on-change="realImageChange_callback"></combobox>
                
                <label text="Visualization size"/>
                <combobox id="1102" on-change="realVisualizationSizeChange_callback"></combobox>
                
                <label text="Visualization update freq."/>
                <combobox id="1103" on-change="realImgUpdateFrequChange_callback"></combobox>
            </group>
                
            <group layout="form" flat="false">
                <label text="Real camera specific" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="Device ID"/>
                <combobox id="4899" on-change="deviceIdComboChange_callback"> </combobox>
            </group>
            </tab>
            <tab title="More">
            <group layout="form" flat="false">
                
                <label text="Camera body size (X, Y, Z, in mm)"/>
                <edit on-editing-finished="sizeChange_callback" id="1"/>

                <label text="Camera Near clipping plane (mm)"/>
                <edit on-editing-finished="nearClippingPlaneChange_callback" id="6"/>

                <label text="Camera far clipping plane (mm)"/>
                <edit on-editing-finished="farClippingPlaneChange_callback" id="7"/>
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
    body=sim.getObjectHandle('RagnarCamera_body')
    arrows=sim.getObjectHandle('RagnarCamera_arrows')
    sensor=sim.getObjectHandle('RagnarCamera_sensor')
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
--    sim.setObjectInt32Parameter(arrows,sim.objintparam_visibility_layer,1)
    updateEnabledDisabledItemsDlg()
end

function sysCall_beforeSimulation()
    simJustStarted=true
--    sim.setObjectInt32Parameter(arrows,sim.objintparam_visibility_layer,0)
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

