function removeFromPluginRepresentation_brApp()
    if bwfPluginLoaded then
        local data={}
        data.id=model
        simBWF.query('object_delete',data)
    end
end

function updatePluginRepresentation_brApp()
    if bwfPluginLoaded then
        local c=readInfo()
        local data={}
        data.id=model
        data.code=c.packMlCode

        simBWF.query('packml_update',data)
    end
end

function updatePluginRepresentation_generalProperties()
    if bwfPluginLoaded then
        local c=readInfo()
        local data={}
        data.id=model
        data.masterIp=c.masterIp
        simBWF.query('generalProperties_update',data)
    end
end

function getDefaultInfoForNonExistingFields(info)
    if not info['version'] then
        info['version']=_MODELVERSION_
    end
    if not info['subtype'] then
        info['subtype']='br-app'
    end
    if not info['bitCoded'] then
        info['bitCoded']=0 -- 1=show packMl, 2=simplified packMl,4=show time, 8=simplified time, 16=show OEE, 32= show warnings at sim start
    end
    if not info['packMlCode'] then
        local code={}
        code.aborting="-- 'Aborting' code:"
        code.aborted="-- 'Aborted' code:"
        code.clearing="-- 'Clearing' code:"
        code.stopping="-- 'Stopping' code:"
        code.stopped="-- 'Stopped' code:"

        code.suspending="-- 'Suspending' code:"
        code.suspended="-- 'Suspended' code:"
        code.unsuspending="-- 'Un-Suspending' code:"
        code.resetting="-- 'Resetting' code:"
        
        code.complete="-- 'Complete' code:"
        code.completing="-- 'Completing' code:"
        code.execute="-- 'Execute' code:"
        code.starting="-- 'Starting' code:"
        code.idle="-- 'Idle' code:"
        
        code.holding="-- 'Holding' code:"
        code.hold="-- 'Hold' code:"
        code.unholding="-- 'Un-Holding' code:"
        info['packMlCode']=code
    end
    if not info['floorSizes'] then
        info['floorSizes']={10,10}
    end
    info['pallets']=nil
    if not info.masterIp then
        info.masterIp="127.0.0.1"
    end
--    if not info['pallets'] then
--        info['pallets']={}
--    end
end

function readInfo()
    local data=sim.readCustomDataBlock(model,simBWF.BLUEREALITYAPP_TAG)
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
        sim.writeCustomDataBlock(model,simBWF.BLUEREALITYAPP_TAG,sim.packTable(data))
    else
        sim.writeCustomDataBlock(model,simBWF.BLUEREALITYAPP_TAG,'')
    end
end

function editPackMlCode(title,field)
    local s="800 600"
    local p="100 100"
    if packMlCodeDlgSize then
        s=packMlCodeDlgSize[1]..' '..packMlCodeDlgSize[2]
    end
    if packMlCodeDlgPos then
        p=packMlCodeDlgPos[1]..' '..packMlCodeDlgPos[2]
    end
    local xml = '<editor title="'..title..'" '
    xml = xml..[[editable="true" searchable="true"
            tabWidth="4" textColor="50 50 50" backgroundColor="190 190 190"
            selectionColor="128 128 255" size="]]..s..[[" position="]]..p..[["
            useVrepKeywords="false" isLua="true">
        </editor>
    ]]

    local c=readInfo()
    local initialText=c['packMlCode'][field]
    local modifiedText
    modifiedText,packMlCodeDlgSize,packMlCodeDlgPos=sim.openTextEditor(initialText,xml)
    if modifiedText~=initialText then
        if sim.msgbox_return_yes==sim.msgBox(sim.msgbox_type_question,sim.msgbox_buttons_yesno,"PackML Code Change","Do you want to apply the changes?") then
            c['packMlCode'][field]=modifiedText
            writeInfo(c)
            simBWF.markUndoPoint()
            updatePluginRepresentation_brApp()
        end
    end
end

function packML_aborting_callback()
    editPackMlCode("PackML 'Aborting' Code","aborting")
end

function packML_aborted_callback()
    editPackMlCode("PackML 'Aborted' Code","aborted")
end

function packML_clearing_callback()
    editPackMlCode("PackML 'Clearing' Code","clearing")
end

function packML_stopping_callback()
    editPackMlCode("PackML 'Stopping' Code","stopping")
end

function packML_stopped_callback()
    editPackMlCode("PackML 'Stopped' Code","stopped")
end

function packML_suspending_callback()
    editPackMlCode("PackML 'Suspending' Code","suspending")
end

function packML_suspended_callback()
    editPackMlCode("PackML 'Suspended' Code","suspended")
end

function packML_unsuspending_callback()
    editPackMlCode("PackML 'Un-Suspending' Code","unsuspending")
end

function packML_resetting_callback()
    editPackMlCode("PackML 'Resetting' Code","resetting")
end

function packML_complete_callback()
    editPackMlCode("PackML 'Complete' Code","complete")
end

function packML_completing_callback()
    editPackMlCode("PackML 'Completing' Code","completing")
end

function packML_execute_callback()
    editPackMlCode("PackML 'Execute' Code","execute")
end

function packML_starting_callback()
    editPackMlCode("PackML 'Starting' Code","starting")
end

function packML_idle_callback()
    editPackMlCode("PackML 'Idle' Code","idle")
end

function packML_holding_callback()
    editPackMlCode("PackML 'Holding' Code","holding")
end

function packML_hold_callback()
    editPackMlCode("PackML 'Hold' Code","hold")
end

function packML_unholding_callback()
    editPackMlCode("PackML 'Un-Holding' Code","unholding")
end

function packML_onClose()
    local x,y=simUI.getPosition(packMLui)
    packML_previousDlgPos={x,y}
    simUI.destroy(packMLui)
end

function packML_createDlg()
    if bwfPluginLoaded then
        local xml =[[
                <image geometry="0,0,1088,607" width="1088" height="607" id="1000"/>
                
                <button text="Aborting" geometry="932,502,100,40" on-click="packML_aborting_callback" id="1" style="* {background-color: #66ff66}"/>                
                <button text="Aborted" geometry="715,502,100,40" on-click="packML_aborted_callback" id="2" style="* {background-color: #ffff66}"/>                
                <button text="Clearing" geometry="497,502,100,40" on-click="packML_clearing_callback" id="3" style="* {background-color: #66ff66}"/>                
                <button text="Stopping" geometry="279,502,100,40" on-click="packML_stopping_callback" id="4" style="* {background-color: #66ff66}"/>                
                <button text="Stopped" geometry="61,502,100,40" on-click="packML_stopped_callback" id="5" style="* {background-color: #ffff66}"/>                
                
                <button text="Suspending" geometry="715,308,100,40" on-click="packML_suspending_callback" id="6" style="* {background-color: #66ff66}"/>                
                <button text="Suspended" geometry="497,308,100,40" on-click="packML_suspended_callback" id="7" style="* {background-color: #ffff66}"/>                
                <button text="Un-Suspending" geometry="279,308,100,40" on-click="packML_unsuspending_callback" id="8" style="* {background-color: #66ff66}"/>                
                <button text="Resetting" geometry="61,308,100,40" on-click="packML_resetting_callback" id="9" style="* {background-color: #66ff66}"/>                

                <button text="Complete" geometry="932,186,100,40" on-click="packML_complete_callback" id="10" style="* {background-color: #ffff66}"/>                
                <button text="Completing" geometry="715,186,100,40" on-click="packML_completing_callback" id="11" style="* {background-color: #66ff66}"/>                
                <button text="Execute" geometry="497,186,100,40" on-click="packML_execute_callback" id="12" style="* {background-color: #66aaff}"/>                
                <button text="Starting" geometry="279,186,100,40" on-click="packML_starting_callback" id="13" style="* {background-color: #66ff66}"/>                
                <button text="Idle" geometry="61,186,100,40" on-click="packML_idle_callback" id="14" style="* {background-color: #ffff66}"/>                

                <button text="Holding" geometry="715,65,100,40" on-click="packML_holding_callback" id="15" style="* {background-color: #66ff66}"/>                
                <button text="Hold" geometry="497,65,100,40" on-click="packML_hold_callback" id="16" style="* {background-color: #ffff66}"/>                
                <button text="Un-Holding" geometry="279,65,100,40" on-click="packML_unholding_callback" id="17" style="* {background-color: #66ff66}"/>                
                ]]
        packMLui=simBWF.createCustomUi(xml,'PackML',packML_previousDlgPos,true,'packML_onClose',true,false,false,'layout="none"',{1088,607})

        local img=nil
        local c=readInfo()
        if not c.packedPackMlImage then
            local file=io.open("d:/v_rep/textures/packML-selfMade.png","rb")
            img=file:read("*a")
            c.packedPackMlImage=img
            writeInfo(c)
        end

        -- We have the image stored in PNG
        img="@mem"..c.packedPackMlImage
        img=sim.loadImage(0,img)
        
        simUI.setImageData(packMLui,1000,img,1088,607)
    end
end

function refreshBrAppDlg()
    if brAppUi then
        local config=readInfo()
        local sel=simBWF.getSelectedEditWidget(brAppUi)
        if (version>30400 or revision>12) then
            simUI.setCheckboxValue(brAppUi,11,simBWF.getCheckboxValFromBool(sim.getBoolParameter(sim.boolparam_br_partrepository)),true)
            simUI.setCheckboxValue(brAppUi,12,simBWF.getCheckboxValFromBool(sim.getBoolParameter(sim.boolparam_br_palletrepository)),true)
        end
        simUI.setCheckboxValue(brAppUi,8,simBWF.getCheckboxValFromBool(testingWithoutPlugin),true)
        simUI.setCheckboxValue(brAppUi,5,simBWF.getCheckboxValFromBool(sim.getBoolParameter(sim.boolparam_online_mode)),true)
        simBWF.setSelectedEditWidget(brAppUi,sel)
        updateBrAppEnabledDisabledItemsDlg()
    end
end

function updateBrAppEnabledDisabledItemsDlg()
    if brAppUi then
        local config=readInfo()
        local simStopped=sim.getSimulationState()==sim.simulation_stopped
        simUI.setEnabled(brAppUi,5,simStopped,true)
        simUI.setEnabled(brAppUi,6,simStopped,true)
        simUI.setEnabled(brAppUi,11,simStopped,true)
        simUI.setEnabled(brAppUi,12,simStopped,true)
    end
end


function partRepository_callback(ui,id)
    sim.setBoolParameter(sim.boolparam_br_partrepository,not sim.getBoolParameter(sim.boolparam_br_partrepository))
    refreshBrAppDlg()
    updateBrAppEnabledDisabledItemsDlg()
end

function verifyLayout_callback()
    sim.clearStringSignal('__brMessages__')
    if messageConsole then
        sim.auxiliaryConsoleClose(messageConsole)
        messageConsole=nil
    end
    -- General setup messages:
    outputGeneralSetupMessages()
    -- Object-specific setup messages:
    local tags=simBWF.getModelTagsForMessages()
    for i=1,#tags,1 do
        local objs=sim.getObjectsWithTag(tags[i],true)
        for j=1,#objs,1 do
            simBWF.callCustomizationScriptFunction_noError('ext_outputBrSetupMessages',objs[j])
            simBWF.callCustomizationScriptFunction_noError('ext_outputPluginSetupMessages',objs[j])
        end
    end
    local msgs=sim.getStringSignal('__brMessages__')
    if msgs then
        messageConsole=sim.auxiliaryConsoleOpen('Messages',400,4,nil,{800,400})
        sim.clearStringSignal('__brMessages__')
        sim.auxiliaryConsolePrint(messageConsole,msgs)
    end
end

function palletRepository_callback(ui,id)
    sim.setBoolParameter(sim.boolparam_br_palletrepository,not sim.getBoolParameter(sim.boolparam_br_palletrepository))
    refreshBrAppDlg()
    updateBrAppEnabledDisabledItemsDlg()
end

function generalPropertiesDlg_close_callback()
    simUI.destroy(generalPropertiesUi)
    generalProperties=nil
    simBWF.markUndoPoint()
    updatePluginRepresentation_generalProperties()
end

function generalPropertiesDlg_masterIpChange_callback(ui,id,newVal)
    local c=readInfo()
    c.masterIp=newVal
    writeInfo(c)
    refreshGeneralPropertiesDialog()
end

function oee_callback(ui,id)
    local c=readInfo()
    c.bitCoded=sim.boolXor32(c.bitCoded,16)
    writeInfo(c)
    refreshGeneralPropertiesDialog()
end

function warningAtRunStart_callback(ui,id)
    local c=readInfo()
    c.bitCoded=sim.boolXor32(c.bitCoded,32)
    writeInfo(c)
end

function simplifiedSimulationTime_callback(ui,id)
    local c=readInfo()
    c.bitCoded=sim.boolXor32(c.bitCoded,8)
    writeInfo(c)
    refreshGeneralPropertiesDialog()
end

function simulationTime_callback(ui,id)
    local c=readInfo()
    c.bitCoded=sim.boolXor32(c.bitCoded,4)
    writeInfo(c)
    refreshGeneralPropertiesDialog()
end

function packMLState_callback(ui,id)
    local c=readInfo()
    c.bitCoded=sim.boolXor32(c.bitCoded,1)
    writeInfo(c)
    refreshGeneralPropertiesDialog()
end

function simplifiedPackMLState_callback(ui,id)
    local c=readInfo()
    c.bitCoded=sim.boolXor32(c.bitCoded,2)
    writeInfo(c)
    refreshGeneralPropertiesDialog()
end


function generalPropertiesDlg_callback(ui,id)
    local xml =[[
                <group layout="form" flat="false">
                    <label text="Master IP" style="* {font-weight: bold;}"/>  <label text=""/>
                    
                    <label text="Address"/>
                    <edit on-editing-finished="generalPropertiesDlg_masterIpChange_callback" style="* {min-width: 100px;}" id="1"/>
                </group>
                
                <group layout="form" flat="false">
                    <label text="PackML" style="* {font-weight: bold;}"/>  <label text=""/>
                    
                    <label text="Behaviour"/>
                    <button text="Edit" on-click="packML_createDlg" id="2" />
                    
                    <label text="Display state when running"/>
                    <checkbox text="" on-change="packMLState_callback" id="3" />

                    <label text="Simplified display"/>
                    <checkbox text="" on-change="simplifiedPackMLState_callback" id="4" />
                </group>

                <group layout="form" flat="false">
                    <label text="Time" style="* {font-weight: bold;}"/>  <label text=""/>
                    
                    <label text="Display when running"/>
                    <checkbox text="" on-change="simulationTime_callback" id="5" />
                    
                    <label text="Simplified display"/>
                    <checkbox text="" on-change="simplifiedSimulationTime_callback" id="6" />
                </group>
                
                <group layout="form" flat="false">
                    <label text="OEE" style="* {font-weight: bold;}"/>  <label text=""/>
                    
                    <label text="Display when running"/>
                    <checkbox text="" on-change="oee_callback" id="7" />
                </group>
                
                <group layout="form" flat="false">
                    <label text="Various" style="* {font-weight: bold;}"/>  <label text=""/>
                    
                    <label text="Display warnings when running"/>
                    <checkbox text="" on-change="warningAtRunStart_callback" id="8" />
                </group>
    ]]
    generalPropertiesUi=simBWF.createCustomUi(xml,"Global Properties","center",true,"generalPropertiesDlg_close_callback",true,false,true)
    refreshGeneralPropertiesDialog()
end

function refreshGeneralPropertiesDialog()
    local c=readInfo()
    local sel=simBWF.getSelectedEditWidget(generalPropertiesUi)
    
    simUI.setEditValue(generalPropertiesUi,1,c.masterIp)
    simUI.setCheckboxValue(generalPropertiesUi,3,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],1)~=0),true)
    simUI.setCheckboxValue(generalPropertiesUi,4,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],2)~=0),true)
    simUI.setCheckboxValue(generalPropertiesUi,5,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],4)~=0),true)
    simUI.setCheckboxValue(generalPropertiesUi,6,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],8)~=0),true)
    simUI.setCheckboxValue(generalPropertiesUi,7,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],16)~=0),true)
    simUI.setCheckboxValue(generalPropertiesUi,8,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],32)~=0),true)
    
    local simStopped=sim.getSimulationState()==sim.simulation_stopped
    simUI.setEnabled(generalPropertiesUi,1,simStopped,true)
    simUI.setEnabled(generalPropertiesUi,2,simStopped,true)
    
    simUI.setEnabled(generalPropertiesUi,4,sim.boolAnd32(c['bitCoded'],1)~=0,true)
    simUI.setEnabled(generalPropertiesUi,6,sim.boolAnd32(c['bitCoded'],4)~=0,true)
    
    simBWF.setSelectedEditWidget(generalPropertiesUi,sel)
end

function testingWithoutPlugin_callback(ui,id,val)
    testingWithoutPlugin=(val~=0)
    if testingWithoutPlugin then
        sim.setIntegerSignal('__brTesting__',1)
    else
        sim.clearIntegerSignal('__brTesting__')
    end
end

function connectWhenRunning_callback(ui,id,val)
    local s=sim.getBoolParameter(sim.boolparam_online_mode)
    sim.setBoolParameter(sim.boolparam_online_mode,not s)
end

function saveJsonClick_callback()
    if bwfPluginLoaded then
        if variousActionDlgId then
            simUI.destroy(variousActionDlgId)
            variousActionDlgId=nil
        end
        local pathAndName=sim.fileDialog(sim.filedlg_type_save,"JSON File Save","","","JSON file","JSON")
        if pathAndName and #pathAndName>0 then
            local data={}
            data.fileName=pathAndName
            simBWF.query('make_JSON_file',data)
        end
    end
end

function startOnline()
    if not online then
        sim.setBoolParameter(sim.boolparam_realtime_simulation,true)
        sim.setArrayParameter(sim.arrayparam_background_color2,{0.8,1,0.8})
        sim.setIntegerSignal('__brOnline__',1)
        online=true
        if bwfPluginLoaded then
            simBWF.query('online_start',{})
        end
        updateBrAppEnabledDisabledItemsDlg()
    end
end

function stopOnline()
    if online then
        sim.setArrayParameter(sim.arrayparam_background_color2,{0.8,0.87,0.92})
        sim.clearIntegerSignal('__brOnline__')
        online=false
        if bwfPluginLoaded then
            simBWF.query('online_stop',{})
        end
        updateBrAppEnabledDisabledItemsDlg()
    end
end

function startSimulation()
    if not simulation then
        sim.setBoolParameter(sim.boolparam_realtime_simulation,false)
        sim.setArrayParameter(sim.arrayparam_background_color2,{0.8,0.8,1})
        simulation=true
        if bwfPluginLoaded then
            simBWF.query('simulation_start',{})
        end
        updateBrAppEnabledDisabledItemsDlg()
    end
end

function stopSimulation()
    if simulation then
        sim.setArrayParameter(sim.arrayparam_background_color2,{0.8,0.87,0.92})
        simulation=false
        if bwfPluginLoaded then
            simBWF.query('simulation_stop',{})
        end
        updateBrAppEnabledDisabledItemsDlg()
    end
end

function sendRequest(payload,path)
    local response_body = { }
    http.TIMEOUT=60 -- default is 60

    local res, code, response_headers, response_status_line = http.request
    {
        url = path,
        method = "POST",
        headers =
        {
          ["Content-Type"] = "application/json",
          ["Content-Length"] = payload:len()
        },
        source = ltn12.source.string(payload),
        sink = ltn12.sink.table(response_body)
    }
    return res,code,response_status_line,table.concat(response_body)
end

function quoteRequest_executeIfNeeded()
    if quoteRequest then
        if quoteRequest.counter>0 then
            quoteRequest.counter=quoteRequest.counter-1
        else
            local res,code,response_status_line,data=sendRequest(quoteRequest.payload,'http://brcommunicator.azurewebsites.net/api/quote')
            if res and code==200 then
                local filename='Quote_'..os.date()..'.docx'
                filename=string.gsub(filename,":","_")
                filename=string.gsub(filename," ","_")
                local f = assert(io.open(filename, 'wb')) -- open in "binary" mode
                f:write(data)
                f:close()
                simBWF.openFile(filename)
            else
                -- code contains the error msg if res is nil. Otherwise, it contains a status code
                local msg="Failed to retrieve the quote information.\n"
                if not res then
                    msg=msg.."Status code is: "..code
                else
                    msg=msg.."Error message is: "..res
                end
                sim.msgBox(sim.msgbox_type_warning,sim.msgbox_buttons_ok,"Quote inquiry",msg)
            end
            simUI.destroy(quoteRequest.ui)
            quoteRequest=nil
        end
    end
end

function roiRequest_executeIfNeeded()
    if roiRequest then
        if roiRequest.counter>0 then
            roiRequest.counter=roiRequest.counter-1
        else
            local res,code,response_status_line,data=sendRequest(roiRequest.payload,'http://brcommunicator.azurewebsites.net/api/roi')
            if res and code==200 then
                local filename='ROI_'..os.date()..'.xlsx'
                filename=string.gsub(filename,":","_")
                filename=string.gsub(filename," ","_")
                local f = assert(io.open(filename, 'wb')) -- open in "binary" mode
                f:write(data)
                f:close()
                simBWF.openFile(filename)
            else
                -- code contains the error msg if res is nil. Otherwise, it contains a status code
                local msg="Failed to retrieve the ROI information.\n"
                if not res then
                    msg=msg.."Status code is: "..code
                else
                    msg=msg.."Error message is: "..res
                end
                sim.msgBox(sim.msgbox_type_warning,sim.msgbox_buttons_ok,"ROI inquiry",msg)
            end
            simUI.destroy(roiRequest.ui)
            roiRequest=nil
        end
    end
end

function sopRequest_executeIfNeeded()
    if sopRequest then
        if sopRequest.counter>0 then
            sopRequest.counter=sopRequest.counter-1
        else
            local res,code,response_status_line,data=sendRequest(sopRequest.payload,'http://brcommunicator.azurewebsites.net/api/sop')
            if res and code==200 then
                local sopConsole=sim.auxiliaryConsoleOpen('Production order',500,4,{100,100},{1000,400},nil,{1,1,1})
                local sopData=json.decode(data)
                for i=1,#sopData/2,1 do
                    local txt='Ragnar '..i..'\n'
                    txt=txt..'    Serial: '..sopData[2*(i-1)+1]..'\n'
                    txt=txt..'    QR code URL: '..sopData[2*(i-1)+2]..'\n'
                    sim.auxiliaryConsolePrint(sopConsole,txt)
                end
            else
                -- code contains the error msg if res is nil. Otherwise, it contains a status code
                local msg="Failed to retrieve the SOP information.\n"
                if not res then
                    msg=msg.."Status code is: "..code
                else
                    msg=msg.."Error message is: "..res
                end
                sim.msgBox(sim.msgbox_type_warning,sim.msgbox_buttons_ok,"SOP inquiry",msg)
            end
            simUI.destroy(sopRequest.ui)
            sopRequest=nil
        end
    end
end

function getSceneScreenShot()
    ---[[
    local rgb=nil
    local res={640,360} -- {640,480}
    if not fromTop then
        -- use a camera from one of the non-floating views:
        for i=0,10,1 do
            if sim.adjustView(i,-1,256)==2 then
                camera=sim.adjustView(i,-1,512)
                if sim.getObjectType(camera)~=sim.object_camera_type then
                    camera=-1
                end
            end
            if camera~=-1 then
                break
            end
        end
        if camera==-1 then
            fromTop=true
        else
            local vs=sim.createVisionSensor(1+2+128,{res[1],res[2],0,0},{0.1,50,60*math.pi/180,0.1,0.1,0.1,255,255,255,0,0})
            sim.setObjectOrientation(vs,camera,{0,0,0})
            sim.setObjectPosition(vs,camera,{0,0,0})
            sim.handleVisionSensor(vs)
            rgb=sim.getVisionSensorCharImage(vs)
            sim.removeObject(vs)
        end
    end
    if fromTop then
        local fl=sim.getObjectHandle('ResizableFloor_5_25')
        local prop=sim.getModelProperty(fl)
        sim.setModelProperty(fl,sim.modelproperty_not_visible)
        local parentless=sim.getObjectsInTree(sim.handle_scene,sim.handle_all,2)
        local minMaxX={9999,-9999}
        local minMaxY={9999,-9999}
        for po=1,#parentless,1 do
            local p=sim.getModelProperty(parentless[po])
            local isVisibleModel=sim.boolAnd32(p,sim.modelproperty_not_model+sim.modelproperty_not_visible)==0
            if isVisibleModel then
                local shapes=sim.getObjectsInTree(parentless[po],sim.object_shape_type,0)
                for sc=1,#shapes,1 do
                    local sp=sim.getObjectSpecialProperty(shapes[sc])
                    if sim.boolAnd32(sp,sim.objectspecialproperty_renderable)>0 then
                        local vertices=sim.getShapeMesh(shapes[sc])
                        local m=sim.getObjectMatrix(shapes[sc],-1)
                        for i=0,#vertices/3-1,1 do
                            local v={vertices[3*i+1],vertices[3*i+2],vertices[3*i+3]}
                            v=sim.multiplyVector(m,v)
                            if minMaxX[1]>v[1] then
                                minMaxX[1]=v[1]
                            end
                            if minMaxX[2]<v[1] then
                                minMaxX[2]=v[1]
                            end
                            if minMaxY[1]>v[2] then
                                minMaxY[1]=v[2]
                            end
                            if minMaxY[2]<v[2] then
                                minMaxY[2]=v[2]
                            end
                        end
                    end
                end
            end
        end
        local extX=minMaxX[2]-minMaxX[1]
        local extY=(minMaxY[2]-minMaxY[1])*1/0.75
       
        local vs=sim.createVisionSensor(1+128,{res[1],res[2],0,0},{0.1,10,math.max(extX,extY),0.1,0.1,0.1,255,255,255,0,0})
        sim.setObjectOrientation(vs,-1,{180*math.pi/180,0,0})
        sim.setObjectPosition(vs,-1,{(minMaxX[1]+minMaxX[2])/2,(minMaxY[1]+minMaxY[2])/2,5})
        sim.handleVisionSensor(vs)
        sim.setModelProperty(fl,prop)
        rgb=sim.getVisionSensorCharImage(vs)
        sim.removeObject(vs)
    end
    if rgb then
        local pngData=sim.saveImage(rgb,res,0,'.png',-1)
        pngData=sim.transformBuffer(pngData,sim.buffer_uint8,1,0,sim.buffer_base64)
        return pngData
    end
    --]]
end

function closeROI_callback()
    simUI.destroy(roiInfo.ui)
    roiInfo.ui=nil
end

function workersCurrentROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>1000 then newValue=1000 end
        roiInfo.current.number_of_workers=math.floor(newValue*10)/10
    end
    refreshRoiDlg()
end

function hourlyCostCurrentROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>1000 then newValue=1000 end
        roiInfo.current.burdened_hourly_cost=math.floor(newValue*100)/100
    end
    refreshRoiDlg()
end

function outputRateCurrentROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>1000 then newValue=1000 end
        roiInfo.current.output_rate_parts_per_minute=math.floor(newValue)
    end
    refreshRoiDlg()
end

function failureRateCurrentROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>100 then newValue=100 end
        roiInfo.current.quality_failure_rate=math.floor(newValue)/100
    end
    refreshRoiDlg()
end

function workersBwfROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>1000 then newValue=1000 end
        roiInfo.bwf.number_of_workers=math.floor(newValue*10)/10
    end
    refreshRoiDlg()
end

function hourlyCostBwfROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>1000 then newValue=1000 end
        roiInfo.bwf.burdened_hourly_cost=math.floor(newValue*100)/100
    end
    refreshRoiDlg()
end

function outputRateBwfROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>1000 then newValue=1000 end
        roiInfo.bwf.output_rate_parts_per_minute=math.floor(newValue)
    end
    refreshRoiDlg()
end

function failureRateBwfROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>100 then newValue=100 end
        roiInfo.bwf.quality_failure_rate=math.floor(newValue)/100
    end
    refreshRoiDlg()
end

function shiftsPerDayBwfROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>5 then newValue=5 end
        roiInfo.bwf.shifts_per_day=math.floor(newValue)
    end
    refreshRoiDlg()
end

function hoursPerShiftBwfROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>12 then newValue=12 end
        roiInfo.bwf.hours_per_shift=math.floor(newValue*10)/10
    end
    refreshRoiDlg()
end

function prodDaysPerYearBwfROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>365 then newValue=365 end
        roiInfo.bwf.production_days_per_year=math.floor(newValue)
    end
    refreshRoiDlg()
end

function reworkCostBwfROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>1000 then newValue=1000 end
        roiInfo.bwf.cost_to_rework_quality_failures=math.floor(newValue*1000)/1000
    end
    refreshRoiDlg()
end

function dualGripperCostROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>10000 then newValue=10000 end
--        roiInfo.unit_cost_1=math.floor(newValue*100)/100
        roiInfo.dual_gripper_cost=math.floor(newValue*100)/100
    end
    refreshRoiDlg()
end

function lipBaseCostROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>10000 then newValue=10000 end
--        roiInfo.unit_cost_2=math.floor(newValue*100)/100
        roiInfo.lip_base_cost=math.floor(newValue*100)/100
    end
    refreshRoiDlg()
end

function swivelAdaptorCostROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>10000 then newValue=10000 end
--        roiInfo.unit_cost_3=math.floor(newValue*100)/100
        roiInfo.swivel_adaptor_cost=math.floor(newValue*100)/100
    end
    refreshRoiDlg()
end

function depreciationROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>20 then newValue=20 end
        roiInfo.depreciation=math.floor(newValue*10)/10
    end
    refreshRoiDlg()
end

function financingCostROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>100 then newValue=100 end
        roiInfo.financing_cost=math.floor(newValue)/100
    end
    refreshRoiDlg()
end

function otherEquipmentCostROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>10000000 then newValue=10000000 end
        roiInfo.cost_of_other_equipment=math.floor(newValue*100)/100
    end
    refreshRoiDlg()
end

function shippingCostROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>100000 then newValue=100000 end
        roiInfo.shipping_and_installation=math.floor(newValue*100)/100
    end
    refreshRoiDlg()
end

function sparePartsCostROI_callback(uiHandle,id,newValue)
    newValue=tonumber(newValue)
    if newValue then
        if newValue<0 then newValue=0 end
        if newValue>100000 then newValue=100000 end
        roiInfo.spare_parts_purchase=math.floor(newValue*100)/100
    end
    refreshRoiDlg()
end

function refreshRoiDlg()
    local sel=simBWF.getSelectedEditWidget(roiInfo.ui)
    simUI.setEditValue(roiInfo.ui,1,simBWF.format("%.1f",roiInfo.current.number_of_workers))
    simUI.setEditValue(roiInfo.ui,2,simBWF.format("%.2f",roiInfo.current.burdened_hourly_cost))
    simUI.setEditValue(roiInfo.ui,3,simBWF.format("%.0f",roiInfo.current.output_rate_parts_per_minute))
    simUI.setEditValue(roiInfo.ui,4,simBWF.format("%.0f",roiInfo.current.quality_failure_rate*100))

    simUI.setEditValue(roiInfo.ui,5,simBWF.format("%.1f",roiInfo.bwf.number_of_workers))
    simUI.setEditValue(roiInfo.ui,6,simBWF.format("%.2f",roiInfo.bwf.burdened_hourly_cost))
    simUI.setEditValue(roiInfo.ui,7,simBWF.format("%.0f",roiInfo.bwf.output_rate_parts_per_minute))
    simUI.setEditValue(roiInfo.ui,8,simBWF.format("%.0f",roiInfo.bwf.quality_failure_rate*100))
    simUI.setEditValue(roiInfo.ui,9,simBWF.format("%.0f",roiInfo.bwf.shifts_per_day))
    simUI.setEditValue(roiInfo.ui,10,simBWF.format("%.1f",roiInfo.bwf.hours_per_shift))
    simUI.setEditValue(roiInfo.ui,11,simBWF.format("%.0f",roiInfo.bwf.production_days_per_year))
    simUI.setEditValue(roiInfo.ui,12,simBWF.format("%.3f",roiInfo.bwf.cost_to_rework_quality_failures))
    
    simUI.setEditValue(roiInfo.ui,13,simBWF.format("%.2f",roiInfo.dual_gripper_cost))
    simUI.setEditValue(roiInfo.ui,14,simBWF.format("%.2f",roiInfo.lip_base_cost))
    simUI.setEditValue(roiInfo.ui,15,simBWF.format("%.2f",roiInfo.swivel_adaptor_cost))
    
    
    simUI.setEditValue(roiInfo.ui,16,simBWF.format("%.1f",roiInfo.depreciation))
    simUI.setEditValue(roiInfo.ui,17,simBWF.format("%.0f",roiInfo.financing_cost*100))
    simUI.setEditValue(roiInfo.ui,19,simBWF.format("%.2f",roiInfo.cost_of_other_equipment))
    simUI.setEditValue(roiInfo.ui,20,simBWF.format("%.2f",roiInfo.shipping_and_installation))
    simUI.setEditValue(roiInfo.ui,21,simBWF.format("%.2f",roiInfo.spare_parts_purchase))
    
    simBWF.setSelectedEditWidget(roiInfo.ui,sel)
end

function generateDefaultRoiInfoIfNeeded()
    roiInfo={}
    roiInfo.current={}
    roiInfo.current.number_of_workers=4
    roiInfo.current.burdened_hourly_cost=17
    roiInfo.current.output_rate_parts_per_minute=330
    roiInfo.current.quality_failure_rate=0

    roiInfo.bwf={}
    roiInfo.bwf.number_of_workers=0.5
    roiInfo.bwf.burdened_hourly_cost=17
    roiInfo.bwf.output_rate_parts_per_minute=330
    roiInfo.bwf.quality_failure_rate=0
    
    roiInfo.bwf.shifts_per_day=3
    roiInfo.bwf.hours_per_shift=8
    roiInfo.bwf.production_days_per_year=300
    roiInfo.bwf.cost_to_rework_quality_failures=0.05

    roiInfo.dual_gripper_cost=435
    roiInfo.lip_base_cost=800
    roiInfo.swivel_adaptor_cost=0
   
    roiInfo.depreciation=7
    roiInfo.financing_cost=0.05
    roiInfo.cost_of_other_equipment=20000
    roiInfo.shipping_and_installation=10000
    roiInfo.spare_parts_purchase=5000
end

function roiSettingsDlg()
    local xml =[[
    <tabs id="78">
    <tab title="Production environment">
            <group layout="form" flat="false">
                <label text="Current" style="* {font-weight: bold; min-width: 250px;}"/>  <label style="* {max-width: 50px;}"/>
                
                <label text="Number of workers"/>
                <edit on-editing-finished="workersCurrentROI_callback" id="1"/>

                <label text="Burdened hourly cost"/>
                <edit on-editing-finished="hourlyCostCurrentROI_callback" id="2"/>

                <label text="Output rate (parts per min.)"/>
                <edit on-editing-finished="outputRateCurrentROI_callback" id="3"/>
                
                <label text="Quality failure rate (%)"/>
                <edit on-editing-finished="failureRateCurrentROI_callback" id="4"/>
            </group>
                
            <group layout="form" flat="false">
                <label text="With BWF" style="* {font-weight: bold; min-width: 250px;}"/>  <label style="* {max-width: 50px;}"/>
                
                <label text="Number of workers"/>
                <edit on-editing-finished="workersBwfROI_callback" id="5"/>

                <label text="Burdened hourly cost"/>
                <edit on-editing-finished="hourlyCostBwfROI_callback" id="6"/>

                <label text="Output rate (parts per min.)"/>
                <edit on-editing-finished="outputRateBwfROI_callback" id="7"/>
                
                <label text="Quality failure rate (%)"/>
                <edit on-editing-finished="failureRateBwfROI_callback" id="8"/>

                <label text="Shifts per day"/>
                <edit on-editing-finished="shiftsPerDayBwfROI_callback" id="9"/>

                <label text="Hours per shift"/>
                <edit on-editing-finished="hoursPerShiftBwfROI_callback" id="10"/>

                <label text="Production days per year"/>
                <edit on-editing-finished="prodDaysPerYearBwfROI_callback" id="11"/>

                <label text="Cost to rework quality failures"/>
                <edit on-editing-finished="reworkCostBwfROI_callback" id="12"/>
            </group>
    </tab>
    <tab title="Other">
            <group layout="form" flat="false">
                <label text="Consumables" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="Dual gripper cost"/>
                <edit on-editing-finished="dualGripperCostROI_callback" id="13"/>

                <label text="Lip base cost"/>
                <edit on-editing-finished="lipBaseCostROI_callback" id="14"/>

                <label text="Swivel adapter cost"/>
                <edit on-editing-finished="swivelAdaptorCostROI_callback" id="15"/>
            </group>
                
            <group layout="form" flat="false">
                <label text="Other" style="* {font-weight: bold;}"/>  <label text=""/>
                
                <label text="Depreciation in life of (years)"/>
                <edit on-editing-finished="depreciationROI_callback" id="16"/>
                
                <label text="Financing cost (%)"/>
                <edit on-editing-finished="financingCostROI_callback" id="17"/>
                
                <label text="Cost of other equipment"/>
                <edit on-editing-finished="otherEquipmentCostROI_callback" id="19"/>
                
                <label text="Cost of ship. & installation"/>
                <edit on-editing-finished="shippingCostROI_callback" id="20"/>
                
                <label text="Cost of spare parts"/>
                <edit on-editing-finished="sparePartsCostROI_callback" id="21"/>
            </group>
    </tab>
    </tabs>
    <button text="Close" on-click="closeROI_callback" />
    ]]
    if not roiInfo then
        generateDefaultRoiInfoIfNeeded()
    end
    roiInfo.ui=simBWF.createCustomUi(xml,'ROI Calculation Request','center',false,nil,true,false,true)
    refreshRoiDlg()
end

function remoteRequestDlg(requestType) -- 0=generate quote, 1=compute roi, 2=generate SOP
    if variousActionDlgId then
        simUI.destroy(variousActionDlgId)
        variousActionDlgId=nil
    end

    generateDefaultRoiInfoIfNeeded()
    local xml =[[
        <group layout="form" flat="true">
            <label text="Client ID"/>
            <edit on-editing-finished="userIdPricing_callback" id="1"/>
            
            <label text="Power supply"/>
            <combobox id="5" on-change="powerSupplyComboChangePricing_callback"></combobox>

            <label text="Connector type"/>
            <combobox id="6" on-change="connectorTypeComboChangePricing_callback"></combobox>
            
            <label text="Line control"/>
            <combobox id="7" on-change="lineControlComboChangePricing_callback"></combobox>

            <label text="Shipping"/>
            <combobox id="8" on-change="shippingComboChangePricing_callback"></combobox>

            <label text="Destination"/>
            <combobox id="9" on-change="destinationComboChangePricing_callback"></combobox>

            <label text="Documentation"/>
            <combobox id="10" on-change="documentationComboChangePricing_callback"></combobox> ]]
            
            if requestType==1 then
                xml=xml..[[
                    <label text="ROI input"/>
                    <button text="Edit" on-click="roiSettingsDlg"/>
                    ]]
            end
            xml=xml..[[
                </group>
                    <group layout="form" flat="true">
                    <button text="Cancel" on-click="cancelRequestDlg_callback" id="3" />
                    ]]
            if requestType==0 then
                xml=xml..'<button text="OK" on-click="okQuote_callback" id="4" />'
            end
            if requestType==1 then
                xml=xml..'<button text="OK" on-click="okRoi_callback" id="4" />'
            end
            if requestType==2 then
                xml=xml..'<button text="OK" on-click="okSop_callback" id="4" />'
            end
            xml=xml..'</group>'
            
    if not remoteRequestUi then
        remoteRequestUi={}
        remoteRequestUi.userId='001'
        remoteRequestUi.power='220V'
        remoteRequestUi.connector='Phoenix'
        remoteRequestUi.lineControl='upstream'
        remoteRequestUi.shipping='air'
        remoteRequestUi.destination='Europe'
        remoteRequestUi.documentation='English'
    end
    if requestType==0 then
        remoteRequestUi.ui=simBWF.createCustomUi(xml,'Generate quote','center',false,nil,true,false,true)
    end
    if requestType==1 then
        remoteRequestUi.ui=simBWF.createCustomUi(xml,'Compute ROI','center',false,nil,true,false,true)
    end
    if requestType==2 then
        remoteRequestUi.ui=simBWF.createCustomUi(xml,'Generate production order','center',false,nil,true,false,true)
    end
    
    simUI.setEditValue(remoteRequestUi.ui,1,remoteRequestUi.userId)
    powerPricing_comboboxItems=sim.UI_populateCombobox(remoteRequestUi.ui,5,{{'110V',1},{'220V',2}},{},remoteRequestUi.power,false,{})
    connectorType_comboboxItems=sim.UI_populateCombobox(remoteRequestUi.ui,6,{{'Phoenix',1},{'Harting',2}},{},remoteRequestUi.connector,false,{})
    lineControl_comboboxItems=sim.UI_populateCombobox(remoteRequestUi.ui,7,{{'downstream',1},{'upstream',2}},{},remoteRequestUi.lineControl,false,{})
    shipping_comboboxItems=sim.UI_populateCombobox(remoteRequestUi.ui,8,{{'land',1},{'air',2}},{},remoteRequestUi.shipping,false,{})
    destination_comboboxItems=sim.UI_populateCombobox(remoteRequestUi.ui,9,{{'Europe',1},{'Asia',2},{'USA',3}},{},remoteRequestUi.destination,false,{})
    documentation_comboboxItems=sim.UI_populateCombobox(remoteRequestUi.ui,10,{{'English',1},{'Chinese',2},{'Danish',3},{'German',4}},{},remoteRequestUi.documentation,false,{})
end

function quoteRequestDlg()
    if not quoteRequest then
        remoteRequestDlg(0)
    end
end

function roiRequestDlg()
    if not roiRequest then
        remoteRequestDlg(1)
    end
end

function sopRequestDlg()
    if not sopRequest then
        remoteRequestDlg(2)
    end
end


function userIdPricing_callback(uiHandle,id,newValue)
    remoteRequestUi.userId=newValue
    simUI.setEditValue(remoteRequestUi.ui,1,remoteRequestUi.userId)
end

function powerSupplyComboChangePricing_callback(uiHandle,id,newIndex)
    remoteRequestUi.power=powerPricing_comboboxItems[newIndex+1][1]
end

function connectorTypeComboChangePricing_callback(uiHandle,id,newIndex)
    remoteRequestUi.connector=connectorType_comboboxItems[newIndex+1][1]
end

function lineControlComboChangePricing_callback(uiHandle,id,newIndex)
    remoteRequestUi.lineControl=lineControl_comboboxItems[newIndex+1][1]
end

function shippingComboChangePricing_callback(uiHandle,id,newIndex)
    remoteRequestUi.shipping=shipping_comboboxItems[newIndex+1][1]
end

function destinationComboChangePricing_callback(uiHandle,id,newIndex)
    remoteRequestUi.destination=destination_comboboxItems[newIndex+1][1]
end

function documentationComboChangePricing_callback(uiHandle,id,newIndex)
    remoteRequestUi.documentation=documentation_comboboxItems[newIndex+1][1]
end

function cancelRequestDlg_callback()
    simUI.destroy(remoteRequestUi.ui)
    remoteRequestUi.ui=nil
end

function getSceneContentData()
    local objects={}
    objects.robots={}
    objects.visionSystems={}
    objects.conveyors={}
    local tagsAndCategories={{simBWF.RAGNAR_TAG,objects.robots},{simBWF.RAGNARVISION_TAG,objects.visionSystems},{simBWF.CONVEYOR_TAG,objects.conveyors}}
    for i=1,#tagsAndCategories,1 do
        local objs=sim.getObjectsWithTag(tagsAndCategories[i][1],true)
        for j=1,#objs,1 do
            local ob=simBWF.callCustomizationScriptFunction('ext_getItemData_pricing',objs[j])
            tagsAndCategories[i][2][#tagsAndCategories[i][2]+1]=ob
        end
    end
    objects.sceneConfig={}
    objects.sceneConfig.type='user_input'
    objects.sceneConfig.client_id=remoteRequestUi.userId
    objects.sceneConfig.projectName=sim.getStringParameter(sim.stringparam_scene_name)
    -- objects.sceneConfig.sceneSerializationNo=sim.getStringParameter(sim.stringparam_scene_unique_id)
    objects.sceneConfig.power_supply=remoteRequestUi.power
    objects.sceneConfig.connector_type=remoteRequestUi.connector
    objects.sceneConfig.conveyor_control="sensor_based"
    objects.sceneConfig.line_control=remoteRequestUi.lineControl
    objects.sceneConfig.shipping_type=remoteRequestUi.shipping
    objects.sceneConfig.shipping_destination=remoteRequestUi.destination
    objects.sceneConfig.robot_documentation=remoteRequestUi.documentation
    return objects
end

function okQuote_callback()
    simUI.destroy(remoteRequestUi.ui)
    remoteRequestUi.ui=nil
    
    local data=getSceneContentData()
    data.sceneConfig.sceneImage=getSceneScreenShot()

    quoteRequest={}
    quoteRequest.payload=json.encode(data,{indent=true})
--    quoteRequest.requestAuxConsole=sim.auxiliaryConsoleOpen('Quote request',500,4,{100,100},{800,800},nil,{1,0.95,0.95})
--    sim.auxiliaryConsolePrint(quoteRequest.requestAuxConsole,quoteRequest.payload)

    local xml =[[
            <label text="Please wait a few seconds..."  style="* {qproperty-alignment: AlignCenter; min-width: 300px; min-height: 100px;}"/>
    ]]
    quoteRequest.ui=simBWF.createCustomUi(xml,'Quote request','center',false,nil,true,false,false)
    quoteRequest.counter=3
end

function okRoi_callback()
    simUI.destroy(remoteRequestUi.ui)
    remoteRequestUi.ui=nil
    
    local data=getSceneContentData()
    for key,value in pairs(roiInfo) do
        data[key]=value
    end

    roiRequest={}
    roiRequest.payload=json.encode(data,{indent=true})
--    roiRequest.requestAuxConsole=sim.auxiliaryConsoleOpen('ROI request',500,4,{100,100},{800,800},nil,{1,0.95,0.95})
--    sim.auxiliaryConsolePrint(roiRequest.requestAuxConsole,roiRequest.payload)

    local xml =[[
            <label text="Please wait a few seconds..."  style="* {qproperty-alignment: AlignCenter; min-width: 300px; min-height: 100px;}"/>
    ]]
    roiRequest.ui=simBWF.createCustomUi(xml,'ROI request','center',false,nil,true,false,false)
    roiRequest.counter=3
end

function okSop_callback()
    simUI.destroy(remoteRequestUi.ui)
    remoteRequestUi.ui=nil
    
    local data=getSceneContentData()

    sopRequest={}
    sopRequest.payload=json.encode(data,{indent=true})
--    sopRequest.requestAuxConsole=sim.auxiliaryConsoleOpen('SOP request',500,4,{100,100},{800,800},nil,{1,0.95,0.95})
--    sim.auxiliaryConsolePrint(sopRequest.requestAuxConsole,sopRequest.payload)

    local xml =[[
            <label text="Please wait a few seconds..."  style="* {qproperty-alignment: AlignCenter; min-width: 300px; min-height: 100px;}"/>
    ]]
    sopRequest.ui=simBWF.createCustomUi(xml,'SOP request','center',false,nil,true,false,false)
    sopRequest.counter=3
end

function onCloseVariousActionDlg()
    simUI.destroy(variousActionDlgId)
    variousActionDlgId=nil
end

function variousActionDlg()
        local xml =[[
                <button text="Save configuration file" on-click="saveJsonClick_callback" style="* {min-width: 300px;}" />
                <button text="Generate quote" on-click="quoteRequestDlg" style="* {min-width: 300px;}" />
                <button text="Compute ROI" on-click="roiRequestDlg" style="* {min-width: 300px;}" />
                <button text="Generate SOP" on-click="sopRequestDlg" style="* {min-width: 300px;}" />
        ]]
        variousActionDlgId=simBWF.createCustomUi(xml,'Actions','center',true,"onCloseVariousActionDlg",true,false,true)
end

function createBrAppDlg()
    if not brAppUi then
        local xml =[[
                <button text="Action dialog" on-click="variousActionDlg" style="* {min-width: 300px;}" id="6" />
                <button text="Verify layout" on-click="verifyLayout_callback" style="* {min-width: 300px;}" id="20" />
                <button text="General properties dialog" on-click="generalPropertiesDlg_callback" style="* {min-width: 300px;}" id="21" />
                <group layout="form" flat="true">
                
                <label text="Part repository"/>
                <checkbox text="" on-change="partRepository_callback" id="11" />

                <label text="Pallet repository"/>
                <checkbox text="" on-change="palletRepository_callback" id="12" />

                <label text="Testing without plugin"/>
                <checkbox text="" on-change="testingWithoutPlugin_callback" id="8" />

                <label text="Connect when running"/>
                <checkbox text="" on-change="connectWhenRunning_callback" id="5" />

                </group>
        ]]
        brAppUi=simBWF.createCustomUi(xml,'BlueReality Settings',previousBrAppDlgPos,false,nil,false,false,false)

        refreshBrAppDlg()
    end
end

function showBrAppDlg()
    if not brAppUi then
        createBrAppDlg()
    end
end

function removeBrAppDlg()
    if brAppUi then
        local x,y=simUI.getPosition(brAppUi)
        previousBrAppDlgPos={x,y}
        simUI.destroy(brAppUi)
        brAppUi=nil
    end
end

function showOrHideBrAppUiIfNeeded()
    if sim.getInt32Parameter(sim_intparam_compilation_version)==1 then
        -- Do not show this helper dlg in BlueReality, only in V-REP PRO
        local s=sim.getObjectSelection()
        if s and #s>=1 and s[#s]==model then
            showBrAppDlg()
        else
            removeBrAppDlg()
        end
    end
end

function outputGeneralSetupMessages()
    if bwfPluginLoaded then
        local msg=""
        local data={}
        data.id=-1
        local result,msgs=simBWF.query('get_objectSetupMessages',data)
        if result=='ok' then
            for i=1,#msgs.messages,1 do
                if msg~='' then
                    msg=msg..'\n'
                end
                msg=msg..msgs[i]
            end
        end
        if #msg>0 then
            simBWF.outputMessage(msg)
        end
    end
end

function outputGeneralRuntimeMessages()
    if bwfPluginLoaded then
        local msg=""
        local data={}
        data.id=-1
        local result,msgs=simBWF.query('get_objectRuntimeMessages',data)
        if result=='ok' then
            for i=1,#msgs.messages,1 do
                if msg~='' then
                    msg=msg..'\n'
                end
                msg=msg..msgs[i]
            end
        end
        if #msg>0 then
            simBWF.outputMessage(msg)
        end
    end
end

function showOrHideModalErrorOrWarningMsg()
    if bwfPluginLoaded then
        if not lastErrorQuery then
            lastErrorQuery=sim.getSystemTimeInMs(-1)
        end
        if sim.getSystemTimeInMs(lastErrorQuery)>2000 then
            lastErrorQuery=sim.getSystemTimeInMs(-1)
            local result,data=simBWF.query('get_modalErrorDisplay',{})
            if simBWF.isInTestMode() and sim.getSimulationState()==sim.simulation_advancing_running and math.abs(sim.getSimulationTime()-10)<0.005 then
                result='ok'
                data={}
                data.errorMsg='Test error'
            end
            if result=='ok' then
                if data.errorMsg then
                    sim.msgBox(sim.msgbox_type_critical,sim.msgbox_buttons_ok,'Error',data.errorMsg)
                else
                    if data.warningMsg then
                        sim.msgBox(sim.msgbox_type_warning,sim.msgbox_buttons_ok,'Warning',data.warningMsg)
                    end
                end
            end
        end
    end
end

function sysCall_nonSimulation()
    showOrHideFloorUiIfNeeded()
    showOrHideBrAppUiIfNeeded()
    showOrHideModalErrorOrWarningMsg()
    
    -- Following is the central part where we set undo points:
    ---------------------------------
    local cnt=sim.getIntegerSignal('__brUndoPointCounter__')
    if cnt~=previousUndoPointCounter then
        undoPointStayedSameCounter=8
        previousUndoPointCounter=cnt
    end
    if undoPointStayedSameCounter>0 then
        undoPointStayedSameCounter=undoPointStayedSameCounter-1
    else
        if undoPointStayedSameCounter==0 then
            sim.announceSceneContentChange() -- to have an undo point
            undoPointStayedSameCounter=-1
        end
    end
    ---------------------------------
    
    quoteRequest_executeIfNeeded()
    roiRequest_executeIfNeeded()
    sopRequest_executeIfNeeded()
    
    local onlSw=sim.getBoolParameter(sim.boolparam_online_mode)
    if onlineSwitch~=onlSw then
        onlineSwitch=onlSw
        simBWF.announceOnlineModeChanged(onlineSwitch)
    end
end

function sysCall_sensing()
    local msgs=sim.getStringSignal('__brMessages__')
    if msgs then
        local c=readInfo()
        if sim.boolAnd32(c.bitCoded,32)>0 then
            if not messageConsole then
                messageConsole=sim.auxiliaryConsoleOpen('Messages',400,4,nil,{800,400})
            end
            sim.auxiliaryConsolePrint(messageConsole,msgs)
        end
        sim.clearStringSignal('__brMessages__')
    end
    outputGeneralRuntimeMessages()
    showOrHideModalErrorOrWarningMsg()
end

function sysCall_afterSimulation()
    if sim.getBoolParameter(sim.boolparam_online_mode) then
        stopOnline()
    else
        stopSimulation()
    end
    sim.setObjectInt32Parameter(model,sim.objintparam_visibility_layer,1)
    if messageConsole then
        sim.auxiliaryConsoleClose(messageConsole)
        messageConsole=nil
    end
    sim.clearStringSignal('__brMessages__')
end

function sysCall_beforeSimulation()
    if messageConsole then
        sim.auxiliaryConsoleClose(messageConsole)
        messageConsole=nil
    end
    outputGeneralSetupMessages()
    
    removeFloorDlg()
    removeBrAppDlg()
    sim.setObjectInt32Parameter(model,sim.objintparam_visibility_layer,0)
    if sim.getBoolParameter(sim.boolparam_online_mode) then
        startOnline()
    else
        startSimulation()
    end
end

function sysCall_beforeInstanceSwitch()
    sim.clearStringSignal('__brMessages__')
    if messageConsole then
        sim.auxiliaryConsoleClose(messageConsole)
        messageConsole=nil
    end
    removeFloorDlg()
    removeBrAppDlg()
    removeFromPluginRepresentation_brApp()
end

function sysCall_afterInstanceSwitch()
    updatePluginRepresentation_brApp()
    updatePluginRepresentation_generalProperties()
end


function createNewJob()
    -- Create new job menu bar cmd
    local oldJob=currentJob
    currentJob=sim.getStringParameter(sim.stringparam_job)
    sim.addStatusbarMessage("Created a new job with name "..currentJob.." (old job was "..oldJob..")")
end

function deleteJob()
    -- Delete current job menu bar cmd
    local oldJob=currentJob
    currentJob=sim.getStringParameter(sim.stringparam_job)
    sim.addStatusbarMessage("Deleted job "..oldJob.." then switched to job "..currentJob)
end

function renameJob()
    -- Rename job menu bar cmd
    local oldJob=currentJob
    currentJob=sim.getStringParameter(sim.stringparam_job)
    sim.addStatusbarMessage("Renamed job to "..currentJob.." (was "..oldJob..")")
end

function switchJob(jobIndex_zeroBased)
    -- Switch job menu bar cmd
    local oldJob=currentJob
    currentJob=sim.getStringParameter(sim.stringparam_job)
    sim.addStatusbarMessage("Switched to job "..currentJob..", ID: "..jobIndex_zeroBased.." (previous job was "..oldJob..")")
end

function sysCall_cleanup()
    stopOnline()
    stopSimulation()
    removeFloorDlg()
    removeBrAppDlg()
--    simBWF.announcePalletWasDestroyed(-1) -- all pallets were destroyed
--    simBWF.announcePalletsHaveBeenUpdated({})
    if sim.isHandleValid(model)==1 then
        -- The associated model might already have been destroyed (if it destroys itself in the init phase)
        removeFromPluginRepresentation_brApp()
        simBWF.writeSessionPersistentObjectData(model,"dlgPosAndSize",previousBrAppDlgPos,previousFloorDlgPos)
    end
end

function sysCall_br(brData)
    local brCallIndex=brData.brCallIndex
    if (brCallIndex==0) then
        variousActionDlg()
    end
    --[[
    if (brCallIndex==1) then
        packML_createDlg()
    end
    if (brCallIndex==6) then
        packMLState_callback()
    end
    if (brCallIndex==7) then
        simplifiedPackMLState_callback()
    end
    if (brCallIndex==8) then
        simulationTime_callback()
    end
    if (brCallIndex==9) then
        simplifiedSimulationTime_callback()
    end
    if (brCallIndex==10) then
        oee_callback()
    end
    
    if (brCallIndex==2) then
        variousActionDlg()
    end
    --]]
    if (brCallIndex==3) then
        partRepository_callback()
    end
    if (brCallIndex==4) then
        palletRepository_callback()
    end
    if (brCallIndex==5) then
        generalPropertiesDlg_callback()
    end
    if (brCallIndex==11) then
        verifyLayout_callback()
    end
    if (brCallIndex==297) then
        createNewJob()
    end
    if (brCallIndex==298) then
        deleteJob()
    end
    if (brCallIndex==299) then
        renameJob()
    end
    if (brCallIndex>=300) then
        switchJob(brCallIndex-300)
    end
end


function sysCall_init()
    if not sim.isPluginLoaded('Bwf') then
        sim.msgBox(sim.msgbox_type_warning,sim.msgbox_buttons_ok,"BWF Plugin","BWF plugin was not found.\n\nThe scene will not operate as expected")
    end
    json=require("dkjson")
    http = require("socket.http")
    ltn12 = require("ltn12")
    require("/BlueWorkforce/modelScripts/v1/resizableFloor_include")

    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    version=sim.getInt32Parameter(sim.intparam_program_version)
    revision=sim.getInt32Parameter(sim.intparam_program_revision)

    floor_e1=sim.getObjectHandle('ResizableFloor_10_50_element')
    floor_e2=sim.getObjectHandle('ResizableFloor_10_50_visibleElement')
    floorItemsHolder=sim.getObjectHandle('Floor_floorItems')
    _MODELVERSION_=1
    _CODEVERSION_=1
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    local _info=readInfo()
    simBWF.checkIfCodeAndModelMatch(model,_CODEVERSION_,_info['version'])
    writeInfo(_info)
    sim.setBoolParameter(sim.boolparam_online_mode,false)
    online=false
    onlineSwitch=nil
    simulation=false
    testingWithoutPlugin=false
    sim.setIntegerSignal('__brUndoPointCounter__',0)
    previousUndoPointCounter=0
    undoPointStayedSameCounter=-1
    previousBrAppDlgPos,previousFloorDlgPos=simBWF.readSessionPersistentObjectData(model,"dlgPosAndSize")
    local objs=sim.getObjectsWithTag(simBWF.BLUEREALITYAPP_TAG,true)
    if #objs>1 then
        sim.removeModel(model)
        sim.removeObjectFromSelection(sim.handle_all)
        objs=sim.getObjectsWithTag(simBWF.BLUEREALITYAPP_TAG,true)
        sim.addObjectToSelection(sim.handle_single,objs[1])
    else
        updatePluginRepresentation_brApp()
        updatePluginRepresentation_generalProperties()
    end
    currentJob=sim.getStringParameter(sim.stringparam_job)
end

