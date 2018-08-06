function partCreation_makeInvisibleOrNonRespondableToOtherParts(handle,invisible,nonRespondableToOtherParts)
    if invisible then
        local objs=sim.getObjectsInTree(handle)
        for i=1,#objs,1 do
            sim.setObjectInt32Parameter(objs[i],sim.objintparam_visibility_layer,0)
            local p=sim.getObjectSpecialProperty(objs[i])
            local p=sim.boolOr32(p,sim.objectspecialproperty_renderable)-sim.objectspecialproperty_renderable
            sim.setObjectSpecialProperty(objs[i],p)
        end
    end
    objs=sim.getObjectsInTree(handle,sim.object_shape_type)
    for i=1,#objs,1 do
        local r,m=sim.getObjectInt32Parameter(objs[i],sim.shapeintparam_respondable_mask)
        if nonRespondableToOtherParts then
            sim.setObjectInt32Parameter(objs[i],sim.shapeintparam_respondable_mask,sim.boolOr32(m,65280)-32512-127)
        else
            sim.setObjectInt32Parameter(objs[i],sim.shapeintparam_respondable_mask,sim.boolOr32(m,65280)-32768-128)
        end
    end
end

function partCreation_getLabels(partH)
    -- There can be up to 3 labels in this part:
    local possibleLabels=sim.getObjectsInTree(partH,sim.object_shape_type,1)
    local labels={}
    for objInd=1,#possibleLabels,1 do
        local h=possibleLabels[objInd]
        local data=sim.readCustomDataBlock(h,simBWF.LABEL_PART_TAG)
        if data then
            labels[#labels+1]=h
        end
    end
    return labels
end

function partCreation_adjustSizeData(partH,sx,sy,sz)
    local data=sim.unpackTable(sim.readCustomDataBlock(partH,simBWF.PART_TAG))
    local labelData=data['labelData']
    if labelData then
        local s=labelData['smallLabelSize']
        labelData['smallLabelSize']={s[1]*sx,s[2]*sy}
        local s=labelData['largeLabelSize']
        labelData['largeLabelSize']={s[1]*sx,s[2]*sy}
        local s=labelData['boxSize']
        labelData['boxSize']={s[1]*sx,s[2]*sy,s[3]*sz}
        data['labelData']=labelData
        sim.writeCustomDataBlock(partH,simBWF.PART_TAG,sim.packTable(data))
    end
end

function partCreation_setItemMass(handle,m)
    if m~=nil then -- Mass can be nil (for a default mass)
        -- Remember, the item can be a shape, or a model containing several shapes
        local currentMass=0
        local objects={handle}
        while #objects>0 do
            handle=objects[#objects]
            table.remove(objects,#objects)
            local i=0
            while true do
                local h=sim.getObjectChild(handle,i)
                if h>=0 then
                    objects[#objects+1]=h
                    i=i+1
                else
                    break
                end
            end
            if sim.getObjectType(handle)==sim.object_shape_type then
                local r,p=sim.getObjectInt32Parameter(handle,sim.shapeintparam_static)
                if p==0 then
                    local m0,i0,com0=sim.getShapeMassAndInertia(handle)
                    currentMass=currentMass+m0
                end
            end
        end

        local massScaling=m/currentMass

        local objects={handle}
        while #objects>0 do
            handle=objects[#objects]
            table.remove(objects,#objects)
            local i=0
            while true do
                local h=sim.getObjectChild(handle,i)
                if h>=0 then
                    objects[#objects+1]=h
                    i=i+1
                else
                    break
                end
            end
            if sim.getObjectType(handle)==sim.object_shape_type then
                local r,p=sim.getObjectInt32Parameter(handle,sim.shapeintparam_static)
                if p==0 then
                    local transf=sim.getObjectMatrix(handle,-1)
                    local m0,i0,com0=sim.getShapeMassAndInertia(handle,transf)
                    for i=1,9,1 do
                        i0[i]=i0[i]*massScaling
                    end
                    sim.setShapeMassAndInertia(handle,m0*massScaling,i0,com0,transf)
                end
            end
        end
    end
end

function partCreation_regenerateOrRemoveLabels(partH,enabledLabels)
    -- There can be up to 3 labels in this part:
    local possibleLabels=sim.getObjectsInTree(partH,sim.object_shape_type,1)
    local labelData=sim.unpackTable(sim.readCustomDataBlock(partH,simBWF.PART_TAG))['labelData']
    for ind=1,3,1 do
        for objInd=1,#possibleLabels,1 do
            local h=possibleLabels[objInd]
            if h>=0 then
                local data=sim.readCustomDataBlock(h,simBWF.LABEL_PART_TAG)
                if data then
                    data=sim.unpackTable(data)
                    if data['labelIndex']==ind then
                        local bits={1,2,4}
                        if (sim.boolAnd32(bits[ind],enabledLabels)>0) then
                            -- We want to regenerate the position of this label
                            if labelData then
                                local bitC=labelData['bitCoded']
                                local smallLabelSize=labelData['smallLabelSize']
                                local largeLabelSize=labelData['largeLabelSize']
                                local useLargeLabel=(sim.boolAnd32(bitC,64*(2^(ind-1)))>0)
                                local labelSize=smallLabelSize
                                if useLargeLabel then
                                    labelSize=largeLabelSize
                                end
                                local code=labelData['placementCode'][ind]
                                local toExecute='local boxSizeX='..labelData['boxSize'][1]..'\n'
                                toExecute=toExecute..'local boxSizeY='..labelData['boxSize'][2]..'\n'
                                toExecute=toExecute..'local boxSizeZ='..labelData['boxSize'][3]..'\n'
                                toExecute=toExecute..'local labelSizeX='..labelSize[1]..'\n'
                                toExecute=toExecute..'local labelSizeY='..labelSize[2]..'\n'
                                toExecute=toExecute..'local labelRadius='..(0.5*math.sqrt(labelSize[1]*labelSize[1]+labelSize[2]*labelSize[2]))..'\n'

                                toExecute=toExecute..'return {'..code..'}'
                                local theTable=sim.executeLuaCode(toExecute)
                                sim.setObjectPosition(h,partH,theTable[1])
                                sim.setObjectOrientation(h,partH,theTable[2])
                            end
                        else
                            sim.removeObject(h) -- we do not want this label
                            possibleLabels[objInd]=-1
                        end
                    end
                end
            end
        end
    end
end

function partCreation_instanciatePart(partHandle,parentHandle,itemDestination,itemPosition,itemOrientation,itemMass,itemScaling,allowChildItemsIfApplicable)
    local childItemsToReturn=nil
    local p=sim.getModelProperty(partHandle)
    local isBasePartModel=sim.boolAnd32(p,sim.modelproperty_not_model)==0
    local tble
    if isBasePartModel then
        tble=sim.copyPasteObjects({partHandle},1)
    else
        tble=sim.copyPasteObjects({partHandle},0)
    end
    local basePartCopy=tble[1]
    sim.writeCustomDataBlock(basePartCopy,simBWF.GEOMETRY_PART_TAG,'') -- remove the embedded part geometry
    sim.setObjectParent(basePartCopy,parentHandle,true)
    local basePartCopyData=sim.readCustomDataBlock(basePartCopy,simBWF.PART_TAG)
    basePartCopyData=sim.unpackTable(basePartCopyData)
    local invisible=sim.boolAnd32(basePartCopyData['bitCoded'],1)>0
    local nonRespondableToOtherParts=sim.boolAnd32(basePartCopyData['bitCoded'],2)>0
    local ignoreBasePart=sim.boolAnd32(basePartCopyData['bitCoded'],4)>0
    local usePalletColors=sim.boolAnd32(basePartCopyData['bitCoded'],8)>0
    partCreation_makeInvisibleOrNonRespondableToOtherParts(basePartCopy,invisible,nonRespondableToOtherParts)
    
    -- Destination:
    if itemDestination then
        basePartCopyData['destination']=itemDestination
    end

    -- Size scaling:
    if itemScaling then
        local itemLabels=partCreation_getLabels(basePartCopy)
        for j=1,#itemLabels,1 do
            sim.setObjectParent(itemLabels[j],-1,true)
        end
        if type(itemScaling)~='table' then
            -- iso-scaling
            partCreation_adjustSizeData(basePartCopy,itemScaling,itemScaling,itemScaling)
            sim.scaleObjects({basePartCopy},itemScaling,false)
        else
            -- non-iso-scaling
            partCreation_adjustSizeData(basePartCopy,itemScaling[1],itemScaling[2],itemScaling[3])
            if isBasePartModel then
                if sim.canScaleModelNonIsometrically(basePartCopy,itemScaling[1],itemScaling[2],itemScaling[3]) then
                    sim.scaleModelNonIsometrically(basePartCopy,itemScaling[1],itemScaling[2],itemScaling[3])
                end
            else
                if sim.canScaleObjectNonIsometrically(basePartCopy,itemScaling[1],itemScaling[2],itemScaling[3]) then
                    sim.scaleObject(basePartCopy,itemScaling[1],itemScaling[2],itemScaling[3],0)
                end
            end
        end
        for j=1,#itemLabels,1 do
            sim.setObjectParent(itemLabels[j],basePartCopy,true)
        end
    end
    
    -- Mass:
    if itemMass then
        partCreation_setItemMass(basePartCopy,itemMass)
    end

   -- Labels:
    if invisible then
        labelsToEnable=0
    end
    if labelsToEnable and labelsToEnable>=0 then
        partCreation_regenerateOrRemoveLabels(basePartCopy,labelsToEnable)
    end

    -- Position:
    sim.setObjectPosition(basePartCopy,-1,itemPosition)

    -- Orientation:
    sim.setObjectOrientation(basePartCopy,-1,itemOrientation)

    basePartCopyData['instanciated']=true
    basePartCopyData['type']=partHandle
    sim.writeCustomDataBlock(basePartCopy,simBWF.PART_TAG,sim.packTable(basePartCopyData))
    
    -- Now check if that parts has a pallet with other parts attached:
    local attachedPalletHandle=simBWF.getReferencedObjectHandle(partHandle,simBWF.PART_PALLET_REF) -- we have to read it from the original base part
    if attachedPalletHandle>=0 and allowChildItemsIfApplicable then
        -- Yes!
        local baseM=sim.getObjectMatrix(basePartCopy,-1)
        local pallet=sim.unpackTable(sim.readCustomDataBlock(attachedPalletHandle,simBWF.PALLET_TAG))
        local palletM=sim.buildMatrix(basePartCopyData.palletOffset,{pallet.yaw,pallet.pitch,pallet.roll})
        for i=1,#pallet.palletItemList,1 do
            local palletItem=pallet.palletItemList[i]
            if palletItem.model>=0 then
                local palletItemM=sim.buildMatrix({palletItem.locationX,palletItem.locationY,palletItem.locationZ},{palletItem.orientationY,palletItem.orientationP,palletItem.orientationR})
                local palletItemM=sim.multiplyMatrices(palletM,palletItemM)
                local palletItemM=sim.multiplyMatrices(baseM,palletItemM)
                local childPart=palletItem.model
                    
                local p=sim.getModelProperty(childPart)
                local isModel=sim.boolAnd32(p,sim.modelproperty_not_model)==0
                local tble
                if isModel then
                    tble=sim.copyPasteObjects({childPart},1)
                else
                    tble=sim.copyPasteObjects({childPart},0)
                end
                
                childPartCopy=tble[1]
                sim.writeCustomDataBlock(childPartCopy,simBWF.GEOMETRY_PART_TAG,'') -- remove the embedded part geometry

                
                if usePalletColors then
                    local l2=sim.getObjectsInTree(childPartCopy,sim.object_shape_type)
                    for i=1,#l2,1 do
                        sim.setShapeColor(l2[i],nil,sim.colorcomponent_ambient_diffuse,{palletItem.colorR,palletItem.colorG,palletItem.colorB})
                    end
                end
                
                sim.setObjectParent(childPartCopy,parentHandle,true)
                local data=sim.readCustomDataBlock(childPartCopy,simBWF.PART_TAG)
                data=sim.unpackTable(data)
                local invisible=sim.boolAnd32(data['bitCoded'],1)>0
                local nonRespondableToOtherParts=sim.boolAnd32(data['bitCoded'],2)>0
                partCreation_makeInvisibleOrNonRespondableToOtherParts(childPartCopy,invisible,nonRespondableToOtherParts)
                -- Correct for the part frame location (the template has its origine centered x/y, and at the bottom of z):
                local minMaxX=data.vertMinMax[1]
                local minMaxY=data.vertMinMax[2]
                local minMaxZ=data.vertMinMax[3]
                local xShift=(minMaxX[2]+minMaxX[1])/2
                local yShift=(minMaxY[2]+minMaxY[1])/2
                local zShift=-minMaxZ[1]
                palletItemM[4]=palletItemM[4]+palletItemM[1]*xShift+palletItemM[2]*yShift+palletItemM[3]*zShift
                palletItemM[8]=palletItemM[8]+palletItemM[5]*xShift+palletItemM[6]*yShift+palletItemM[7]*zShift
                palletItemM[12]=palletItemM[12]+palletItemM[9]*xShift+palletItemM[10]*yShift+palletItemM[11]*zShift
                --------
                sim.setObjectMatrix(childPartCopy,-1,palletItemM)
                data['instanciated']=true
                data['type']=childPart
                sim.writeCustomDataBlock(childPartCopy,simBWF.PART_TAG,sim.packTable(data))
                if childItemsToReturn==nil then
                    childItemsToReturn={}
                end
                childItemsToReturn[#childItemsToReturn+1]={childPartCopy,isModel}
            end
        end
    end
    local baseItemToReturn=nil
    if ignoreBasePart and childItemsToReturn and #childItemsToReturn>0 then
        if isBasePartModel then
            sim.removeModel(basePartCopy)
        else
            sim.removeObject(basePartCopy)
        end
    else
        baseItemToReturn={basePartCopy,isBasePartModel}
    end
    return baseItemToReturn,childItemsToReturn
end

function partCreation_addToProducedPartsList(baseHandleAndModelTag,auxPartsHandlesAndModelTags,allProducedParts,time)
    if auxPartsHandlesAndModelTags and #auxPartsHandlesAndModelTags>0 then
        for i=1,#auxPartsHandlesAndModelTags,1 do
            local childPartCopy=auxPartsHandlesAndModelTags[i][1]
            p=sim.getObjectPosition(childPartCopy,-1)
            local partData={childPartCopy,time,p,auxPartsHandlesAndModelTags[i][2],true} -- handle, lastMovingTime, lastPosition, isModel, isActive
            allProducedParts[#allProducedParts+1]=partData
        end
    end
    if baseHandleAndModelTag and #baseHandleAndModelTag>=2 and baseHandleAndModelTag[1]>=0 then
        local basePartCopy=baseHandleAndModelTag[1]
        p=sim.getObjectPosition(basePartCopy,-1)
        local partData={basePartCopy,time,p,baseHandleAndModelTag[2],true} -- handle, lastMovingTime, lastPosition, isModel, isActive
        allProducedParts[#allProducedParts+1]=partData
    end
end

function partCreation_deactivatePart(handle,isModel)
    if isModel then
        local p=sim.getModelProperty(handle)
        p=sim.boolOr32(p,sim.modelproperty_not_dynamic)
        sim.setModelProperty(handle,p)
    else
        sim.setObjectInt32Parameter(handle,sim.shapeintparam_static,1) -- we make it static now!
    end
    sim.resetDynamicObject(handle) -- important, otherwise the dynamics engine doesn't notice the change!
end

function partCreation_removePart(handle,isModel)
    if isModel then
        sim.removeModel(handle)
    else
        sim.removeObject(handle)
    end
end

function partCreation_handleCreatedParts(allProducedParts,timeForIdlePartToDeactivate,time,dt)
    local i=1
    while i<=#allProducedParts do
        local h=allProducedParts[i][1]
        if sim.isHandleValid(h)>0 then
            local dataName=simBWF.PART_TAG
            local data=sim.readCustomDataBlock(h,dataName)
            data=sim.unpackTable(data)
            local p=sim.getObjectPosition(h,-1)
            if allProducedParts[i][5] then
                -- The part is still active
                local deactivate=data['deactivate']
                local dp={p[1]-allProducedParts[i][3][1],p[2]-allProducedParts[i][3][2],p[3]-allProducedParts[i][3][3]}
                local l=math.sqrt(dp[1]*dp[1]+dp[2]*dp[2]+dp[3]*dp[3])
                if (l>0.01*dt) then
                    allProducedParts[i][2]=time
                end
                allProducedParts[i][3]=p
                if (time-allProducedParts[i][2]>timeForIdlePartToDeactivate) then
                    deactivate=true
                end
                if deactivate then
                    partCreation_deactivatePart(h,allProducedParts[i][4])
                    allProducedParts[i][5]=false
                    data['vel']={0,0,0}
                else
                    data['vel']={dp[1]/dt,dp[2]/dt,dp[3]/dt}
                end
                sim.writeCustomDataBlock(h,dataName,sim.packTable(data))
            end
            -- Does it want to be destroyed?
            if data['destroy'] or p[3]<-1000 or data['giveUpOwnership'] then
                if not data['giveUpOwnership'] then
                    partCreation_removePart(h,allProducedParts[i][4])
                end
                table.remove(allProducedParts,i)
            else
                i=i+1
            end
        else
            table.remove(allProducedParts,i)
        end
    end
end