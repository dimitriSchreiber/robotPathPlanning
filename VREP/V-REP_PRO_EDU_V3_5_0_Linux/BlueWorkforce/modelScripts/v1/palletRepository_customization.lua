function _removeFromPluginRepresentationForOnePallet(palletHandle)
    if bwfPluginLoaded then
        local data={}
        data.id=palletHandle
        simBWF.query('object_delete',data)
    end
end

function _updatePluginRepresentationForOnePallet(palletHandle)
    if bwfPluginLoaded then
        beforeSendingPalletDataToPlugin(palletHandle)
        local data=readPalletInfo(palletHandle)
--        print("********************* PALLET REPO PALLET ID",data.id)

        simBWF.query('pallet_update',data)
    end
end

function removeFromPluginRepresentation_palletRepository()
    if bwfPluginLoaded then
        local allPallets=getAllPalletHandles()
        for i=1,#allPallets,1 do
            _removeFromPluginRepresentationForOnePallet(allPallets[i])
        end
    end
end

function updatePluginRepresentation_palletRepository()
    if bwfPluginLoaded then
        local allPallets=getAllPalletHandles()
        for i=1,#allPallets,1 do
            _updatePluginRepresentationForOnePallet(allPallets[i])
        end
    end
end

function sysCall_beforeDelete(data)
    -- Check which pallet needs to be updated after object deletion (i.e. part deleted that the pallet refers to)
    palletsToUpdateAfterObjectDeletion={}
    local allPallets=getAllPalletHandles()
    for i=1,#allPallets,1 do
        local refParts=sim.getReferencedHandles(allPallets[i])
        for j=1,#refParts,1 do
            if refParts[j]>=0 and data.objectHandles[refParts[j]] then
--            print("Found")
                palletsToUpdateAfterObjectDeletion[#palletsToUpdateAfterObjectDeletion+1]=allPallets[i]
                break
            end
        end
    end
    if #palletsToUpdateAfterObjectDeletion==0 then
        palletsToUpdateAfterObjectDeletion=nil
    end
end

function sysCall_afterDelete(data)
    if palletsToUpdateAfterObjectDeletion then
        for i=1,#palletsToUpdateAfterObjectDeletion,1 do
            _updatePluginRepresentationForOnePallet(palletsToUpdateAfterObjectDeletion[i])
        end
    end
    palletsToUpdateAfterObjectDeletion=nil
end

function readPalletInfo(palletHandle)
    return sim.unpackTable(sim.readCustomDataBlock(palletHandle,simBWF.PALLET_TAG))
end

function writePalletInfo(palletHandle,data)
    sim.writeCustomDataBlock(palletHandle,simBWF.PALLET_TAG,sim.packTable(data))
end

function ext_getListOfAvailablePallets()
    local allPallets=getAllPalletHandles()
    local retList={}
    for i=1,#allPallets,1 do
        retList[#retList+1]={simBWF.getPalletAltName(allPallets[i]),allPallets[i]}
    end
    return retList
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
    local data=sim.readCustomDataBlock(model,simBWF.PALLETREPOSITORY_TAG)
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
        sim.writeCustomDataBlock(model,simBWF.PALLETREPOSITORY_TAG,sim.packTable(data))
    else
        sim.writeCustomDataBlock(model,simBWF.PALLETREPOSITORY_TAG,'')
    end
end

function removePallet(palletHandle)
    sim.removeObject(palletHandle)
    _removeFromPluginRepresentationForOnePallet(palletHandle)
    simBWF.markUndoPoint()
end

function getPalletHandle(name)
    local l=sim.getObjectsInTree(palletHolder,sim.handle_all,1+2)
    for i=1,#l,1 do
        if simBWF.getPalletAltName(l[i])==name then
            return l[i]
        end
    end
    return -1
end

function getPalletWithName(name)
    local l=sim.getObjectsInTree(palletHolder,sim.handle_all,1+2)
    for i=1,#l,1 do
        if simBWF.getPalletAltName(l[i])==name then
            return l[i]
        end
    end
    return -1
end

function getAllPalletHandles()
    return sim.getObjectsInTree(palletHolder,sim.handle_all,1+2)
end

function addNewPallet()
    local pallet
    if bwfPluginLoaded then
        local res
        res,pallet=simBWF.query('pallet_createNew')
        if res~='ok' then
            pallet=nil
        end
    end

    local name='PALLET'
    local nameNb=0
    while getPalletHandle(name..nameNb)>=0 do
        nameNb=nameNb+1
    end
    name=name..nameNb
    
    local palletDummy=sim.createDummy(0.001)
    sim.setObjectParent(palletDummy,palletHolder,true)
    sim.setObjectPosition(palletDummy,palletHolder,{0,0,0})
    sim.setObjectOrientation(palletDummy,palletHolder,{0,0,0})
    simBWF.setPalletAltName(palletDummy,name)
    
    
    if pallet then
        pallet.id=palletDummy
        pallet.name=name
    else
        -- for testing:
        pallet={}
        pallet.id=palletDummy
        pallet.name=name
        
        pallet.version=1
        pallet.yaw=0
        pallet.pitch=0
        pallet.roll=0
        pallet.acc=100
        pallet.speed=100
        pallet.tabIndex=0

        pallet.palletItemList={} -- empty array (no pallet points in a new pallet)
        
        local allParts=simBWF.getAllPartsFromPartRepository()
        for i=1,4,1 do
            pallet.palletItemList[i]={}
            pallet.palletItemList[i].id=i-1
            pallet.palletItemList[i].version=1
            local theModel=-1
            if #allParts>0 then
                theModel=allParts[1][2]
            end
            pallet.palletItemList[i].model=theModel
            if i==1 or i==3 then
                pallet.palletItemList[i].colorR=1
                pallet.palletItemList[i].locationX=-0.07
            else
                pallet.palletItemList[i].colorR=0.3
                pallet.palletItemList[i].locationX=0.07
            end
            if i==1 or i==2 then
                pallet.palletItemList[i].colorG=0.8
                pallet.palletItemList[i].colorB=0
                pallet.palletItemList[i].locationY=-0.07
            else
                pallet.palletItemList[i].colorG=0
                pallet.palletItemList[i].colorB=0.8
                pallet.palletItemList[i].locationY=0.07
            end
            pallet.palletItemList[i].locationZ=0
            pallet.palletItemList[i].orientationY=0
            pallet.palletItemList[i].orientationP=0
            pallet.palletItemList[i].orientationR=0
        end
        
        pallet.retangularorigoX=0
        pallet.retangularorigoY=0
        pallet.retangularorigoZ=0
        pallet.retangulariRows=1
        pallet.retangulariColumns=1
        pallet.retangulariLayers=1
        pallet.retangularfRowStep=0.1
        pallet.retangularfColumnStep=0.1
        pallet.retangularfLayerStep=0.1

        pallet.honeycomborigoX=0
        pallet.honeycomborigoY=0
        pallet.honeycomborigoZ=0
        pallet.honeycombiRows=1
        pallet.honeycombiColumns=1
        pallet.honeycombiLayers=1
        pallet.honeycombfRowStep=0.1
        pallet.honeycombfColumnStep=0.1
        pallet.honeycombfLayerStep=0.1
        pallet.honeycomboddFirstRow=false

        pallet.circleorigoX=0
        pallet.circleorigoY=0
        pallet.circleorigoZ=0
        pallet.circlefRadius=0
        pallet.circlefAngleOffset=0
        pallet.circleiCircumferenceObjects=1
        pallet.circleiLayers=1
        pallet.circlefLayerStep=0
        pallet.circleitemInCenter=true
    end
    
    writePalletInfo(palletDummy,pallet)
    
    afterReceivingPalletDataFromPlugin(palletDummy)
    _updatePluginRepresentationForOnePallet(palletDummy)
    return palletDummy,name
end

function afterReceivingPalletDataFromPlugin(palletHandle)
    -- We store the pallet item models as referenced objects instead:
    local pallet=readPalletInfo(palletHandle)
    pallet.id=palletHandle
    writePalletInfo(palletHandle,pallet)
    local refParts={}
    for i=1,#pallet.palletItemList,1 do
        local partId=pallet.palletItemList[i].model
        if partId<0 then
            partId=-1
        end
        refParts[i]=partId
    end
    sim.setReferencedHandles(palletHandle,refParts)
end

function beforeSendingPalletDataToPlugin(palletHandle)
    local pallet=readPalletInfo(palletHandle)
    local refParts=sim.getReferencedHandles(palletHandle)
    for i=1,#pallet.palletItemList,1 do
        if i<=#refParts then
            pallet.palletItemList[i].model=refParts[i]
        end
    end
    pallet.id=palletHandle
    writePalletInfo(palletHandle,pallet)
end

function duplicatePallet(palletHandle)
    local palTable=sim.copyPasteObjects({palletHandle},0)
    local palletDuplicate=palTable[1]
    sim.setObjectParent(palletDuplicate,palletHolder,true)
    afterReceivingPalletDataFromPlugin(palletDuplicate) -- The plugin didn't send anything. But we want to use the same part references as the original pallet
    local data=readPalletInfo(palletDuplicate)
    data.id=palletDuplicate
    data.name=simBWF.getPalletAltName(palletDuplicate)
    writePalletInfo(palletDuplicate,data)
    _updatePluginRepresentationForOnePallet(palletDuplicate)
    return palletDuplicate,data.name
end

function populatePalletRepoTable()
    local retVal={}
    local allPallets=getAllPalletHandles()
    simUI.clearTable(palletRepoUi,10)
    simUI.setRowCount(palletRepoUi,10,0)
    for i=1,#allPallets,1 do
        local pallet=allPallets[i]
        simUI.setRowCount(palletRepoUi,10,i)
        simUI.setRowHeight(palletRepoUi,10,i-1,25,25)
        simUI.setItem(palletRepoUi,10,i-1,0,simBWF.getPalletAltName(pallet))
        retVal[i]=pallet
    end
    return retVal
end

function refreshPalletRepoDlg()
    if palletRepoUi then
        local sel=simBWF.getSelectedEditWidget(palletRepoUi)
        
        simUI.setColumnCount(palletRepoUi,10,1)
        simUI.setColumnWidth(palletRepoUi,10,0,310,310)
        
        tablePalletHandles=populatePalletRepoTable()
        
        updatePalletRepoEnabledDisabledItemsDlg()
        
        simBWF.setSelectedEditWidget(palletRepoUi,sel)
        
        updatePalletRepoEnabledDisabledItemsDlg()
    end
end

function updatePalletRepoEnabledDisabledItemsDlg()
    if palletRepoUi then
        local simStopped=sim.getSimulationState()==sim.simulation_stopped
        
        simUI.setEnabled(palletRepoUi,1,simStopped,true)
        simUI.setEnabled(palletRepoUi,2,bwfPluginLoaded and selectedPalletHandle>=0,true)
        simUI.setEnabled(palletRepoUi,3,simStopped and selectedPalletHandle>=0,true)
    end
end

function addNewPalletClick_callback()
    local rc=simUI.getRowCount(palletRepoUi,10)
    simUI.setRowCount(palletRepoUi,10,rc+1)
    simUI.setRowHeight(palletRepoUi,10,rc,25,25)
    local palletHandle,name=addNewPallet()
    simUI.setItem(palletRepoUi,10,rc,0,name)
    tablePalletHandles[rc+1]=palletHandle
    simUI.setTableSelection(palletRepoUi,10,rc,0)
    selectedPalletHandle=palletHandle
    updatePalletRepoEnabledDisabledItemsDlg()
    simBWF.announcePalletWasCreated()
end

function onRejectPalletEdit()
    sim.auxFunc('enableRendering')
end

function onAcceptPalletEdit(arg1)
    sim.auxFunc('enableRendering')
    writePalletInfo(selectedPalletHandle,arg1)
    afterReceivingPalletDataFromPlugin(selectedPalletHandle)
    _updatePluginRepresentationForOnePallet(selectedPalletHandle)
end

function editPalletClick_callback()
    if bwfPluginLoaded and selectedPalletHandle>=0 then
        beforeSendingPalletDataToPlugin(selectedPalletHandle)
        local palletData=readPalletInfo(selectedPalletHandle)
        local data={}
        data.pallet=palletData
        data.onReject='onRejectPalletEdit'
        data.onAccept='onAcceptPalletEdit'
        sim.auxFunc('disableRendering')
        local reply=simBWF.query('pallet_edit',data)
        if reply~='ok' then
            sim.auxFunc('enableRendering')
        end
    end
    updatePalletRepoEnabledDisabledItemsDlg()
end

function duplicatePalletClick_callback()
    if selectedPalletHandle>=0 then
        local name
        selectedPalletHandle,name=duplicatePallet(selectedPalletHandle)
        local rc=simUI.getRowCount(palletRepoUi,10)
        simUI.setRowCount(palletRepoUi,10,rc+1)
        simUI.setRowHeight(palletRepoUi,10,rc,25,25)
        simUI.setItem(palletRepoUi,10,rc,0,name)
        tablePalletHandles[rc+1]=selectedPalletHandle
        simUI.setTableSelection(palletRepoUi,10,rc,0)
    end
    updatePalletRepoEnabledDisabledItemsDlg()
    simBWF.announcePalletWasCreated()
end

function onPalletRepoDlgCellActivate(uiHandle,id,row,column,value)
    if selectedPalletHandle>=0 then
        local valid=false
        if #value>0 then
            value=simBWF.getValidName(value,true)
            if getPalletWithName(value)==-1 then
                valid=true
                simBWF.setPalletAltName(selectedPalletHandle,value)
                value=simBWF.getPalletAltName(selectedPalletHandle)
                local data=readPalletInfo(selectedPalletHandle)
                data.name=value
                writePalletInfo(selectedPalletHandle,data)
                _updatePluginRepresentationForOnePallet(selectedPalletHandle)
                simUI.setItem(palletRepoUi,10,row,0,value)
                simBWF.announcePalletWasRenamed(selectedPalletHandle)
            end
        end
        if not valid then
            value=simBWF.getPalletAltName(selectedPalletHandle)
            simUI.setItem(palletRepoUi,10,row,0,value)
        end
    end
end

function onPalletRepoDlgTableSelectionChange(uiHandle,id,row,column)
    if row>=0 then
        selectedPalletHandle=tablePalletHandles[row+1]
    else
        selectedPalletHandle=-1
    end
    updatePalletRepoEnabledDisabledItemsDlg()
end

function onPalletRepoDlgTableKeyPress(uiHandle,id,key,text)
    if selectedPalletHandle>=0 then
        if text:byte(1,1)==27 then
            -- esc
            selectedPalletHandle=-1
            simUI.setTableSelection(palletRepoUi,10,-1,-1)
            updatePalletRepoEnabledDisabledItemsDlg()
        end
        if text:byte(1,1)==13 then
            -- enter or return
        end
        if text:byte(1,1)==127 or text:byte(1,1)==8 then
            -- del or backspace
            if sim.getSimulationState()==sim.simulation_stopped then
                removePallet(selectedPalletHandle)
                tablePalletHandles=populatePalletRepoTable()
                selectedPalletHandle=-1
                updatePalletRepoEnabledDisabledItemsDlg()
            end
        end
    end
end

function createPalletRepoDlg()
    if (not palletRepoUi) and simBWF.canOpenPropertyDialog() then
        local xml =[[

            <table show-horizontal-header="false" autosize-horizontal-header="true" show-grid="false" selection-mode="row" editable="true" on-cell-activate="onPalletRepoDlgCellActivate" on-selection-change="onPalletRepoDlgTableSelectionChange" on-key-press="onPalletRepoDlgTableKeyPress" id="10"/>
            <button text="Add new pallet" style="* {min-width: 300px;}" on-click="addNewPalletClick_callback" id="1" />
            <button text="Edit selected pallet" style="* {min-width: 300px;}" on-click="editPalletClick_callback" id="2" />
            <button text="Duplicate selected pallet" style="* {min-width: 300px;}" on-click="duplicatePalletClick_callback" id="3" />

            ]]
--            <button text="Edit pallets"  style="* {min-width: 300px;}" on-click="editPalletsClick_callback" id="99" />
--            <button text="Delete selected pallet" style="* {min-width: 300px;}" on-click="deleteClick_callback" id="4" />


        palletRepoUi=simBWF.createCustomUi(xml,'Pallet Repository',previousPalletRepoDlgPos,true,'onClosePalletRepo')

        selectedPalletHandle=-1
        
        refreshPalletRepoDlg()
        
    end
end

function onClosePalletRepo()
    sim.setBoolParameter(sim.boolparam_br_palletrepository,false)
    removePalletRepoDlg()
end

function showPalletRepoDlg()
    if not palletRepoUi then
        createPalletRepoDlg()
    end
end

function removePalletRepoDlg()
    if palletRepoUi then
        local x,y=simUI.getPosition(palletRepoUi)
        previousPalletRepoDlgPos={x,y}
        simUI.destroy(palletRepoUi)
        palletRepoUi=nil
    end
end

function showOrHidePalletRepoUiIfNeeded()
    if sim.getBoolParameter(sim.boolparam_br_palletrepository) then
        showPalletRepoDlg()
    else
        removePalletRepoDlg()
    end
end

function sysCall_nonSimulation()
    showOrHidePalletRepoUiIfNeeded()
end

function sysCall_sensing()
    if not notFirstDuringSimulation then
        updatePalletRepoEnabledDisabledItemsDlg()
        notFirstDuringSimulation=true
    end
end

function sysCall_afterSimulation()
    updatePalletRepoEnabledDisabledItemsDlg()
    notFirstDuringSimulation=nil
end

function sysCall_beforeInstanceSwitch()
    removePalletRepoDlg()
    removeFromPluginRepresentation_palletRepository()
end

function sysCall_afterInstanceSwitch()
    updatePluginRepresentation_palletRepository()
end

function sysCall_cleanup()
    removePalletRepoDlg()
--    if sim.isHandleValid(model)==1 then
        -- The associated model might already have been destroyed (if it destroys itself in the init phase)
        removeFromPluginRepresentation_palletRepository()
        simBWF.writeSessionPersistentObjectData(model,"dlgPosAndSize",previousPalletRepoDlgPos)
--    end
end

function sysCall_init()
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    version=sim.getInt32Parameter(sim.intparam_program_version)
    revision=sim.getInt32Parameter(sim.intparam_program_revision)

    palletHolder=model

    PALLET_ID_START=20000000 -- was 0 before (and pallets deleted with 'pallet_delete'). Now we have a pseudo scene object deleted with 'object_delete'
    _MODELVERSION_=1
    _CODEVERSION_=1
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    local _info=readInfo()
    simBWF.checkIfCodeAndModelMatch(model,_CODEVERSION_,_info['version'])
    writeInfo(_info)
    previousPalletRepoDlgPos=simBWF.readSessionPersistentObjectData(model,"dlgPosAndSize")
    updatePluginRepresentation_palletRepository()
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
