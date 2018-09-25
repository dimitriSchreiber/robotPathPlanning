function _removeTemplateInPlugin(partHandle)
    if bwfPluginLoaded then
        local data={}
        data.id=partHandle
        simBWF.query('object_delete',data)
    end
end

function _updateTemplateInPlugin(partHandle)
    if bwfPluginLoaded then
        local data={}
        data.id=partHandle
        data.displayName=simBWF.getPartAltName(partHandle)
        local geomData=sim.readCustomDataBlock(partHandle,simBWF.GEOMETRY_PART_TAG)
        if geomData then
            geomData=sim.unpackTable(geomData)
        end
        data.vertices=geomData.vertices
        data.indices=geomData.indices
        data.normals=geomData.normals
        simBWF.query('part_model_update',data)
        _updateTemplateSettingsInPlugin(partHandle)
    end
end

function _updateTemplateSettingsInPlugin(partHandle)
    if bwfPluginLoaded then
        local pData=simBWF.readPartInfo(partHandle)
        local data={}
        data.id=partHandle
        data.overrideGripperSettings=pData.robotInfo.overrideGripperSettings
        data.speed=pData.robotInfo.speed
        data.accel=pData.robotInfo.accel
        data.dynamics=pData.robotInfo.dynamics
        data.dwellTime=pData.robotInfo.dwellTime
        data.approachHeight=pData.robotInfo.approachHeight
        data.departHeight=pData.robotInfo.departHeight
        data.offset=pData.robotInfo.offset
        data.rounding=pData.robotInfo.rounding
        data.nullingAccuracy=pData.robotInfo.nullingAccuracy
        --data.freeModeTiming=pData.robotInfo.freeModeTiming
        --data.actionModeTiming=pData.robotInfo.actionModeTiming
        data.pickActions={}
        for i=1,#pData.robotInfo.pickActions,1 do
            local v=pData.robotInfo.pickActions[i]
            data.pickActions[i]={cmd=pData.robotInfo.actionTemplates[v.name].cmd,dt=v.dt}
        end
        data.placeActions={}
        data.relativeToBelt=pData.robotInfo.relativeToBelt
        simBWF.query('part_settings',data)
    end
end

function removeFromPluginRepresentation_partRepository()
    if bwfPluginLoaded then
        local parts=sim.getObjectsInTree(originalPartHolder,sim.handle_all,1+2)
        for i=1,#parts,1 do
            _removeTemplateInPlugin(parts[i])
        end
    end
end

function updatePluginRepresentation_partRepository()
    if bwfPluginLoaded then
        local parts=sim.getObjectsInTree(originalPartHolder,sim.handle_all,1+2)
        for i=1,#parts,1 do
            _updateTemplateInPlugin(parts[i])
        end
    end
end

function ext_announcePalletWasDestroyed(palletId)
    -- We go through all parts and adjust them if needed:
    local parts=getPartTable()
    for i=1,#parts,1 do
        local part=parts[i][2]
        local data=getPartData(part)
        if (data.palletId==palletId) or (palletId==-1) then
            data.palletId=-1
            updatePartData(part,data)
            simBWF.markUndoPoint()
        end
    end
    refreshPartRepoDlg()
end

function sysCall_afterDelete(data)
    refreshPartRepoDlg()
end

function ext_announcePalletWasRenamed()
    refreshPartRepoDlg()
end

function ext_announcePalletWasCreated()
    refreshPartRepoDlg()
end


function ext_insertPart(objectHandle)
    sim.removeObjectFromSelection(sim.handle_all,-1)
    insertPart(objectHandle)
    removePartRepoDlg()
    sim.setBoolParameter(sim.boolparam_br_partrepository,true)
    showOrHidePartRepoUiIfNeeded()
    selectedPartId=objectHandle
    refreshPartRepoDlg()
end

function getDefaultInfoForNonExistingFields(info)
    if not info['version'] then
        info['version']=_MODELVERSION_
    end
    if not info['subtype'] then
        info['subtype']='repository'
    end
end

function readInfo()
    local data=sim.readCustomDataBlock(model,simBWF.PARTREPOSITORY_TAG)
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
        sim.writeCustomDataBlock(model,simBWF.PARTREPOSITORY_TAG,sim.packTable(data))
    else
        sim.writeCustomDataBlock(model,simBWF.PARTREPOSITORY_TAG,'')
    end
end



function embedPartGeometry(partHandle)
    -- 1. Get the vertices and indices of the part (in coords. relative to the shape frame first): 
    local p=sim.getModelProperty(partHandle)
    local vertices=nil
    local indices=nil
    local normals=nil
    if sim.boolAnd32(p,sim.modelproperty_not_model)>0 then
        -- We have a shape here
        vertices,indices,normals=sim.getShapeMesh(partHandle)
    else
        -- We have a model here
        vertices={}
        indices={}
        normals={}
        local shapes=sim.getObjectsInTree(partHandle,sim.object_shape_type,0)
        for i=1,#shapes,1 do
            local r,l=sim.getObjectInt32Parameter(shapes[i],sim.objintparam_visibility_layer)
            if sim.boolAnd32(l,255)>0 then
                -- For all visible shapes, get the data..
                local v,ind,norm=sim.getShapeMesh(shapes[i])
                -- Make the vertices relative to the model...
                local m=sim.getObjectMatrix(shapes[i],partHandle)
                local mr=sim.getObjectMatrix(shapes[i],partHandle)
                mr[4]=0
                mr[8]=0
                mr[12]=0
                for j=0,(#v/3)-1,1 do
                    local pt={v[3*j+1],v[3*j+2],v[3*j+3]}
                    pt=sim.multiplyVector(m,pt)
                    v[3*j+1]=pt[1]
                    v[3*j+2]=pt[2]
                    v[3*j+3]=pt[3]
                end
                for j=0,(#norm/3)-1,1 do
                    local n={norm[3*j+1],norm[3*j+2],norm[3*j+3]}
                    n=sim.multiplyVector(mr,n)
                    norm[3*j+1]=n[1]
                    norm[3*j+2]=n[2]
                    norm[3*j+3]=n[3]
                end
                -- Append the data to the existing mesh data:
                local vOff=#vertices
                local iOff=#indices
                local iiOff=#vertices/3
                local nOff=#normals
                for j=1,#v,1 do
                    vertices[vOff+j]=v[j]
                end
                for j=1,#ind,1 do
                    indices[iOff+j]=ind[j]+iiOff
                end
                for j=1,#norm,1 do
                    normals[nOff+j]=norm[j]
                end
            end
        end
    end
    
    -- Check the vertices min/max, relative to the part frame:
    local minMaxX={0,0}
    local minMaxY={0,0}
    local minMaxZ={0,0}
    for i=0,(#vertices/3)-1,1 do
        local pt={vertices[3*i+1],vertices[3*i+2],vertices[3*i+3]}
        if i==0 then
            minMaxX[1]=pt[1]
            minMaxX[2]=pt[1]
            minMaxY[1]=pt[2]
            minMaxY[2]=pt[2]
            minMaxZ[1]=pt[3]
            minMaxZ[2]=pt[3]
        else
            if pt[1]<minMaxX[1] then minMaxX[1]=pt[1] end
            if pt[1]>minMaxX[2] then minMaxX[2]=pt[1] end
            if pt[2]<minMaxY[1] then minMaxY[1]=pt[2] end
            if pt[2]>minMaxY[2] then minMaxY[2]=pt[2] end
            if pt[3]<minMaxZ[1] then minMaxZ[1]=pt[3] end
            if pt[3]>minMaxZ[2] then minMaxZ[2]=pt[3] end
        end
    end
    
    -- 2. Write the geom's offsets relative to the shape's frame:
    local pData=simBWF.readPartInfo(partHandle)--sim.readCustomDataBlock(partHandle,simBWF.PART_TAG)
    pData.vertMinMax={minMaxX,minMaxY,minMaxZ}
    simBWF.writePartInfo(partHandle,pData)
    
    -- 3. Embed the vertices and indices into the part. But first transform the vertices to have the origin centered at the bottom center of the geometry:
    local geomData={}
    for i=0,#vertices/3-1,1 do
        vertices[3*i+1]=vertices[3*i+1]-(minMaxX[2]+minMaxX[1])/2
        vertices[3*i+2]=vertices[3*i+2]-(minMaxY[2]+minMaxY[1])/2
        vertices[3*i+3]=vertices[3*i+3]-minMaxZ[1]
    end
    geomData.vertices=vertices
    geomData.indices=indices
    geomData.normals=normals
    sim.writeCustomDataBlock(partHandle,simBWF.GEOMETRY_PART_TAG,sim.packTable(geomData))
end

function getPartTable()
    local l=sim.getObjectsInTree(originalPartHolder,sim.handle_all,1+2)
    local retL={}
    for i=1,#l,1 do
 --       print(sim.getObjectName(l[i]),sim.getObjectName(l[i]+sim.handleflag_altname),simBWF.getPartAltName(l[i]))
        retL[#retL+1]={simBWF.getPartAltName(l[i]),l[i]}
    end
    return retL
end

function doesPartWithNameExist(name)
    local l=sim.getObjectsInTree(originalPartHolder,sim.handle_all,1+2)
    local retL={}
    for i=1,#l,1 do
        if simBWF.getPartAltName(l[i])==name then
            return true
        end
    end
    return false
end

function getPartData(partHandle)
    local l=sim.getObjectsInTree(originalPartHolder,sim.handle_all,1+2)
    local retL={}
    for i=1,#l,1 do
        if l[i]==partHandle then
            local data=sim.readCustomDataBlock(partHandle,simBWF.PART_TAG)
            if data then
                data=simBWF.readPartInfo(partHandle)
                return data
            end
        end
    end
end

function updatePartData(partHandle,data)
    local l=sim.getObjectsInTree(originalPartHolder,sim.handle_all,1+2)
    local retL={}
    for i=1,#l,1 do
        if l[i]==partHandle then
            sim.writeCustomDataBlock(partHandle,simBWF.PART_TAG,sim.packTable(data))
            if bwfPluginLoaded then
--                _removeTemplateInPlugin(partHandle)
                _updateTemplateInPlugin(partHandle)
            end
            break
        end
    end
end

function removePart(partHandle)
    local l=sim.getObjectsInTree(originalPartHolder,sim.handle_all,1+2)
    local retL={}
    for i=1,#l,1 do
        if l[i]==partHandle then
            local pData=sim.readCustomDataBlock(partHandle,simBWF.PART_TAG)
            pData=sim.unpackTable(pData)
            
            -- 1. Remove its plugin representation:
            if bwfPluginLoaded then
                _removeTemplateInPlugin(partHandle)
            end

            -- 2. Remove the part:
            selectedPartId=-1
            local p=sim.getModelProperty(partHandle)
            if sim.boolAnd32(p,sim.modelproperty_not_model)>0 then
                sim.removeObject(partHandle)
            else
                sim.removeModel(partHandle)
            end
            
            simBWF.markUndoPoint()
            break
        end
    end
end

function insertPart(partHandle)
    local allNames=getAllPartNameMap()
    local data=simBWF.readPartInfo(partHandle)
    local nm=simBWF.getObjectAltName(partHandle)
    if string.find(nm,simBWF.PART_ALTNAMEPREFIX)==1 then
        nm=simBWF.getPartAltName(partHandle) -- has already the __PART__ prefix
    end
    simBWF.writePartInfo(partHandle,data)

    nm=simBWF.getValidName(nm,true)
    local cnt
    local baseNm
    baseNm,cnt=simBWF.getNameAndNumber(nm)
    if baseNm=='' then
        baseNm='_'
    end
    nm=baseNm
    cnt=0
    while true do
        if not allNames[nm] then
            break
        end
        nm=baseNm..cnt
        cnt=cnt+1
    end

    simBWF.setPartAltName(partHandle,nm)

    sim.setObjectPosition(partHandle,model,{0,0,0}) -- keep the orientation as it is

    -- Make the model static, non-respondable, non-collidable, non-measurable, non-visible, etc.
    if sim.boolAnd32(sim.getModelProperty(partHandle),sim.modelproperty_not_model)>0 then
        -- Shape
        local p=sim.boolOr32(sim.getObjectProperty(partHandle),sim.objectproperty_dontshowasinsidemodel)
        sim.setObjectProperty(partHandle,p)
    else
        -- Model
        local p=sim.boolOr32(sim.getModelProperty(partHandle),sim.modelproperty_not_showasinsidemodel)
        sim.setModelProperty(partHandle,p)
    end

    removeAssociatedCustomizationScriptIfAvailable(partHandle)
    sim.setObjectParent(partHandle,originalPartHolder,true)
    
    -- We embed into each part its geometry:
    embedPartGeometry(partHandle)
    _updateTemplateInPlugin(partHandle)
end

function populatePartRepoTable()
    local parts=getPartTable()
    local retVal={}
    simUI.clearTable(partRepoUi,10)
    simUI.setRowCount(partRepoUi,10,0)
    for i=1,#parts,1 do
        local part=parts[i]
        simUI.setRowCount(partRepoUi,10,i)
        simUI.setRowHeight(partRepoUi,10,i-1,25,25)
        simUI.setItem(partRepoUi,10,i-1,0,part[1])
        retVal[i]=part[2]
    end
    return retVal
end

function refreshPartRepoDlg()
    if partRepoUi then
        simUI.setColumnCount(partRepoUi,10,1)
        simUI.setColumnWidth(partRepoUi,10,0,310,310)
        tablePartIds=populatePartRepoTable()
        
        if selectedPartId>=0 then
            local c=getPartData(selectedPartId)
            simUI.setEditValue(partRepoUi,6,c['destination'],true)
            simUI.setCheckboxValue(partRepoUi,41,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],1)~=0),true)
            simUI.setCheckboxValue(partRepoUi,42,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],2)~=0),true)
            simUI.setCheckboxValue(partRepoUi,9,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],4)~=0),true)
            simUI.setCheckboxValue(partRepoUi,11,simBWF.getCheckboxValFromBool(sim.boolAnd32(c['bitCoded'],8)~=0),true)
            
            local pallets=simBWF.getAvailablePallets()
            local selected=simBWF.NONE_TEXT
            for i=1,#pallets,1 do
                if pallets[i][2]==simBWF.getReferencedObjectHandle(selectedPartId,simBWF.PART_PALLET_REF) then
                    selected=pallets[i][1]
                    break
                end
            end
            
            local off=c['palletOffset']
            simUI.setEditValue(partRepoUi,8,simBWF.format("%.0f , %.0f , %.0f",off[1]*1000,off[2]*1000,off[3]*1000),true)
            
            comboPallet=sim.UI_populateCombobox(partRepoUi,7,pallets,{},selected,true,{{simBWF.NONE_TEXT,-1}})
            for i=1,#tablePartIds,1 do
                if tablePartIds[i]==selectedPartId then
                    simUI.setTableSelection(partRepoUi,10,i-1,0)
                    break
                end
            end
        else
            simUI.setEditValue(partRepoUi,6,'',true)
            simUI.setCheckboxValue(partRepoUi,41,simBWF.getCheckboxValFromBool(false),true)
            simUI.setCheckboxValue(partRepoUi,42,simBWF.getCheckboxValFromBool(false),true)
            simUI.setCheckboxValue(partRepoUi,9,simBWF.getCheckboxValFromBool(false),true)
            simUI.setCheckboxValue(partRepoUi,11,simBWF.getCheckboxValFromBool(false),true)
            simUI.setComboboxItems(partRepoUi,7,{},-1,true)
            simUI.setTableSelection(partRepoUi,10,-1,-1)
            simUI.setEditValue(partRepoUi,8,"0, 0, 0",true)
        end
        
        updatePartRepoEnabledDisabledItemsDlg()
    end
end

function updatePartRepoEnabledDisabledItemsDlg()
    if partRepoUi then
        local simStopped=sim.getSimulationState()==sim.simulation_stopped
        simUI.setEnabled(partRepoUi,6,selectedPartId>=0 and simStopped,true)
        simUI.setEnabled(partRepoUi,7,selectedPartId>=0 and simStopped,true)
        local pall=false
        if selectedPartId>=0 then
            pall=simBWF.getReferencedObjectHandle(selectedPartId,simBWF.PART_PALLET_REF)>=0
        end
        simUI.setEnabled(partRepoUi,8,pall and simStopped,true)
        simUI.setEnabled(partRepoUi,9,pall and simStopped,true)
        simUI.setEnabled(partRepoUi,11,pall and simStopped,true)
        simUI.setEnabled(partRepoUi,41,selectedPartId>=0 and not pall and simStopped,true)
        simUI.setEnabled(partRepoUi,42,selectedPartId>=0 and not pall and simStopped,true)
        simUI.setEnabled(partRepoUi,43,selectedPartId>=0,true)
    end
end

function defaultDestination_callback(ui,id,newVal)
    if selectedPartId>=0 then
        local c=getPartData(selectedPartId)
        newVal=simBWF.getValidName(newVal,true,{'<','>'})
        if #newVal>0 then
            c.destination=newVal
            updatePartData(selectedPartId,c)
            simBWF.markUndoPoint()
        end
    end
    refreshPartRepoDlg()
end

function palletOffset_callback(ui,id,newVal)
    if selectedPartId>=0 then
        local c=getPartData(selectedPartId)
        
        local i=1
        local t={0,0,0}
        for token in (newVal..","):gmatch("([^,]*),") do
            t[i]=tonumber(token)
            if t[i]==nil then t[i]=0 end
            t[i]=t[i]*0.001
            if t[i]>0.2 then t[i]=0.2 end
            if t[i]<-0.2 then t[i]=-0.2 end
            i=i+1
        end
        c['palletOffset']={t[1],t[2],t[3]}
        updatePartData(selectedPartId,c)
        simBWF.markUndoPoint()
    end
    refreshPartRepoDlg()
end

function palletChange_callback(ui,id,newIndex)
    if selectedPartId>=0 then
        simBWF.setReferencedObjectHandle(selectedPartId,simBWF.PART_PALLET_REF,comboPallet[newIndex+1][2])
        local c=getPartData(selectedPartId)
        updatePartData(selectedPartId,c)
        simBWF.markUndoPoint()
    end
    refreshPartRepoDlg()
end

function invisiblePart_callback(ui,id,newVal)
    if selectedPartId>=0 then
        local c=getPartData(selectedPartId)
        c['bitCoded']=sim.boolOr32(c['bitCoded'],1)
        if newVal==0 then
            c['bitCoded']=c['bitCoded']-1
        end
        updatePartData(selectedPartId,c)
        simBWF.markUndoPoint()
    end
    refreshPartRepoDlg()
end

function invisibleToOtherParts_callback(ui,id,newVal)
    if selectedPartId>=0 then
        local c=getPartData(selectedPartId)
        c['bitCoded']=sim.boolOr32(c['bitCoded'],2)
        if newVal==0 then
            c['bitCoded']=c['bitCoded']-2
        end
        updatePartData(selectedPartId,c)
        simBWF.markUndoPoint()
    end
    refreshPartRepoDlg()
end

function ignoreBasePart_callback(ui,id,newVal)
    if selectedPartId>=0 then
        local c=getPartData(selectedPartId)
        c['bitCoded']=sim.boolOr32(c['bitCoded'],4)
        if newVal==0 then
            c['bitCoded']=c['bitCoded']-4
        end
        updatePartData(selectedPartId,c)
        simBWF.markUndoPoint()
    end
    refreshPartRepoDlg()
end

function usePalletColors_callback(ui,id,newVal)
    if selectedPartId>=0 then
        local c=getPartData(selectedPartId)
        c['bitCoded']=sim.boolOr32(c['bitCoded'],8)
        if newVal==0 then
            c['bitCoded']=c['bitCoded']-8
        end
        updatePartData(selectedPartId,c)
        simBWF.markUndoPoint()
    end
    refreshPartRepoDlg()
end

function onPartRepoCellActivate(uiHandle,id,row,column,value)
    if selectedPartId>=0 then
        local valid=false
        if #value>0 and (sim.getSimulationState()==sim.simulation_stopped) then
--            value=string.match(value,"[^ ]+")
            value=simBWF.getValidName(value,true)
            if not doesPartWithNameExist(value) then
                valid=true
                simBWF.setPartAltName(selectedPartId,value)
--                updatePartData(selectedPartId,partData)
                updatePluginRepresentation_partRepository()
            end
        end
        simUI.setItem(uiHandle,10,row,0,simBWF.getPartAltName(selectedPartId))
    end
end

function onPartRepoTableSelectionChange(uiHandle,id,row,column)
    if row>=0 then
        selectedPartId=tablePartIds[row+1]
    else
        selectedPartId=-1
    end
    refreshPartRepoDlg()
    updatePartRepoEnabledDisabledItemsDlg()
end

function onPartRepoTableKeyPress(uiHandle,id,key,text)
    if selectedPartId>=0 then
        if text:byte(1,1)==27 then
            -- esc
            selectedPartId=-1
            simUI.setTableSelection(uiHandle,10,-1,-1)
            refreshPartRepoDlg()
            updatePartRepoEnabledDisabledItemsDlg()
        end
        if text:byte(1,1)==13 then
            -- enter or return
        end
        if text:byte(1,1)==127 or text:byte(1,1)==8 then
            -- del or backspace
            if sim.getSimulationState()==sim.simulation_stopped then
                removePart(selectedPartId)
                tablePartIds=populatePartRepoTable()
                selectedPartId=-1
                refreshPartRepoDlg()
                updatePartRepoEnabledDisabledItemsDlg()
            end
        end
    end
end

function partRobotSettingsClose_cb(dlgPos)
    previousPartPickPlaceDlgPos=dlgPos
end

function partRobotSettingsApply_cb(robotInfo)
    local c=getPartData(selectedPartId)
    c.robotInfo.overrideGripperSettings=robotInfo.overrideGripperSettings
    c.robotInfo.speed=robotInfo.speed
    c.robotInfo.accel=robotInfo.accel
    c.robotInfo.dynamics=robotInfo.dynamics
    for i=1,2,1 do
        c.robotInfo.dwellTime[i]=robotInfo.dwellTime[i]
        c.robotInfo.approachHeight[i]=robotInfo.approachHeight[i]
        c.robotInfo.departHeight[i]=robotInfo.departHeight[i]
        c.robotInfo.rounding[i]=robotInfo.rounding[i]
        c.robotInfo.nullingAccuracy[i]=robotInfo.nullingAccuracy[i]
        for j=1,3,1 do
            c.robotInfo.offset[i][j]=robotInfo.offset[i][j]
        end
        --c.robotInfo.freeModeTiming[i]=robotInfo.freeModeTiming[i]
        --c.robotInfo.actionModeTiming[i]=robotInfo.actionModeTiming[i]
        c.robotInfo.relativeToBelt[i]=robotInfo.relativeToBelt[i]
    end
    c.robotInfo.actionTemplates=robotInfo.actionTemplates
    c.robotInfo.pickActions=robotInfo.pickActions
    c.robotInfo.placeActions=robotInfo.placeActions
    updatePartData(selectedPartId,c)
    simBWF.markUndoPoint()
end

function partRobotSettings_callback()
    if selectedPartId>=0 then
        local c=getPartData(selectedPartId)
        pickPlaceSettings_display(c.robotInfo,"'"..simBWF.getPartAltName(selectedPartId).."' pick settings",false,partRobotSettingsApply_cb,partRobotSettingsClose_cb,previousPartPickPlaceDlgPos)
    end
end

function createPartRepoDlg()
    if (not partRepoUi) and simBWF.canOpenPropertyDialog() then
        local xml =[[
            <table show-horizontal-header="false" autosize-horizontal-header="true" show-grid="false" selection-mode="row" editable="true" on-cell-activate="onPartRepoCellActivate" on-selection-change="onPartRepoTableSelectionChange" on-key-press="onPartRepoTableKeyPress" id="10"/>

            <group layout="form" flat="false">
                <label text="Part properties" style="* {font-weight: bold;}"/><label text=""/>
                
                <label text="Default destination"/>
                <edit on-editing-finished="defaultDestination_callback" style="* {min-width: 175px;}" id="6"/>

                <label text="Pallet"/>
                <combobox id="7" on-change="palletChange_callback"/>

                <label text="Pallet offset (X, Y, Z, in mm)"/>
                <edit on-editing-finished="palletOffset_callback" id="8"/>
                
                <label text="Ignore base part"/>
                <checkbox text="" on-change="ignoreBasePart_callback" id="9" />
                
                <label text="Use pallet colors"/>
                <checkbox text="" on-change="usePalletColors_callback" id="11" />
                
                <label text="Invisible"/>
                <checkbox text="" on-change="invisiblePart_callback" id="41" />

                <label text="Invisible to other parts"/>
                <checkbox text="" on-change="invisibleToOtherParts_callback" id="42" />
                
                <label text="Pick settings"/>
                <button text="Edit" on-click="partRobotSettings_callback" id="43" />
                
            </group>
        ]]


        partRepoUi=simBWF.createCustomUi(xml,'Part Repository',previousPartRepoDlgPos,true,'onClosePartRepo')-- modal,resizable,activate,additionalUiAttribute--]])

    
        selectedPartId=-1
        
        refreshPartRepoDlg()
    end
end

function onClosePartRepo()
    sim.setBoolParameter(sim.boolparam_br_partrepository,false)
    removePartRepoDlg()
end

function showPartRepoDlg()
    if not partRepoUi then
        createPartRepoDlg()
    end
end

function removePartRepoDlg()
    if partRepoUi then
        local x,y=simUI.getPosition(partRepoUi)
        previousPartRepoDlgPos={x,y}
        simUI.destroy(partRepoUi)
        partRepoUi=nil
    end
end

function getAllPartNameMap()
    local allNames={}
    local parts=sim.getObjectsInTree(originalPartHolder,sim.handle_all,1+2)
    for i=1,#parts,1 do
        allNames[simBWF.getPartAltName(parts[i])]=parts[i]
    end
    return allNames
end

function showOrHidePartRepoUiIfNeeded()
    if sim.getBoolParameter(sim.boolparam_br_partrepository) then
        showPartRepoDlg()
    else
        removePartRepoDlg()
    end
end

function removeAssociatedCustomizationScriptIfAvailable(h)
    local sh=sim.getCustomizationScriptAssociatedWithObject(h)
    if sh>0 then
        sim.removeScript(sh)
    end
end

function sysCall_nonSimulation()
    showOrHidePartRepoUiIfNeeded()
end

function sysCall_sensing()
    if not notFirstDuringSimulation then
        updatePartRepoEnabledDisabledItemsDlg()
        notFirstDuringSimulation=true
    end
end

function sysCall_afterSimulation()
    updatePartRepoEnabledDisabledItemsDlg()
    notFirstDuringSimulation=nil
end

function sysCall_beforeInstanceSwitch()
    removePartRepoDlg()
    removeFromPluginRepresentation_partRepository()
end

function sysCall_afterInstanceSwitch()
    updatePluginRepresentation_partRepository()
end

function sysCall_cleanup()
    removePartRepoDlg()
--    if sim.isHandleValid(model)==1 then
        -- The associated model might already have been destroyed (if it destroys itself in the init phase)
        removeFromPluginRepresentation_partRepository()
        simBWF.writeSessionPersistentObjectData(model,"dlgPosAndSize",previousPartRepoDlgPos)
--    end
end

function sysCall_init()
    require("/BlueWorkforce/modelScripts/v1/pickAndPlaceSettings_include")

    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    version=sim.getInt32Parameter(sim.intparam_program_version)
    revision=sim.getInt32Parameter(sim.intparam_program_revision)

    originalPartHolder=sim.getObjectHandle('partRepository_modelParts')
    proxSensor=sim.getObjectHandle('partRepository_sensor')
    partToEdit=-1

    MODELTEMPLATE_ID_START=10000000 -- so that we don't have any collision with 3DObject handles or with pallet handles
    _MODELVERSION_=1
    _CODEVERSION_=1
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    local _info=readInfo()
    simBWF.checkIfCodeAndModelMatch(model,_CODEVERSION_,_info['version'])
    writeInfo(_info)
    previousPartRepoDlgPos=simBWF.readSessionPersistentObjectData(model,"dlgPosAndSize")
    updatePluginRepresentation_partRepository()
--[[    
    local objs=sim.getObjectsWithTag(simBWF.PARTREPOSITORY_TAG,true)
    if #objs>1 then
        sim.removeModel(model)
        sim.removeObjectFromSelection(sim.handle_all)
        objs=sim.getObjectsWithTag(simBWF.PARTREPOSITORY_TAG,true)
        sim.addObjectToSelection(sim.handle_single,objs[1])
    else
        updatePluginRepresentation_partRepository()
        updatePluginRepresentation_palletRepository()
    end
    --]]
end
