require('utils')

local simBWF={}

function simBWF.modifyPartDeactivationTime(currentDeactivationTime)
    local objs=sim.getObjectsInTree(sim.handle_scene,sim.handle_all)
    for i=1,#objs,1 do
        local dat=sim.readCustomDataBlock(objs[i],simBWF.OLDOVERRIDE_TAG)
        if dat then
            dat=sim.unpackTable(dat)
            if sim.boolAnd32(dat['bitCoded'],4)>0 then
                return dat['deactivationTime']
            end
            break
        end
    end
    return currentDeactivationTime
end

function simBWF.modifyAuxVisualizationItems(visualize)
    local objs=sim.getObjectsInTree(sim.handle_scene,sim.handle_all)
    for i=1,#objs,1 do
        local dat=sim.readCustomDataBlock(objs[i],simBWF.OLDOVERRIDE_TAG)
        if dat then
            dat=sim.unpackTable(dat)
            local v=sim.boolAnd32(dat['bitCoded'],1+2)
            if v>0 then
                if v==1 then return false end
                if v==2 then return true end
            end
            break
        end
    end
    return visualize
end

function simBWF.canOpenPropertyDialog(modelHandle)
    local objs=sim.getObjectsInTree(sim.handle_scene,sim.handle_all)
    for i=1,#objs,1 do
        local dat=sim.readCustomDataBlock(objs[i],simBWF.OLDOVERRIDE_TAG)
        if dat then
            dat=sim.unpackTable(dat)
            local v=sim.boolAnd32(dat['bitCoded'],16)
            if v>0 then
  --              sim.addStatusbarMessage("\nInfo: property dialog won't open, since it was disabled in the settings control center.\n")
            end
            return (v==0)
        end
    end
    return true
end

function simBWF.createOpenBox(size,baseThickness,wallThickness,density,inertiaCorrectionFact,static,respondable,color)
    local parts={}
    local dim={size[1],size[2],baseThickness}
    parts[1]=sim.createPureShape(0,16,dim,density*dim[1]*dim[2]*dim[3])
    sim.setObjectPosition(parts[1],-1,{0,0,baseThickness*0.5})
    dim={wallThickness,size[2],size[3]-baseThickness}
    parts[2]=sim.createPureShape(0,16,dim,density*dim[1]*dim[2]*dim[3])
    sim.setObjectPosition(parts[2],-1,{(size[1]-wallThickness)*0.5,0,baseThickness+dim[3]*0.5})
    parts[3]=sim.createPureShape(0,16,dim,density*dim[1]*dim[2]*dim[3])
    sim.setObjectPosition(parts[3],-1,{(-size[1]+wallThickness)*0.5,0,baseThickness+dim[3]*0.5})
    dim={size[1]-2*wallThickness,wallThickness,size[3]-baseThickness}
    parts[4]=sim.createPureShape(0,16,dim,density*dim[1]*dim[2]*dim[3])
    sim.setObjectPosition(parts[4],-1,{0,(size[2]-wallThickness)*0.5,baseThickness+dim[3]*0.5})
    parts[5]=sim.createPureShape(0,16,dim,density*dim[1]*dim[2]*dim[3])
    sim.setObjectPosition(parts[5],-1,{0,(-size[2]+wallThickness)*0.5,baseThickness+dim[3]*0.5})
    for i=1,#parts,1 do
        sim.setShapeColor(parts[i],'',sim.colorcomponent_ambient_diffuse,color)
    end
    local shape=sim.groupShapes(parts)
    if math.abs(1-inertiaCorrectionFact)>0.001 then
        local transf=sim.getObjectMatrix(shape,-1)
        local m0,i0,com0=sim.getShapeMassAndInertia(shape,transf)
        for i=1,#i0,1 do
            i0[i]=i0[1]*inertiaCorrectionFact
        end
        sim.setShapeMassAndInertia(shape,m0,i0,com0,transf)
    end
    if static then
        sim.setObjectInt32Parameter(shape,sim.shapeintparam_static,1)
    else
        sim.setObjectInt32Parameter(shape,sim.shapeintparam_static,0)
    end
    if respondable then
        sim.setObjectInt32Parameter(shape,sim.shapeintparam_respondable,1)
    else
        sim.setObjectInt32Parameter(shape,sim.shapeintparam_respondable,0)
    end
    sim.reorientShapeBoundingBox(shape,-1)
    return shape
end

function simBWF.getOneRawPalletItem()
    local decItem={}
    decItem['pos']={0,0,0}
    decItem['orient']={0,0,0}
    decItem['processingStage']=0
    decItem['ser']=0
    decItem['layer']=1
    return decItem
end

function simBWF.getSinglePalletPoint(optionalGlobalOffset)
    if not optionalGlobalOffset then
        optionalGlobalOffset={0,0,0}    
    end
    local decItem=simBWF.getOneRawPalletItem()
    decItem['pos']={optionalGlobalOffset[1],optionalGlobalOffset[2],optionalGlobalOffset[3]}
    return {decItem}
end

function simBWF.getCircularPalletPoints(radius,count,angleOffset,center,layers,layerStep,optionalGlobalOffset)
    local retVal={}
    if not optionalGlobalOffset then
        optionalGlobalOffset={0,0,0}    
    end
    local da=2*math.pi/count
    for j=1,layers,1 do
        for i=0,count-1,1 do
            local decItem=simBWF.getOneRawPalletItem()
            local relP={optionalGlobalOffset[1]+radius*math.cos(da*i+angleOffset),optionalGlobalOffset[2]+radius*math.sin(da*i+angleOffset),optionalGlobalOffset[3]+(j-1)*layerStep}
            decItem['pos']=relP
            decItem['ser']=#retVal
            decItem['layer']=j
            retVal[#retVal+1]=decItem
        end
        if center then -- the center point
            local decItem=simBWF.getOneRawPalletItem()
            local relP={optionalGlobalOffset[1],optionalGlobalOffset[2],optionalGlobalOffset[3]+(j-1)*layerStep}
            decItem['pos']=relP
            decItem['ser']=#retVal
            decItem['layer']=j
            retVal[#retVal+1]=decItem
        end
    end
    return retVal
end

function simBWF.getLinePalletPoints(rows,rowStep,cols,colStep,layers,layerStep,pointsAreCentered,optionalGlobalOffset)
    local retVal={}
    local goff={0,0,0}
    if optionalGlobalOffset then
        goff={optionalGlobalOffset[1],optionalGlobalOffset[2],optionalGlobalOffset[3]}
    end
    if pointsAreCentered then
        goff[1]=goff[1]-(rows-1)*rowStep*0.5
        goff[2]=goff[2]-(cols-1)*colStep*0.5
    end
    for k=1,layers,1 do
        for j=1,cols,1 do
            for i=1,rows,1 do
                local decItem=simBWF.getOneRawPalletItem()
                local relP={goff[1]+(i-1)*rowStep,goff[2]+(j-1)*colStep,goff[3]+(k-1)*layerStep}
                decItem['pos']=relP
                decItem['ser']=#retVal
                decItem['layer']=k
                retVal[#retVal+1]=decItem
            end
        end
    end
    return retVal
end

function simBWF.getHoneycombPalletPoints(rows,rowStep,cols,colStep,layers,layerStep,firstRowIsOdd,pointsAreCentered,optionalGlobalOffset)
    local retVal={}
    local goff={0,0,0}
    if optionalGlobalOffset then
        goff={optionalGlobalOffset[1],optionalGlobalOffset[2],optionalGlobalOffset[3]}
    end
    local rowSize={rows,rows-1}
    if sim.boolAnd32(rows,1)==0 then
        -- max row is even
        if firstRowIsOdd then
            rowSize={rows-1,rows}
        end
    else
        -- max row is odd
        if not firstRowIsOdd then
            rowSize={rows-1,rows}
        end
    end
    local colOff=-(cols-1)*colStep*0.5
    local rowOffs={-(rowSize[1]-1)*rowStep*0.5,-(rowSize[2]-1)*rowStep*0.5}

    if not pointsAreCentered then
        goff[1]=goff[1]+(rowSize[1]-1)*rowStep*0.5
        goff[2]=goff[2]+(cols-1)*colStep*0.5
    end

    for k=1,layers,1 do
        for j=1,cols,1 do
            local r=rowSize[1+sim.boolAnd32(j-1,1)]
            for i=1,r,1 do
                local rowOff=rowOffs[1+sim.boolAnd32(j-1,1)]
                local decItem=simBWF.getOneRawPalletItem()
                local relP={goff[1]+rowOff+(i-1)*rowStep,goff[2]+colOff+(j-1)*colStep,goff[3]+(k-1)*layerStep}
                decItem['pos']=relP
                decItem['ser']=#retVal
                decItem['layer']=k
                retVal[#retVal+1]=decItem
            end
        end
    end
    return retVal
end

function simBWF.generatePalletPoints(objectData)
    local isCentered=true
    local allItems={}
    local tp=objectData['palletPattern']
    if tp and tp>0 then
        if tp==1 then -- single
            local d=objectData['singlePatternData']
            allItems=simBWF.getSinglePalletPoint(d)
        end
        if tp==2 then -- circular
            local d=objectData['circularPatternData3']
            local off=d[1]
            local radius=d[2]
            local cnt=d[3]
            local angleOff=d[4]
            local center=d[5]
            local layers=d[6]
            local layersStep=d[7]
            allItems=simBWF.getCircularPalletPoints(radius,cnt,angleOff,center,layers,layersStep,off)
        end
        if tp==3 then -- rectangular
            local d=objectData['linePatternData']
            local off=d[1]
            local rows=d[2]
            local rowStep=d[3]
            local cols=d[4]
            local colStep=d[5]
            local layers=d[6]
            local layersStep=d[7]
            allItems=simBWF.getLinePalletPoints(rows,rowStep,cols,colStep,layers,layersStep,isCentered,off)
        end
        if tp==4 then -- honeycomb
            local d=objectData['honeycombPatternData']
            local off=d[1]
            local rows=d[2]
            local rowStep=d[3]
            local cols=d[4]
            local colStep=d[5]
            local layers=d[6]
            local layersStep=d[7]
            local firstRowIsOdd=d[8]
            allItems=simBWF.getHoneycombPalletPoints(rows,rowStep,cols,colStep,layers,layersStep,firstRowIsOdd,isCentered,off)
        end
        if tp==5 then -- custom/imported
            allItems=objectData['palletPoints'] -- leave it as it is
        end
    end
    return allItems
end

function simBWF._getPartDefaultInfoForNonExistingFieldsV0(info)
    info['labelInfo']=nil -- not used anymore
    info['weightDistribution']=nil -- not supported anymore (now part of the feeder distribution algo)
    if not info['version'] then
        info['version']=0
    end
    if not info['name'] then
        info['name']='<partName>'
    end
    if not info['destination'] then
        info['destination']='<defaultDestination>'
    end
    if not info['bitCoded'] then
        info['bitCoded']=0 -- 1=invisible, 2=non-respondable to other parts
    end
    if not info['palletPattern'] then
        info['palletPattern']=0 -- 0=none, 1=single, 2=circular, 3=line (rectangle), 4=honeycomb, 5=custom/imported
    end
    if not info['circularPatternData3'] then
        info['circularPatternData3']={{0,0,0},0.1,6,0,true,1,0.05} -- offset, radius, count,angleOffset, center, layers, layers step
    end
    if not info['customPatternData'] then
        info['customPatternData']=''
    end
    if not info['linePatternData'] then
        info['linePatternData']={{0,0,0},3,0.03,3,0.03,1,0.05} -- offset, rowCnt, rowStep, colCnt, colStep, layers, layers step
    end
    if not info['honeycombPatternData'] then
        info['honeycombPatternData']={{0,0,0},3,0.03,3,0.03,1,0.05,false} -- offset, rowCnt, rowStep, colCnt, colStep, layers, layers step, firstRowOdd
    end
    if not info['palletPoints'] then
        info['palletPoints']={}
    end
end

function simBWF.readPartInfoV0(handle)
    local data=sim.readCustomDataBlock(handle,simBWF.PART_TAG)
    if data then
        data=sim.unpackTable(data)
    else
        data={}
    end
    simBWF._getPartDefaultInfoForNonExistingFieldsV0(data)
    return data
end

function simBWF._getPartDefaultInfoForNonExistingFields(info)
    -- Following few not supported anymore with V1
    info['labelInfo']=nil
    info['weightDistribution']=nil
    info['palletPattern']=nil
    info['circularPatternData3']=nil
    info['customPatternData']=nil
    info['linePatternData']=nil
    info['honeycombPatternData']=nil
    info['palletPoints']=nil
    info['name']=nil
    info['palletId']=nil
    
    -- palletId is stored in the object referenced IDs
    if not info['vertMinMax'] then
        info['vertMinMax']={{0,0},{0,0},{0,0}}
    end
    if not info['version'] then
        info['version']=1
    end
    if not info['destination'] then
        info['destination']='<defaultDestination>'
    end
    if not info['bitCoded'] then
        info['bitCoded']=0 -- 1=invisible, 2=non-respondable to other parts, 4=ignore base object (if associated with pallet), 8=use pallet colors
    end
    if not info['palletOffset'] then
        info['palletOffset']={0,0,0}
    end
    
    -- Following name (robotInfo) is not very good. It groups part pick/place settings. Place settings are ignored (since they are taken from the gripper of the pallet)
    if not info['robotInfo'] then
        info['robotInfo']={}
    end
    simBWF._getPickPlaceSettingsDefaultInfoForNonExistingFields(info.robotInfo)
end

function simBWF._getPickPlaceSettingsDefaultInfoForNonExistingFields(info)
    if not info.overrideGripperSettings then
        info.overrideGripperSettings=false -- by default, we use the gripper settings
    end
    if not info.speed then
        info.speed=1 -- in %
    end
    if not info.accel then
        info.accel=1 -- in %
    end
    if not info.dynamics then
        info.dynamics=1 -- in %
    end
    if not info.dwellTime then
        info.dwellTime={0.1,0.1}
    end
    if not info.approachHeight then
        info.approachHeight={0.1,0.1}
    end
    if not info.departHeight then
        info.departHeight={0.1,0.1}
    end
    if not info.offset then
        info.offset={{0,0,0},{0,0,0}}
    end
    if not info.rounding then
        info.rounding={0.05,0.05}
    end
    if not info.nullingAccuracy then
        info.nullingAccuracy={0.005,0.005}
    end
    if not info.actionTemplates then
        info.actionTemplates={release={cmd="M800M810"},activePick={cmd="M801M810"},activePlace={cmd="M800M811"}}
    end
    if not info.pickActions then
        info.pickActions={{name="release",dt=0},{name="activePick",dt=0.01}}
    end
    if not info.placeActions then
        info.placeActions={{name="activePlace",dt=0},{name="release",dt=0.01}}
    end
    if not info.relativeToBelt then
        info.relativeToBelt={false,false} -- makes only sensor for pick. No meaning (for now) for place
    end
    -- Following not supported anymore:
    info.freeModeTiming=nil
    info.actionModeTiming=nil
end

function simBWF.readPartInfo(handle)
    local data=sim.readCustomDataBlock(handle,simBWF.PART_TAG)
    if data then
        data=sim.unpackTable(data)
    else
        data={}
    end
    simBWF._getPartDefaultInfoForNonExistingFields(data)
    return data
end

function simBWF.writePartInfo(handle,data)
    if data then
        sim.writeCustomDataBlock(handle,simBWF.PART_TAG,sim.packTable(data))
    else
        sim.writeCustomDataBlock(handle,simBWF.PART_TAG,'')
    end
end

function simBWF.palletPointsToString(palletPoints)
    local txt=""
    for i=1,#palletPoints,1 do
        local pt=palletPoints[i]
        if i~=1 then
            txt=txt..",\n"
        end
        txt=txt.."{{"..pt['pos'][1]..","..pt['pos'][2]..","..pt['pos'][3].."},"
        txt=txt.."{"..pt['orient'][1]..","..pt['orient'][2]..","..pt['orient'][3].."},"
        txt=txt..pt['layer'].."}"
    end
    return txt
end

function simBWF.stringToPalletPoints(txt)
    local palletPoints=nil
    local arr=stringToArray(txt)
    if arr then
        palletPoints={}
        for i=1,#arr,1 do
            local item=arr[i]
            if type(item)~='table' then return end
            if #item<3 then return end
            local pos=item[1]
            local orient=item[2]
            local layer=item[3]
            if type(pos)~='table' or #pos<3 then return end
            if type(orient)~='table' or #orient<3 then return end
            for j=1,3,1 do
                if type(pos[j])~='number' then return end
                if type(orient[j])~='number' then return end
            end
            if type(layer)~='number' then return end
            local decItem=simBWF.getOneRawPalletItem()
            decItem['pos']=pos
            decItem['orient']=orient
            decItem['ser']=#palletPoints
            decItem['layer']=layer
            palletPoints[#palletPoints+1]=decItem
        end
    end
    return palletPoints
end

function simBWF.arePalletPointsSame_posOrientAndLayer(pall1,pall2)
    if #pall1~=pall2 then return false end
    local distToll=0.0001*0.0001
    local orToll=0.05*math.pi/180
    orToll=orToll*orToll
    for i=1,#pall1,1 do
        local p1=pall1[i]
        local p2=pall2[i]
        if p1['layer']~=p2['layer'] then return false end
        local pos1=p1['pos']
        local pos2=p2['pos']
        local dx={pos1[1]-pos2[1],pos1[2]-pos2[2],pos1[3]-pos2[3]}
        local ll=dx[1]*dx[1]+dx[2]*dx[2]+dx[3]*dx[3]
        if ll>distToll then return false end
        pos1=p1['orient']
        pos2=p2['orient']
        dx={pos1[1]-pos2[1],pos1[2]-pos2[2],pos1[3]-pos2[3]}
        ll=dx[1]*dx[1]+dx[2]*dx[2]+dx[3]*dx[3]
        if ll>orToll then return false end
    end
    return true
end

function simBWF.readPalletFromFile(file)
    local json=require('dkjson')
    local file="d:/v_rep/qrelease/release/palletTest.txt"
    local f = io.open(file,"rb")
    local retVal=nil
    if f then
        f:close()
        local jsonData=''
        for line in io.lines(file) do
            jsonData=jsonData..line
        end
        jsonData='{ '..jsonData..' }'
        local obj,pos,err=json.decode(jsonData,1,nil)
        if type(obj)=='table' then
            if type(obj.frames)=='table'  then
                for j=1,#obj.frames,1 do
                    local fr=obj.frames[j]
                    if fr.rawPallet then
                        local palletItemList=fr.rawPallet.palletItemList
                        if palletItemList then
                            retVal={}
                            for itmN=1,#palletItemList,1 do
                                local item=palletItemList[itmN]
                                local decItem=simBWF.getOneRawPalletItem()
                                decItem['pos']={item.location.x*0.001,item.location.y*0.001,item.location.z*0.001}
                                decItem['orient']={item.roll,item.pitch,item.yaw}
                                decItem['ser']=#retVal
                                retVal[#retVal+1]=decItem
                            end
                            break
                        end
                    end
                end
            end
        end
    end
    return retVal
end

function simBWF.getPartRepositoryHandles()
    local repoP=getObjectsWithTag(simBWF.OLDPARTREPO_TAG,true) -- to support BR version 0
    if #repoP==0 then
        repoP=getObjectsWithTag(simBWF.PARTREPOSITORY_TAG,true) 
    end
    if #repoP==0 then
        repoP=getObjectsWithTag(simBWF.BLUEREALITYAPP_TAG,true) -- for temp. transition
    end
    
    if #repoP==1 then
        local repo=repoP[1]
        local suff=sim.getNameSuffix(sim.getObjectName(repo))
        local nm='partRepository_modelParts'
        if suff>=0 then
            nm=nm..'#'..suff
        end
        local partHolder=getObjectHandle_noErrorNoSuffixAdjustment(nm)
        if partHolder>=0 then
            return repo,partHolder
        end
    end
end

function simBWF.getAvailablePallets()
    local repoP=getObjectsWithTag(simBWF.PALLETREPOSITORY_TAG,true)
    if #repoP==0 then
        repoP=getObjectsWithTag(simBWF.BLUEREALITYAPP_TAG,true) -- for temp. transition
    end
    if #repoP==1 then
        local retData=simBWF.callCustomizationScriptFunction('ext_getListOfAvailablePallets',repoP[1])
        return retData
    end
    return {}
end

function simBWF.getAllPartsFromPartRepositoryV0()
    local repo,partHolder=simBWF.getPartRepositoryHandles()
    if repo then
        local retVal={}
        local l=sim.getObjectsInTree(partHolder,sim.handle_all,1+2)
        for i=1,#l,1 do
            local data=sim.readCustomDataBlock(l[i],simBWF.PART_TAG)
            if data then
                data=sim.unpackTable(data)
                retVal[#retVal+1]={data['name'],l[i]}
            end
        end
        return retVal
    end
end

function simBWF.getAllPartsFromPartRepository()
    local repo,partHolder=simBWF.getPartRepositoryHandles()
    if repo then
        local retVal={}
        local l=sim.getObjectsInTree(partHolder,sim.handle_all,1+2)
        for i=1,#l,1 do
            local data=sim.readCustomDataBlock(l[i],simBWF.PART_TAG)
            if data then
                data=sim.unpackTable(data)
                retVal[#retVal+1]={simBWF.getPartAltName(l[i]),l[i]}
            end
        end
        return retVal
    end
end


function simBWF.removeTmpRem(txt)
    while true do
        local s=string.find(txt,"--%[%[tmpRem")
        if not s then break end
        local e=string.find(txt,"--%]%]",s+1)
        if not e then break end
        local tmp=''
        if s>1 then
            tmp=string.sub(txt,1,s-1)
        end
        tmp=tmp..string.sub(txt,e+4)
        txt=tmp
    end
    return txt
end

function simBWF.getAllPossiblePartDestinationsV0()
    local allDestinations={}
    -- First the parts from the part repository:
    local lst=simBWF.getAllPartsFromPartRepositoryV0()
    if lst then
        for i=1,#lst,1 do
            allDestinations[#allDestinations+1]=lst[i][1]
        end
    end
    -- The pingpong packer destination:
    local lst=getObjectsWithTag(simBWF.CONVEYOR_TAG,true)
    for i=1,#lst,1 do
        local data=sim.readCustomDataBlock(lst[i],simBWF.CONVEYOR_TAG)
        data=sim.unpackTable(data)
        if data['locationName'] then
            allDestinations[#allDestinations+1]=data['locationName']
        end
    end
    -- The thermoformer destination:
    for i=1,#lst,1 do
        local data=sim.readCustomDataBlock(lst[i],simBWF.CONVEYOR_TAG)
        data=sim.unpackTable(data)
        if data['partName'] then
            allDestinations[#allDestinations+1]=data['partName']
        end
    end
    -- The location destination
    local lst=getObjectsWithTag(simBWF.OLDLOCATION_TAG,true)
    for i=1,#lst,1 do
        local data=sim.readCustomDataBlock(lst[i],simBWF.OLDLOCATION_TAG)
        data=sim.unpackTable(data)
        if data['name'] then
            allDestinations[#allDestinations+1]=data['name']
        end
    end
    return allDestinations
end

function simBWF.getAllPossiblePartDestinations()
    local allDestinations={}
    -- First the parts from the part repository:
    local lst=simBWF.getAllPartsFromPartRepository()
    if lst then
        for i=1,#lst,1 do
            allDestinations[#allDestinations+1]=lst[i][1]
        end
    end

    -- TODO: use below the model's alt-names as destination!
    --[[
    -- The pingpong packer destination:
    local lst=getObjectsWithTag(simBWF.CONVEYOR_TAG,true)
    for i=1,#lst,1 do
        local data=sim.readCustomDataBlock(lst[i],simBWF.CONVEYOR_TAG)
        data=sim.unpackTable(data)
        if data['locationName'] then
            allDestinations[#allDestinations+1]=data['locationName']
        end
    end
    -- The thermoformer destination:
    for i=1,#lst,1 do
        local data=sim.readCustomDataBlock(lst[i],simBWF.CONVEYOR_TAG)
        data=sim.unpackTable(data)
        if data['partName'] then
            allDestinations[#allDestinations+1]=data['partName']
        end
    end
    --]]
    return allDestinations
end

function simBWF.isObjectPartAndInstanciated(h)
    local data=sim.readCustomDataBlock(h,simBWF.PART_TAG)
    if data then
        data=sim.unpackTable(data)
        return true, data['instanciated'], data
    end
    return false, false, nil
end

function simBWF.checkIfCodeAndModelMatch(modelHandle,codeVersion,modelVersion)
    if codeVersion~=modelVersion then
        sim.msgBox(sim.msgbox_type_warning,sim.msgbox_buttons_ok,"Code and Model Version Mismatch","There is a mismatch between the code version and model version for:\n\nModel name: "..sim.getObjectName(modelHandle).."\nModel version: "..modelVersion.."\nCode version: "..codeVersion)
    end
end

function simBWF.getAllPossibleTriggerableFeeders(except)
    local allFeeders={}
    local allObjs=sim.getObjectsInTree(sim.handle_scene,sim.handle_all,0)
    for i=1,#allObjs,1 do
        local h=allObjs[i]
        if h~=except then
            local data=sim.readCustomDataBlock(h,simBWF.PARTFEEDER_TAG)
            if data then
                data=sim.unpackTable(data)
                if sim.boolAnd32(data['bitCoded'],4+8+16)==16 then
                    allFeeders[#allFeeders+1]={sim.getObjectName(h),h}
                end
            else
                data=sim.readCustomDataBlock(h,simBWF.MULTIFEEDER_TAG)
                if data then
                    data=sim.unpackTable(data)
                    if sim.boolAnd32(data['bitCoded'],4+8+16)==16 then
                        allFeeders[#allFeeders+1]={sim.getObjectName(h),h}
                    end
                end
            end
        end
    end
    return allFeeders
end

function simBWF.getReferencedObjectHandle(modelHandle,index)
    local refH=sim.getReferencedHandles(modelHandle)
    if refH and #refH>=index then
        return refH[index]
    end
    return -1
end

function simBWF.setReferencedObjectHandle(modelHandle,index,referencedObjectHandle)
    local refH=sim.getReferencedHandles(modelHandle)
    if not refH then
        refH={}
    end
    while #refH<index do
        refH[#refH+1]=-1 -- pad with -1
    end
    refH[index]=referencedObjectHandle
    sim.setReferencedHandles(modelHandle,refH)
end

function simBWF.getObjectNameOrNone(objectHandle)
    if objectHandle>=0 then
        return sim.getObjectName(objectHandle)
    end
    return simBWF.NONE_TEXT
end

function simBWF.getObjectAltNameOrNone(objectHandle)
    if objectHandle>=0 then
        return simBWF.getObjectAltName(objectHandle)
    end
    return simBWF.NONE_TEXT
end

function simBWF.createCustomUi(nakedXml,title,dlgPos,closeable,onCloseFunction,modal,resizable,activate,additionalAttributes,dlgSize)
    -- Call utils function instead once version is stable
    local xml='<ui title="'..title..'" closeable="'
    if closeable then
        if onCloseFunction and onCloseFunction~='' then
            xml=xml..'true" on-close="'..onCloseFunction..'"'
        else
            xml=xml..'true"'
        end
    else
        xml=xml..'false"'
    end
    if modal then
        xml=xml..' modal="true"'
    else
        xml=xml..' modal="false"'
    end
    if resizable then
        xml=xml..' resizable="true"'
    else
        xml=xml..' resizable="false"'
    end
    if activate then
        xml=xml..' activate="true"'
    else
        xml=xml..' activate="false"'
    end
    if additionalAttributes and additionalAttributes~='' then
        xml=xml..' '..additionalAttributes
    end
    if dlgSize then
        xml=xml..' size="'..dlgSize[1]..','..dlgSize[2]..'"'
    end
    if not dlgPos then
        xml=xml..' placement="relative" position="-50,50">'
    else
        if type(dlgPos)=='string' then
            if dlgPos=='center' then
                xml=xml..' placement="center">'
            end
            if dlgPos=='bottomRight' then
                xml=xml..' placement="relative" position="-50,-50">'
            end
            if dlgPos=='bottomLeft' then
                xml=xml..' placement="relative" position="50,-50">'
            end
            if dlgPos=='topLeft' then
                xml=xml..' placement="relative" position="50,50">'
            end
            if dlgPos=='topRight' then
                xml=xml..' placement="relative" position="-50,50">'
            end
        else
            xml=xml..' placement="absolute" position="'..dlgPos[1]..','..dlgPos[2]..'">'
        end
    end
    xml=xml..nakedXml..'</ui>'
    local ui=simUI.create(xml)
    --[[
    if dlgSize then
        simUI.setSize(ui,dlgSize[1],dlgSize[2])
    end
    --]]
    if not activate then
        if 2==sim.getInt32Parameter(sim.intparam_platform) then
            -- To fix a Qt bug on Linux
            sim.auxFunc('activateMainWindow')
        end
    end
    return ui
end

function simBWF.getSelectedEditWidget(ui)
    -- Call utils function instead once version is stable
    local ret=-1
    if sim.getInt32Parameter(sim.intparam_program_version)>30302 then
        ret=simUI.getCurrentEditWidget(ui)
    end
    return ret
end

function simBWF.setSelectedEditWidget(ui,id)
    -- Call utils function instead once version is stable
    if id>=0 then
        simUI.setCurrentEditWidget(ui,id)
    end
end

function simBWF.getRadiobuttonValFromBool(b)
    -- Call utils function instead once version is stable
    if b then
        return 1
    end
    return 0
end

function simBWF.getCheckboxValFromBool(b)
    -- Call utils function instead once version is stable
    if b then
        return 2
    end
    return 0
end


function simBWF.writeSessionPersistentObjectData(objectHandle,dataName,...)
    -- Call utils function instead once version is stable
    local data={...}
    local nm="___"..sim.getScriptHandle()..sim.getObjectName(objectHandle)..sim.getInt32Parameter(sim.intparam_scene_unique_id)..sim.getObjectStringParameter(objectHandle,sim.objstringparam_dna)..dataName
    data=sim.packTable(data)
    sim.writeCustomDataBlock(sim.handle_app,nm,data)
end

function simBWF.readSessionPersistentObjectData(objectHandle,dataName)
    -- Call utils function instead once version is stable
    local nm="___"..sim.getScriptHandle()..sim.getObjectName(objectHandle)..sim.getInt32Parameter(sim.intparam_scene_unique_id)..sim.getObjectStringParameter(objectHandle,sim.objstringparam_dna)..dataName
    local data=sim.readCustomDataBlock(sim.handle_app,nm)
    if data then
        data=sim.unpackTable(data)
        return unpack(data)
    else
        return nil
    end
end

function simBWF.drawImageLines(image,resolution,points,color,size)
    return sim.auxFunc('drawImageLines',image,resolution,points,color,size)
end

function simBWF.drawImageSquares(image,resolution,squares,color,size)
    return sim.auxFunc('drawImageSquares',image,resolution,squares,color,size)
end

function simBWF.getUiTitleNameFromModel(model,modelVersion,codeVersion)
    local retVal=sim.getObjectName(model+sim.handleflag_altname)
    if modelVersion then
        retVal=retVal.." (V"..modelVersion..")"
    end
    return retVal
end

function simBWF.getNormalizedVector(v)
    local l=math.sqrt(v[1]*v[1]+v[2]*v[2]+v[3]*v[3])
    return {v[1]/l,v[2]/l,v[3]/l}
end

function simBWF.getPtPtDistance(pt1,pt2)
    local p={pt2[1]-pt1[1],pt2[2]-pt1[2],pt2[3]-pt1[3]}
    return math.sqrt(p[1]*p[1]+p[2]*p[2]+p[3]*p[3])
end

function simBWF.getCrossProduct(v1,v2)
    local ret={}
    ret[1]=v1[2]*v2[3]-v1[3]*v2[2]
    ret[2]=v1[3]*v2[1]-v1[1]*v2[3]
    ret[3]=v1[1]*v2[2]-v1[2]*v2[1]
    return ret
end

function simBWF.getScaledVector(v,scalingFact)
    return {v[1]*scalingFact,v[2]*scalingFact,v[3]*scalingFact}
end

function simBWF.getModelMainTag(objHandle)
    local tags=sim.readCustomDataBlockTags(objHandle)
    if tags then
        for i=1,#tags,1 do
            if tags[i]==simBWF.LOCATIONFRAME_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.TRACKINGWINDOW_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.RAGNAR_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.CONVEYOR_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.PARTFEEDER_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.PARTTAGGER_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.PACKML_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.BLUEREALITYAPP_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.PARTSINK_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.LIFT_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.RAGNARGRIPPER_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.RAGNARGRIPPERPLATFORM_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.RAGNARVISION_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.RAGNARCAMERA_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.RAGNARSENSOR_TAG then
                return tags[i]
            end
            if tags[i]==simBWF.RAGNARDETECTOR_TAG then
                return tags[i]
            end
        end
    end
    return ''
end

function simBWF.getModelTagsForMessages()
    local ret={}
    ret[1]=simBWF.LOCATIONFRAME_TAG
    ret[2]=simBWF.TRACKINGWINDOW_TAG
    ret[3]=simBWF.RAGNAR_TAG
    ret[4]=simBWF.CONVEYOR_TAG
    ret[5]=simBWF.PARTFEEDER_TAG
    ret[6]=simBWF.PARTTAGGER_TAG
    ret[7]=simBWF.PARTSINK_TAG
    ret[8]=simBWF.RAGNARGRIPPER_TAG
    ret[9]=simBWF.RAGNARGRIPPERPLATFORM_TAG
    ret[10]=simBWF.RAGNARVISION_TAG
    ret[11]=simBWF.RAGNARCAMERA_TAG
    ret[12]=simBWF.RAGNARSENSOR_TAG
    ret[13]=simBWF.RAGNARDETECTOR_TAG
    ret[14]=simBWF.LIFT_TAG
    return ret
end

function simBWF.isSystemOnline()
    return sim.getIntegerSignal('__brOnline__')~=nil
end

function simBWF.isInTestMode()
    return sim.getIntegerSignal('__brTesting__')~=nil
end

function simBWF.markUndoPoint()
    local cnt=sim.getIntegerSignal('__brUndoPointCounter__')
    if cnt then
        sim.setIntegerSignal('__brUndoPointCounter__',cnt+1)
    end
end

function simBWF.outputMessage(msg)
    local msgs=sim.getStringSignal('__brMessages__')
    if not msgs then
        msgs=''
    end
    msgs=msgs..msg..'\n'
    sim.setStringSignal('__brMessages__',msgs)
end

function simBWF.getSimulationOrOnlineTime()
    return sim.getFloatSignal('__brOnlineTime__')
end

function simBWF.getMatrixFromCalibrationBallPositions(ball1,ball2,ball3,relativeToVisionSensor)
    local calData={ball1,ball2,ball3}
    -- now set the location frame balls in place:
    -- normalized vector X:
    local x={calData[2][1]-calData[1][1],calData[2][2]-calData[1][2],calData[2][3]-calData[1][3]}
    x=simBWF.getNormalizedVector(x)
    -- normalized vector Z:
    local yp={calData[3][1]-calData[2][1],calData[3][2]-calData[2][2],calData[3][3]-calData[2][3]}
    local z=simBWF.getCrossProduct(x,yp)
    z=simBWF.getNormalizedVector(z)
    if z[3]<0 and not relativeToVisionSensor then
       z=simBWF.getScaledVector(z,-1) -- this is the case when the blue ball is on the 'other side'
    end
    -- normalized vector Y:
    local y=simBWF.getCrossProduct(z,x)
    -- Build the matrix:
    local m={x[1],y[1],z[1],calData[1][1],
            x[2],y[2],z[2],calData[1][2],
            x[3],y[3],z[3],calData[1][3]}
    return m
end

function simBWF.callScriptFunction_noError(funcName,objectId,scriptType,...)
    local err=sim.getInt32Parameter(sim.intparam_error_report_mode)
    sim.setInt32Parameter(sim.intparam_error_report_mode,0)
    local funcNameAtScriptName=funcName..'@'..sim.getObjectName(objectId)
    local ret1,ret2,ret3,ret4,ret5,ret6,ret7,ret8=sim.callScriptFunction(funcNameAtScriptName,scriptType,...)
    sim.setInt32Parameter(sim.intparam_error_report_mode,err)
    return ret1,ret2,ret3,ret4,ret5,ret6,ret7,ret8
end

function simBWF.callScriptFunction(funcName,objectId,scriptType,...)
    local funcNameAtScriptName=funcName..'@'..sim.getObjectName(objectId)
    local ret1,ret2,ret3,ret4,ret5,ret6,ret7,ret8=sim.callScriptFunction(funcNameAtScriptName,scriptType,...)
    return ret1,ret2,ret3,ret4,ret5,ret6,ret7,ret8
end

function simBWF.callCustomizationScriptFunction(funcName,objectId,...)
    return simBWF.callScriptFunction(funcName,objectId,sim.scripttype_customizationscript,...)
end

function simBWF.callChildScriptFunction(funcName,objectId,...)
    return simBWF.callScriptFunction(funcName,objectId,sim.scripttype_childscript,...)
end

function simBWF.callCustomizationScriptFunction_noError(funcName,objectId,...)
    return simBWF.callScriptFunction_noError(funcName,objectId,sim.scripttype_customizationscript,...)
end

function simBWF.callChildScriptFunction_noError(funcName,objectId,...)
    return simBWF.callScriptFunction_noError(funcName,objectId,sim.scripttype_childscript,...)
end

function simBWF.announcePalletWasRenamed(palletId)
    -- 1. Location frames:
    local allLocationFrames=sim.getObjectsWithTag(simBWF.LOCATIONFRAME_TAG,true)
    for i=1,#allLocationFrames,1 do
        simBWF.callCustomizationScriptFunction('ext_announcePalletWasRenamed',allLocationFrames[i])
    end
    -- 2. Tracking windows:
    local allTrackingWindows=sim.getObjectsWithTag(simBWF.TRACKINGWINDOW_TAG,true)
    for i=1,#allTrackingWindows,1 do
        simBWF.callCustomizationScriptFunction('ext_announcePalletWasRenamed',allTrackingWindows[i])
    end
    -- 3. Part repository:
    local allPartRepositories=sim.getObjectsWithTag(simBWF.PARTREPOSITORY_TAG,true)
    for i=1,#allPartRepositories,1 do
        simBWF.callCustomizationScriptFunction('ext_announcePalletWasRenamed',allPartRepositories[i])
    end
    -- For temp transition:
    local allPartRepositories=sim.getObjectsWithTag(simBWF.BLUEREALITYAPP_TAG,true)
    for i=1,#allPartRepositories,1 do
        simBWF.callCustomizationScriptFunction_noError('ext_announcePalletWasRenamed',allPartRepositories[i])
    end
end

function simBWF.announcePalletWasCreated()
    -- 1. Location frames:
    local allLocationFrames=sim.getObjectsWithTag(simBWF.LOCATIONFRAME_TAG,true)
    for i=1,#allLocationFrames,1 do
        simBWF.callCustomizationScriptFunction('ext_announcePalletWasCreated',allLocationFrames[i])
    end
    -- 2. Tracking windows:
    local allTrackingWindows=sim.getObjectsWithTag(simBWF.TRACKINGWINDOW_TAG,true)
    for i=1,#allTrackingWindows,1 do
        simBWF.callCustomizationScriptFunction('ext_announcePalletWasCreated',allTrackingWindows[i])
    end
    -- 3. Part repository:
    local allPartRepositories=sim.getObjectsWithTag(simBWF.PARTREPOSITORY_TAG,true)
    for i=1,#allPartRepositories,1 do
        simBWF.callCustomizationScriptFunction('ext_announcePalletWasCreated',allPartRepositories[i])
    end
    -- for temp. transition:
    local allPartRepositories=sim.getObjectsWithTag(simBWF.BLUEREALITYAPP_TAG,true)
    for i=1,#allPartRepositories,1 do
        simBWF.callCustomizationScriptFunction_noError('ext_announcePalletWasCreated',allPartRepositories[i])
    end
end

function simBWF.announceOnlineModeChanged(isNowOnline)
    -- 1. Location frames:
    local allLocationFrames=sim.getObjectsWithTag(simBWF.LOCATIONFRAME_TAG,true)
    for i=1,#allLocationFrames,1 do
        simBWF.callCustomizationScriptFunction('ext_announceOnlineModeChanged',allLocationFrames[i],isOnlineNow)
    end
    -- 2. Tracking windows:
    local allTrackingWindows=sim.getObjectsWithTag(simBWF.TRACKINGWINDOW_TAG,true)
    for i=1,#allTrackingWindows,1 do
        simBWF.callCustomizationScriptFunction('ext_announceOnlineModeChanged',allTrackingWindows[i],isOnlineNow)
    end
end

function simBWF.markAsCopy(objectHandle)
    sim.writeCustomDataBlock(objectHandle,'@tmp__isCopy','x')
end

function simBWF.isCopy(objectHandle)
    local retVal=(sim.readCustomDataBlock(objectHandle,'@tmp__isCopy')~=nil)
    sim.writeCustomDataBlock(objectHandle,'@tmp__isCopy','')
    return retVal
end

function simBWF.getObjectHandleFromAltName(altName)
    local version=sim.getInt32Parameter(sim.intparam_program_version)
    local revision=sim.getInt32Parameter(sim.intparam_program_revision)
    if (version>v or revision>15) then
        return sim.getObjectHandle(altName..'@alt')
    end
    return sim.getObjectHandle(altName)
end

function simBWF.getObjectAltName(objectHandle)
    local version=sim.getInt32Parameter(sim.intparam_program_version)
    local revision=sim.getInt32Parameter(sim.intparam_program_revision)
    if (version>30400 or revision>15) then
        return sim.getObjectName(objectHandle+sim.handleflag_altname)
    end
    return sim.getObjectName(objectHandle)
end

function simBWF.setObjectAltName(objectHandle,altName)
    local version=sim.getInt32Parameter(sim.intparam_program_version)
    local revision=sim.getInt32Parameter(sim.intparam_program_revision)
    if (version>30400 or revision>15) then
        if #altName>=1 then
            local correctedName=''
            for i=1,#altName,1 do
                local v=altName:sub(i,i)
                if (v>='0' and v<='9') or (v>='a' and v<='z') or (v>='A' and v<='Z') or v=='_' then
                    correctedName=correctedName..v
                else
                    correctedName=correctedName..'_'
                end
            end
            return sim.setObjectName(objectHandle+sim.handleflag_altname+sim.handleflag_silenterror,correctedName)
        end
    end
    return(-1)
end

function simBWF.getPartAltName(objectHandle)
    local nm=simBWF.getObjectAltName(objectHandle)
    local retValue=""
    if string.find(nm,simBWF.PART_ALTNAMEPREFIX)==1 then -- should always pass
        for i=#simBWF.PART_ALTNAMEPREFIX+1,#nm,1 do
            retValue=retValue..string.sub(nm,i,i)-- We remove the simBWF.PART_ALTNAMEPREFIX prefix
        end
    else
        retValue="ERROR"
    end
    return retValue
end

function simBWF.setPartAltName(objectHandle,altName)
    return simBWF.setObjectAltName(objectHandle,simBWF.PART_ALTNAMEPREFIX..altName)
end

function simBWF.getPalletHandleFromAltName(palletName)
    palletName=simBWF.PALLET_ALTNAMEPREFIX..palletName
    return simBWF.getObjectHandleFromAltName(palletName)
end

function simBWF.getPalletAltName(objectHandle)
    local nm=simBWF.getObjectAltName(objectHandle)
    local retValue=""
    if string.find(nm,simBWF.PALLET_ALTNAMEPREFIX)==1 then -- should always pass
        for i=#simBWF.PALLET_ALTNAMEPREFIX+1,#nm,1 do
            retValue=retValue..string.sub(nm,i,i)-- We remove the simBWF.PALLET_ALTNAMEPREFIX prefix
        end
    else
        retValue="ERROR"
    end
    return retValue
end

function simBWF.setPalletAltName(objectHandle,altName)
    return simBWF.setObjectAltName(objectHandle,simBWF.PALLET_ALTNAMEPREFIX..altName)
end

function simBWF.getValidName(name,onlyUpperCase,optionalAllowedChars)
    if onlyUpperCase then
        name=name:upper()
    end
    local retVal=''
    for i=1,#name,1 do
        local v=name:sub(i,i)
        specialChar=false
        if type(optionalAllowedChars)=='table' then
            for j=1,#optionalAllowedChars,1 do
                if v==optionalAllowedChars[j] then
                    specialChar=true
                    break
                end
            end
        end
        if (v>='0' and v<='9') or (v>='a' and v<='z') or (v>='A' and v<='Z') or v=='_' or specialChar then
            retVal=retVal..v
        else
            retVal=retVal..'_'
        end
    end
    return retVal
end

function simBWF.openFile(fileAndPath)
    local platf=sim.getInt32Parameter(sim.intparam_platform)
    if platf==0 then
        sim.launchExecutable(fileAndPath,'',0)
    end
    if platf==1 then
        if (version>30400 or revision>14) then
            sim.launchExecutable('@open',fileAndPath,0)
        else
            sim.launchExecutable('/usr/bin/open',fileAndPath,0)
        end
    end
    if platf==2 then
        if (version>30400 or revision>14) then
            sim.launchExecutable('@xdg-open',fileAndPath,0)
        else
            sim.launchExecutable('/usr/bin/xdg-open',fileAndPath,0)
        end
    end
end

function simBWF.openUrl(url)
    local platf=sim.getInt32Parameter(sim.intparam_platform)
    if string.find(url,"http://",1)~=1 then
        url="http://"..url
    end
    if platf==0 then
        sim.launchExecutable(url,'',0)
    end
    if platf==1 then
        if (version>30400 or revision>14) then
            sim.launchExecutable('@open',url,0)
        else
            sim.launchExecutable('/usr/bin/open',url,0)
        end
    end
    if platf==2 then
        if (version>30400 or revision>14) then
            sim.launchExecutable('@xdg-open',url,0)
        else
            sim.launchExecutable('/usr/bin/xdg-open',url,0)
        end
    end
end

function simBWF.forbidInputForTrackingWindowChainItems(inputItem)
    local modelTags={simBWF.TRACKINGWINDOW_TAG,simBWF.RAGNARVISION_TAG,simBWF.RAGNARSENSOR_TAG,simBWF.RAGNARDETECTOR_TAG}
    local objs=sim.getObjectsInTree(sim.handle_scene)
    for i=1,#objs,1 do
        local dat=sim.readCustomDataBlockTags(objs[i])
        if dat then
            local leave=false
            for j=1,#dat,1 do
                for k=1,#modelTags,1 do
                    if dat[j]==modelTags[k] then
                        simBWF.callCustomizationScriptFunction("ext_forbidInput",objs[i],inputItem)
                        leave=true
                        break
                    end
                end
                if leave then
                    break
                end
            end
        end
    end
end

function simBWF.getModelThatUsesThisModelAsInput(thisModelHandle)
    local modelTags={simBWF.TRACKINGWINDOW_TAG,simBWF.RAGNARVISION_TAG,simBWF.RAGNARSENSOR_TAG,simBWF.RAGNARDETECTOR_TAG}
    for i=1,#modelTags,1 do
        local models=sim.getObjectsWithTag(modelTags[i],true)
        for j=1,#models,1 do
            local h=simBWF.callCustomizationScriptFunction('ext_getInputObjectHande',models[j])
            if h==thisModelHandle then
                return models[j]
            end
        end
    end
    return -1
end

function simBWF.sendQuery(cmd,data)
    if __BWFPLUGINISLOADED__ or sim.isPluginLoaded('Bwf') then
        __BWFPLUGINISLOADED__=true
        local reply,replyData=simBWF.query(cmd,data)
        return reply,replyData
    else
        local nm="___OUTPUTMSGNOBWFPLUGIN"..sim.getInt32Parameter(sim.intparam_scene_unique_id)
        local data=sim.readCustomDataBlock(sim.handle_app,nm)
        if data~='x' then
            sim.msgBox(sim.msgbox_type_warning,sim.msgbox_buttons_ok,"BWF Plugin","BWF plugin was not found.\n\nThe scene will not operate as expected")
            sim.writeCustomDataBlock(sim.handle_app,nm,"x")
        end
    end
    return 'ng'
end

function simBWF.getNameAndNumber(name)
    local baseName=''
    local nbTxt=''
    for i=#name,1,-1 do
        local v=name:sub(i,i)
        if (v>='0' and v<='9') and (baseName=='') then
            nbTxt=v..nbTxt
        else
            baseName=v..baseName
        end
    end
    local nb=tonumber(nbTxt)
    return baseName,nb
end

function simBWF.format(fmt,...)
    -- on some systems, Lua will format fractional numbers with the wrong decimal char, e.g.:
    -- "0.1" as "0,1"
    local a={...}
    for i=1,#a,1 do
        if type(a[i])=='string' then
            a[i]=string.gsub(a[i],",","@@##@@")
        end
    end
    local str=string.gsub(fmt,",","@@##@@") 
    str=string.gsub(string.format(str,unpack(a)),",",".")
    return(string.gsub(str,"@@##@@",",")) 
end


-- Model tags (do not modify):
simBWF.LOCATIONFRAME_TAG='XYZ_LOCATIONFRAME_INFO'
simBWF.TRACKINGWINDOW_TAG='XYZ_TRACKINGWINDOW_INFO'
simBWF.RAGNAR_TAG='RAGNAR_CONF'
simBWF.CONVEYOR_TAG='CONVEYOR_CONF'
simBWF.PARTFEEDER_TAG='XYZ_FEEDER_INFO'
simBWF.MULTIFEEDER_TAG='XYZ_MULTIFEEDERTRIGGER_INFO'
simBWF.PARTTAGGER_TAG='XYZ_PARTTAGGER_INFO'
simBWF.PART_TAG='XYZ_FEEDERPART_INFO'
simBWF.PALLET_TAG='XYZ_PALLET_INFO'
simBWF.PACKML_TAG='XYZ_PACKML_INFO'
simBWF.BLUEREALITYAPP_TAG='XYZ_BLUEREALITYAPP_INFO'
simBWF.PARTREPOSITORY_TAG='XYZ_PARTREPO_INFO'
simBWF.PALLETREPOSITORY_TAG='XYZ_PALLETREPO_INFO'
simBWF.PARTSINK_TAG='XYZ_PARTSINK_INFO'
simBWF.LIFT_TAG='XYZ_LIFT_INFO'
simBWF.RAGNARGRIPPER_TAG='XYZ_RAGNARGRIPPER_INFO'
simBWF.RAGNARGRIPPERPLATFORM_TAG='XYZ_RAGNARGRIPPERPLATFORM_INFO'
simBWF.RAGNARVISION_TAG='XYZ_RAGNARVISION_INFO'
simBWF.RAGNARCAMERA_TAG='XYZ_RAGNARCAMERA_INFO'
simBWF.RAGNARSENSOR_TAG='XYZ_RAGNARSENSOR_INFO'
simBWF.RAGNARDETECTOR_TAG='XYZ_RAGNARDETECTOR_INFO'
simBWF.BINARYSENSOR_TAG='XYZ_BINARYSENSOR_INFO'
simBWF.RAGNARGRIPPERPLATFORMIKPT_TAG='XYZ_RAGNARGRIPPERPLATFORM_IKPT_INFO'
simBWF.CALIBRATIONBALL1_TAG='XYZ_CALIBRATIONBALL1_INFO'
simBWF.BOX_PART_TAG='XYZ_BOX_INFO'
simBWF.CYLINDER_PART_TAG='XYZ_CYLINDER_INFO'
simBWF.SPHERE_PART_TAG='XYZ_SPHERE_INFO'
simBWF.TRAY_PART_TAG='XYZ_TRAY_INFO'
simBWF.PACKINGBOX_PART_TAG='XYZ_PACKINGBOX_INFO'
simBWF.PILLOWBAG_PART_TAG='XYZ_PILLOWBAG_INFO'
simBWF.SHIPPINGBOX_PART_TAG='XYZ_SHIPPINGBOX_INFO'
simBWF.LABEL_PART_TAG='XYZ_PARTLABEL_INFO'
simBWF.GEOMETRY_PART_TAG='PART_GEOMETRY_INFO'


simBWF.OLDLOCATION_TAG='XYZ_LOCATION_INFO'
simBWF.OLDPARTREPO_TAG='XYZ_PARTREPOSITORY_INFO'
simBWF.OLDOVERRIDE_TAG='XYZ_OVERRIDE_INFO'
simBWF.OLDSTATICPICKWINDOW_TAG='XYZ_STATICPICKWINDOW_INFO'
simBWF.OLDSTATICPLACEWINDOW_TAG='XYZ_STATICPLACEWINDOW_INFO'

-- Object names (do not modify):
simBWF.PALLET_ALTNAMEPREFIX='__PALLET__'
simBWF.PART_ALTNAMEPREFIX='__PART__'

-- NONE text (do not modify):
simBWF.NONE_TEXT='<NONE>'

-- Ragnar referenced object slots (do not modify):
simBWF.RAGNAR_PICKTRACKINGWINDOW1_REF=1
simBWF.RAGNAR_PICKTRACKINGWINDOW2_REF=2
simBWF.RAGNAR_PICKTRACKINGWINDOW3_REF=3
simBWF.RAGNAR_PICKTRACKINGWINDOW4_REF=4
simBWF.RAGNAR_PLACETRACKINGWINDOW1_REF=11
simBWF.RAGNAR_PLACETRACKINGWINDOW2_REF=12
simBWF.RAGNAR_PLACETRACKINGWINDOW3_REF=13
simBWF.RAGNAR_PLACETRACKINGWINDOW4_REF=14
simBWF.RAGNAR_PICKFRAME1_REF=21
simBWF.RAGNAR_PICKFRAME2_REF=22
simBWF.RAGNAR_PICKFRAME3_REF=23
simBWF.RAGNAR_PICKFRAME4_REF=24
simBWF.RAGNAR_PLACEFRAME1_REF=31
simBWF.RAGNAR_PLACEFRAME2_REF=32
simBWF.RAGNAR_PLACEFRAME3_REF=33
simBWF.RAGNAR_PLACEFRAME4_REF=34
simBWF.RAGNAR_CONVEYOR1_REF=41
simBWF.RAGNAR_CONVEYOR2_REF=42

-- Feeder/Multifeeder referenced object slots (do not modify):
simBWF.FEEDER_SENSOR_REF=1
simBWF.FEEDER_CONVEYOR_REF=2
simBWF.FEEDER_STOPSIGNAL_REF=3
simBWF.FEEDER_STARTSIGNAL_REF=4

-- Location frame referenced object slots (do not modify):
simBWF.LOCATIONFRAME_PALLET_REF=1

-- Tracking window referenced object slots (do not modify):
simBWF.TRACKINGWINDOW_PALLET_REF=1
simBWF.TRACKINGWINDOW_INPUT_REF=2

-- Ragnar vision referenced object slots (do not modify):
simBWF.RAGNARVISION_CONVEYOR_REF=1
simBWF.RAGNARVISION_CAMERA_REF=2
simBWF.RAGNARVISION_INPUT_REF=3

-- Ragnar sensor referenced object slots (do not modify):
simBWF.RAGNARSENSOR_CONVEYOR_REF=1
simBWF.RAGNARSENSOR_INPUT_REF=2

-- Ragnar detector referenced object slots (do not modify):
simBWF.RAGNARDETECTOR_CONVEYOR_REF=1
simBWF.RAGNARDETECTOR_INPUT_REF=2

-- Sink referenced object slots (do not modify):
simBWF.PARTSINK_TRIGGER_REF=1

-- Part referenced object slots (do not modify):
simBWF.PART_PALLET_REF=1

-- Part palletizer referenced object slots (do not modify):
simBWF.PALLETIZER_CONVEYOR_REF=1

-- Static pick window referenced object slots (do not modify):
simBWF.STATICPICKWINDOW_SENSOR_REF=1

-- Static place window referenced object slots (do not modify):
simBWF.STATICPLACEWINDOW_SENSOR_REF=1

-- Old tracking window referenced object slots (do not modify):
simBWF.OLDTRACKINGWINDOW_CONVEYOR_REF=1
simBWF.OLDTRACKINGWINDOW_INPUT_REF=2

-- Old Ragnar referenced object slots (do not modify):
simBWF.OLDRAGNAR_PARTTRACKING1_REF=1
simBWF.OLDRAGNAR_PARTTRACKING2_REF=2
simBWF.OLDRAGNAR_STATICWINDOW1_REF=3
simBWF.OLDRAGNAR_TARGETTRACKING1_REF=11
simBWF.OLDRAGNAR_TARGETTRACKING2_REF=12
simBWF.OLDRAGNAR_STATICTARGETWINDOW1_REF=13
simBWF.OLDRAGNAR_DROPLOCATION1_REF=21
simBWF.OLDRAGNAR_DROPLOCATION2_REF=22
simBWF.OLDRAGNAR_DROPLOCATION3_REF=23
simBWF.OLDRAGNAR_DROPLOCATION4_REF=24


-- Part teleporter referenced object slots (do not modify):
simBWF.TELEPORTER_DESTINATION_REF=1

-- Conveyor/Pingpong/thermoformer referenced object slots (do not modify):
simBWF.CONVEYOR_STOP_SIGNAL_REF=1
simBWF.CONVEYOR_START_SIGNAL_REF=2
simBWF.CONVEYOR_MASTER_CONVEYOR_REF=3

return simBWF