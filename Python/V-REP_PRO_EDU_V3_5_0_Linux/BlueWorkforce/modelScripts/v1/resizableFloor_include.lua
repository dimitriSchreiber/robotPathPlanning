function updateFloor()
    local c=readInfo()
    local sx=c['floorSizes'][1]/10
    local sy=c['floorSizes'][2]/10
    local sizeFact=sim.getObjectSizeFactor(model)
    sim.setObjectParent(floor_e1,-1,true)
    local child=sim.getObjectChild(floorItemsHolder,0)
    while child~=-1 do
        sim.removeObject(child)
        child=sim.getObjectChild(floorItemsHolder,0)
    end
    local xPosInit=(sx-1)*-5*sizeFact
    local yPosInit=(sy-1)*-5*sizeFact
    local f1,f2
    for x=1,sx,1 do
        for y=1,sy,1 do
            if (x==1)and(y==1) then
                sim.setObjectParent(floor_e1,floorItemsHolder,true)
                f1=floor_e1
            else
                f1=sim.copyPasteObjects({floor_e1},0)[1]
                f2=sim.copyPasteObjects({floor_e2},0)[1]
                sim.setObjectParent(f1,floorItemsHolder,true)
                sim.setObjectParent(f2,f1,true)
            end
            local p=sim.getObjectPosition(f1,sim.handle_parent)
            p[1]=xPosInit+(x-1)*10*sizeFact
            p[2]=yPosInit+(y-1)*10*sizeFact
            sim.setObjectPosition(f1,sim.handle_parent,p)
        end
    end
end

function updateFloorUi()
    local c=readInfo()
    local sizeFact=sim.getObjectSizeFactor(model)
    simUI.setLabelText(floorUi,1,'X-size (m): '..simBWF.format("%.2f",c['floorSizes'][1]*sizeFact),true)
    simUI.setSliderValue(floorUi,2,c['floorSizes'][1]/10,true)
    simUI.setLabelText(floorUi,3,'Y-size (m): '..simBWF.format("%.2f",c['floorSizes'][2]*sizeFact),true)
    simUI.setSliderValue(floorUi,4,c['floorSizes'][2]/10,true)
end

function floorSliderXChange(ui,id,newVal)
    local c=readInfo()
    c['floorSizes'][1]=newVal*10
    writeInfo(c)
    updateFloorUi()
    updateFloor()
end

function floorSliderYChange(ui,id,newVal)
    local c=readInfo()
    c['floorSizes'][2]=newVal*10
    writeInfo(c)
    updateFloorUi()
    updateFloor()
end

function showFloorDlg()
    if not floorUi then
    xml = [[
    <group layout="form" flat="true">
        <label text="X-size (m): 1" id="1"/>
        <hslider tick-position="above" tick-interval="1" minimum="1" maximum="5" on-change="floorSliderXChange" id="2"/>
        <label text="Y-size (m): 1" id="3"/>
        <hslider tick-position="above" tick-interval="1" minimum="1" maximum="5" on-change="floorSliderYChange" id="4"/>
    </group>
    <label text="" style="* {margin-left: 400px;}"/>
]]
        floorUi=simBWF.createCustomUi(xml,'Floor',previousFloorDlgPos,false,nil,false,false,false)
        updateFloorUi()
    end
end

function removeFloorDlg()
    if floorUi then
        local x,y=simUI.getPosition(floorUi)
        previousFloorDlgPos={x,y}
        simUI.destroy(floorUi)
        floorUi=nil
    end
end

function showOrHideFloorUiIfNeeded()
    local s=sim.getObjectSelection()
    if s and #s>=1 and s[1]==model then
        showFloorDlg()
    else
        removeFloorDlg()
    end
end
