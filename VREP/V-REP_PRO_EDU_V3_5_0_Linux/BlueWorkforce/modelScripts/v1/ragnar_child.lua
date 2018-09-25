function sysCall_suspend()
    simulationPause(true)
end

function sysCall_resume()
    simulationPause(false)
end

function simulationPause(isPause)
    if robotPlot_ui then
        if isPause and lastDataFromRagnar then
            setPlotData(lastDataFromRagnar,1)
            setPlotData(lastDataFromRagnar,2)
            setPlotData(lastDataFromRagnar,3)
        end
        simUI.setMouseOptions(robotPlot_ui,1,isPause,isPause,isPause,isPause)
        simUI.setMouseOptions(robotPlot_ui,2,isPause,isPause,isPause,isPause)
        simUI.setMouseOptions(robotPlot_ui,3,isPause,isPause,isPause,isPause)
    end
    if clearancePlot_ui then
        if isPause and lastClearanceData then
            setClearancePlotData(lastClearanceData,1)
        end
        simUI.setMouseOptions(clearancePlot_ui,1,isPause,isPause,isPause,isPause)
    end
end

function getPlatform()
    local objs=sim.getObjectsInTree(ragnarGripperPlatformAttachment,sim.handle_all,1+2)
    for i=1,#objs,1 do
        if sim.readCustomDataBlock(objs[i],simBWF.RAGNARGRIPPERPLATFORM_TAG) then
            return objs[i]
        end
    end
    return -1
end

function getGripper(thePlatform)
    if thePlatform>=0 then
        local objs=sim.getObjectsInTree(thePlatform,sim.handle_all,1)
        for i=1,#objs,1 do
            if sim.readCustomDataBlock(objs[i],simBWF.RAGNARGRIPPER_TAG) then
                return objs[i]
            end
        end
    end
    return -1
end

function executeIk()
    if platform>=0 then
        for i=1,4,1 do
            -- We handle each branch individually:
            local ld=sim.getLinkDummy(ikTips[i])
            if ld>=0 then
                -- We make sure we don't perform too large jumps:
                local p=sim.getObjectPosition(ikTips[i],ld)
                local l=math.sqrt(p[1]*p[1]+p[2]*p[2]+p[3]*p[3])
                local steps=math.ceil(0.00001+l/0.05)
                local start=sim.getObjectPosition(ikTips[i],-1)
                local goal=sim.getObjectPosition(ld,-1)
                for j=1,steps,1 do
                    local t=j/steps
                    local pos={start[1]*(1-t)+goal[1]*t,start[2]*(1-t)+goal[2]*t,start[3]*(1-t)+goal[3]*t}
                    sim.setObjectPosition(ld,-1,pos)
                    sim.handleIkGroup(ikGroups[i])
                end
            end
        end
    end
end

function setPlatformPose(pos,orient)
    if platform>=0 then
        sim.setObjectPosition(platform,sim.handle_parent,pos)
        sim.setObjectOrientation(platform,sim.handle_parent,orient)
        executeIk()
    end
end

function getPlatformPose()
    if platform>=0 then
        local pos=sim.getObjectPosition(platform,sim.handle_parent)
        local orient=sim.getObjectOrientation(platform,sim.handle_parent)
        return pos,orient
    end
end

function enableRagnar()
    if bwfPluginLoaded then
        if not savedJoints then
            savedJoints={}
            local allJoints=sim.getObjectsInTree(model,sim.object_joint_type,1)
            for i=1,#allJoints,1 do
                savedJoints[allJoints[i]]=sim.getJointPosition(allJoints[i])
            end    
            local data={}
            data.id=model
            data.bufferSize=connectionBufferSize
            simBWF.query('ragnar_connect',data)
        end
    end
end

function disableRagnar()
    if savedJoints then
        local data={}
        data.id=model
        simBWF.query('ragnar_disconnect',data)
        for key,value in pairs(savedJoints) do
            sim.setJointPosition(key,value)
        end
        savedJoints=nil
    end
end

function setPlotData(dataFromRagnar,plotId)
    if robotPlot_ui then
        if plotId==1 then
            for i=1,4,1 do
                local label='axis'..i
                simUI.clearCurve(robotPlot_ui,1,label)
                if #dataFromRagnar.timeStamps>0 then
                    simUI.addCurveTimePoints(robotPlot_ui,1,label,dataFromRagnar.timeStamps,dataFromRagnar.motorAngles[i])
                end
            end
            simUI.rescaleAxesAll(robotPlot_ui,1,false,false)
            simUI.replot(robotPlot_ui,1)
        end
        if plotId==2 then
            for i=1,4,1 do
                local label='axis'..i
                simUI.clearCurve(robotPlot_ui,2,label)
                if #dataFromRagnar.timeStamps>0 then
                    simUI.addCurveTimePoints(robotPlot_ui,2,label,dataFromRagnar.timeStamps,dataFromRagnar.motorErrors[i])
                end
            end
            simUI.rescaleAxesAll(robotPlot_ui,2,false,false)
            simUI.replot(robotPlot_ui,2)
        end
        if plotId==3 then
            simUI.clearCurve(robotPlot_ui,3,'X')
            simUI.clearCurve(robotPlot_ui,3,'Y')
            simUI.clearCurve(robotPlot_ui,3,'Z')
            simUI.clearCurve(robotPlot_ui,3,'Rot')
            simUI.clearCurve(robotPlot_ui,3,'Gripper close')
            simUI.clearCurve(robotPlot_ui,3,'Gripper open')
            simUI.addCurveTimePoints(robotPlot_ui,3,'X',dataFromRagnar.timeStamps,dataFromRagnar.platformPose[1])
            simUI.addCurveTimePoints(robotPlot_ui,3,'Y',dataFromRagnar.timeStamps,dataFromRagnar.platformPose[2])
            simUI.addCurveTimePoints(robotPlot_ui,3,'Z',dataFromRagnar.timeStamps,dataFromRagnar.platformPose[3])
            simUI.addCurveTimePoints(robotPlot_ui,3,'Rot',dataFromRagnar.timeStamps,dataFromRagnar.platformPose[6])
            simUI.addCurveTimePoints(robotPlot_ui,3,'Gripper close',dataFromRagnar.gripperClose.t,dataFromRagnar.gripperClose.v)
            simUI.addCurveTimePoints(robotPlot_ui,3,'Gripper open',dataFromRagnar.gripperOpen.t,dataFromRagnar.gripperOpen.v)
            simUI.rescaleAxesAll(robotPlot_ui,3,false,false)
 --           simUI.growPlotYRange(robotPlot_ui,3,min,max)
            simUI.replot(robotPlot_ui,3)
        end
    end
end

function setClearancePlotData(clearanceData,plotId)
    if clearancePlot_ui then
        if plotId==1 then
            simUI.clearCurve(clearancePlot_ui,1,'Clearance')
            if #clearanceData.times>0 then
                simUI.addCurveTimePoints(clearancePlot_ui,1,'Clearance',clearanceData.times,clearanceData.clearances)
            end
            simUI.rescaleAxesAll(clearancePlot_ui,1,false,false)
            simUI.replot(clearancePlot_ui,1)
        end
    end
end

function getAndApplyRagnarState()
    if savedJoints then
    
        if not gripperActionBuffer then
            gripperActionBuffer={}
            gripperActionBuffer.close={t={},v={}}
            gripperActionBuffer.open={t={},v={}}
        end

        local getData=false
        if online then    
            local dt=sim.getSystemTimeInMs(lastMoveVisualizeUpdateTimeInMs)
            if dt>moveVisUpdateFrequMs then
                getData=true
                lastMoveVisualizeUpdateTimeInMs=sim.getSystemTimeInMs(-1)
            end
        else
            local t=(sim.getSimulationTime()+sim.getSimulationTimeStep())*1000
            if t+1>lastMoveVisualizeUpdateTimeInMs+moveVisUpdateFrequMs then
                getData=true
                lastMoveVisualizeUpdateTimeInMs=t
            end
        end
        
        if getData then
            local updatePlot=false
            if online then    
                local dt=sim.getSystemTimeInMs(lastPlotVisualizeUpdateTimeInMs)
                if dt>plotVisUpdateFrequMs then
                    updatePlot=true
                    lastPlotVisualizeUpdateTimeInMs=sim.getSystemTimeInMs(-1)
                end
            else
                local t=(sim.getSimulationTime()+sim.getSimulationTimeStep())*1000
                if t+1>lastPlotVisualizeUpdateTimeInMs+plotVisUpdateFrequMs then
                    updatePlot=true
                    lastPlotVisualizeUpdateTimeInMs=t
                end
            end
        
            if not showTrajectory then
                sim.addDrawingObjectItem(graspCloseDrawingObject,nil) -- empty the cont.
                sim.addDrawingObjectItem(graspOpenDrawingObject,nil) -- empty the cont.
            end

            local data={}
            data.id=model
            data.stateCount=connectionBufferSize
            data.posMultiplier=1000 -- for string buffers only!
            data.angleMultiplier=180/math.pi -- for string buffers only!
            local res,retData=simBWF.query('ragnar_getStates',data)
            
            if res=='ok' then
                dataFromRagnar=retData
            else
                if simBWF.isInTestMode() then
                    -- Generate fake data:
                    if not blabla then
                        blabla=0
                    end
                    blabla=blabla+0.05
                    dataFromRagnar={}
                    dataFromRagnar.timeStamps={}
                    dataFromRagnar.motorAngles={{},{},{},{},{}}
                    dataFromRagnar.motorErrors={{},{},{},{},{}}
                    dataFromRagnar.platformPose={{},{},{},{},{},{}}
                    local blabli=0
                    for i=1,connectionBufferSize,1 do
                        dataFromRagnar.timeStamps[i]=blabla+0.01*i
                        for j=1,5,1 do
                            dataFromRagnar.motorAngles[j][i]=math.sin(dataFromRagnar.timeStamps[i]*(1+0.1*j))
                            dataFromRagnar.motorErrors[j][i]=math.sin(dataFromRagnar.timeStamps[i]*(1+0.1*j))
                        end
                        
                        blabli=blabli+0.05
                        dataFromRagnar.platformPose[1][i]=math.sin(blabli+blabla*1.0)*primaryArmLengthInMM/1000
                        dataFromRagnar.platformPose[2][i]=math.sin(blabli+blabla*1.3)*primaryArmLengthInMM*0.7/1000
                        dataFromRagnar.platformPose[3][i]=-(secondaryArmLengthInMM-primaryArmLengthInMM+300)/1000+math.sin(blabla*0.6)*0.1
                        dataFromRagnar.platformPose[4][i]=0
                        dataFromRagnar.platformPose[5][i]=0
                        dataFromRagnar.platformPose[6][i]=0
                    end
                    dataFromRagnar.stateCount=connectionBufferSize
                    
                    -- Pack the data:
                    dataFromRagnar.timeStamps=sim.packFloatTable(dataFromRagnar.timeStamps)
                    for i=1,5,1 do
                        dataFromRagnar.motorAngles[i]=sim.packFloatTable(dataFromRagnar.motorAngles[i])
                        dataFromRagnar.motorErrors[i]=sim.packFloatTable(dataFromRagnar.motorErrors[i])
                    end
                    for i=1,6,1 do
                        dataFromRagnar.platformPose[i]=sim.packFloatTable(dataFromRagnar.platformPose[i])
                    end
                    
                else
                    dataFromRagnar=nil
                end
            end
            if dataFromRagnar then
                -- Unpack the data and scale it appropriately:
                dataFromRagnar.timeStamps=sim.unpackFloatTable(dataFromRagnar.timeStamps)
                for i=1,5,1 do
                    dataFromRagnar.motorAngles[i]=sim.transformBuffer(dataFromRagnar.motorAngles[i],sim.buffer_float,data.angleMultiplier,0,sim.buffer_float)
                    dataFromRagnar.motorAngles[i]=sim.unpackFloatTable(dataFromRagnar.motorAngles[i])
                end
                for i=1,5,1 do
                    dataFromRagnar.motorErrors[i]=sim.transformBuffer(dataFromRagnar.motorErrors[i],sim.buffer_float,data.angleMultiplier,0,sim.buffer_float)
                    dataFromRagnar.motorErrors[i]=sim.unpackFloatTable(dataFromRagnar.motorErrors[i])
                end
                for i=1,3,1 do
                    dataFromRagnar.platformPose[i]=sim.transformBuffer(dataFromRagnar.platformPose[i],sim.buffer_float,data.posMultiplier,0,sim.buffer_float)
                    dataFromRagnar.platformPose[i]=sim.unpackFloatTable(dataFromRagnar.platformPose[i])
                end
                for i=4,6,1 do
                    dataFromRagnar.platformPose[i]=sim.transformBuffer(dataFromRagnar.platformPose[i],sim.buffer_float,data.angleMultiplier,0,sim.buffer_float)
                    dataFromRagnar.platformPose[i]=sim.unpackFloatTable(dataFromRagnar.platformPose[i])
                end
            end
            
            if dataFromRagnar and #dataFromRagnar.timeStamps>1 then
                local pp=dataFromRagnar.platformPose
                local dataCnt=#dataFromRagnar.timeStamps
                
                if updatePlot then -- clearance
                   if previousClearanceFlag and previousClearanceEveryStepFlag then
                        lastClearanceData.times={}
                        lastClearanceData.clearances={}
                        local collection1=robotArmCollection
                        if previousClearanceIncludePlatformFlag then
                            collection1=robotArmAndPlatformCollection
                        end
                        for i=1,dataCnt,1 do
                            local pos={pp[1][i]/data.posMultiplier,pp[2][i]/data.posMultiplier,pp[3][i]/data.posMultiplier}
                            local orient={pp[4][i]/data.angleMultiplier,pp[5][i]/data.angleMultiplier,pp[6][i]/data.angleMultiplier}
                            setPlatformPose(pos,orient)
                            local res,distData=sim.checkDistance(collection1,robotObstaclesCollection,0)
                            if res>0 then
                                lastClearanceData.times[i]=dataFromRagnar.timeStamps[i]
                                lastClearanceData.clearances[i]=distData[7]
                            end
                        end
                    end
                end
                
                
                local currentPos={pp[1][dataCnt]/data.posMultiplier,pp[2][dataCnt]/data.posMultiplier,pp[3][dataCnt]/data.posMultiplier}
                local currentOrient={pp[4][dataCnt]/data.angleMultiplier,pp[5][dataCnt]/data.angleMultiplier,pp[6][dataCnt]/data.angleMultiplier}
                setPlatformPose(currentPos,currentOrient)
                if updatePlot then
                    sim.addDrawingObjectItem(trajectoryDrawingObject,nil) -- empty the cont.
                    if showTrajectory then
                        local m=sim.getObjectMatrix(ragnarRef,-1)
                        local w={dataFromRagnar.platformPose[1][dataCnt]/data.posMultiplier,dataFromRagnar.platformPose[2][dataCnt]/data.posMultiplier,dataFromRagnar.platformPose[3][dataCnt]/data.posMultiplier}
                        w=sim.multiplyVector(m,w)
                        local mm=math.max(dataCnt-100,1)
                        for i=dataCnt-1,mm,-1 do
                            local v={dataFromRagnar.platformPose[1][i]/data.posMultiplier,dataFromRagnar.platformPose[2][i]/data.posMultiplier,dataFromRagnar.platformPose[3][i]/data.posMultiplier}
                            v=sim.multiplyVector(m,v)
                            local dt=dataFromRagnar.timeStamps[i+1]-dataFromRagnar.timeStamps[i]
                            local l=simBWF.getPtPtDistance(v,w)
                            local speed=0
                            if dt>0 then
                                speed=l/dt
                            end
                            local c=getColorFromIntensity(speed/maxSpeed)
                            local data={v[1],v[2],v[3],w[1],w[2],w[3],c[1],c[2],c[3]}
                            sim.addDrawingObjectItem(trajectoryDrawingObject,data)
                            w=v
                        end
                    end
                    
                    if robotPlot_ui then
                        dataFromRagnar.gripperOpen=gripperActionBuffer.open
                        dataFromRagnar.gripperClose=gripperActionBuffer.close
                        setPlotData(dataFromRagnar,simUI.getCurrentTab(robotPlot_ui,77)+1)
                        lastDataFromRagnar=dataFromRagnar
                    end
                end
            end
        end
        -- Now take care of the gripper actions (in each simulation step):
        if not dataFromRagnar then
            dataFromRagnar={}
        end
        local data={}
        data.id=model
        local res,retData=simBWF.query('ragnar_getGripperAction',data)
        if res~='ok' then
            if simBWF.isInTestMode() then
                -- Generate fake data:
                if not fakeActionStage then
                    fakeActionStage=0
                end
                retData.gripperAction=-1 -- means no action
                if sim.getSimulationTime()>5 and fakeActionStage==0 then
                    retData.gripperAction=1
                    fakeActionStage=1
                end
                if sim.getSimulationTime()>15 and fakeActionStage==1 then
                    retData.gripperAction=0
                    fakeActionStage=2
                end
                local currentPos,currentOrient=getPlatformPose()
                retData.platformPosAtAction=currentPos
                retData.platformYprAtAction=currentOrient
                retData.gripperActionTime=0
                retData.timeStamp=0
            else
                retData=nil
            end
        end
        if retData then
            if retData.gripperAction~=-1 then
                -- Gripping state changed
                local dat={}
                dat[1]=retData.gripperAction
                dat[2]={retData.platformPosAtAction[1],retData.platformPosAtAction[2],retData.platformPosAtAction[3]}
                dat[3]={retData.platformYprAtAction[1],retData.platformYprAtAction[2],retData.platformYprAtAction[3]}
                dat[4]=retData.timeStamp-retData.gripperActionTime
                dat[5]=platform
                dat[6]=ragnarRef
                simBWF.callCustomizationScriptFunction('ext_attachOrDetachDetectedPart',gripper,dat)
                
                if showTrajectory then
                    local m=sim.getObjectMatrix(ragnarRef,-1)
                    local p=sim.multiplyVector(m,dat[2])
                    if retData.gripperAction==1 then
                        sim.addDrawingObjectItem(graspCloseDrawingObject,p)
                    else
                        sim.addDrawingObjectItem(graspOpenDrawingObject,p)
                    end
                end
                
                -- Buffer the open/close actions and their time/pos:
                local co=nil
                if retData.gripperAction==1 then
                    co=gripperActionBuffer.close
--                    setPlatformColor({1,0,1})
                end
                if retData.gripperAction==0 then
                    co=gripperActionBuffer.open
--                    setPlatformColor(platformOriginalCol)
                end
                if co then
                    co.t[#co.t+1]=retData.gripperActionTime
                    co.v[#co.v+1]=retData.platformPosAtAction[1]
                    
                    co.t[#co.t+1]=retData.gripperActionTime
                    co.v[#co.v+1]=retData.platformPosAtAction[2]
                    
                    co.t[#co.t+1]=retData.gripperActionTime
                    co.v[#co.v+1]=retData.platformPosAtAction[3]
                end

                -- Remove old gripper actions in the buffer:
                if lastDataFromRagnar and lastDataFromRagnar.timeStamps and #lastDataFromRagnar.timeStamps>0 then
                    while #gripperActionBuffer.close.t>0 and gripperActionBuffer.close.t[1]<lastDataFromRagnar.timeStamps[1] do
                        table.remove(gripperActionBuffer.close.t,1)
                        table.remove(gripperActionBuffer.close.v,1)
                    end
                    while #gripperActionBuffer.open.t>0 and gripperActionBuffer.open.t[1]<lastDataFromRagnar.timeStamps[1] do
                        table.remove(gripperActionBuffer.open.t,1)
                        table.remove(gripperActionBuffer.open.v,1)
                    end
                end
            end
        end
    end
end

function startShowingPlotFromRobot()
    if savedJoints and not robotPlot_ui then
        local xml=[[<tabs id="77">
                <tab title="Axes angles">
                <plot id="1" max-buffer-size="100000" cyclic-buffer="false" background-color="25,25,25" foreground-color="150,150,150"/>
                </tab>
                <tab title="Axes angular errors">
                <plot id="2" max-buffer-size="100000" cyclic-buffer="false" background-color="25,25,25" foreground-color="150,150,150"/>
                </tab>
                <tab title="Platform position">
                <plot id="3" max-buffer-size="100000" cyclic-buffer="false" background-color="25,25,25" foreground-color="150,150,150"/>
                </tab>
            </tabs>]]
        local prevPos,prevSize=simBWF.readSessionPersistentObjectData(model,"ragnarPlotPosAndSize"..simOrRealIndex)
        if not prevPos then
            prevPos="bottomRight"
        end
        robotPlot_ui=simBWF.createCustomUi(xml,simBWF.getObjectAltName(model),prevPos,true,"stopShowingPlotFromRobot_callback",false,true,false,nil,prevSize)
        simUI.setPlotLabels(robotPlot_ui,1,"time (seconds)","degrees")
        simUI.setPlotLabels(robotPlot_ui,2,"time (seconds)","degrees")
        simUI.setPlotLabels(robotPlot_ui,3,"time (seconds)","millimeters and degrees")
        if not plotTabIndex then
            plotTabIndex=0
        end
        simUI.setCurrentTab(robotPlot_ui,77,plotTabIndex,true)

        local curveStyle=simUI.curve_style.line
        local scatterShape={scatter_shape=simUI.curve_scatter_shape.none,scatter_size=5,line_size=1,add_to_legend=true,selectable=true,track=false}
        simUI.addCurve(robotPlot_ui,1,simUI.curve_type.time,'axis1',{255,0,0},curveStyle,scatterShape)
        simUI.addCurve(robotPlot_ui,1,simUI.curve_type.time,'axis2',{0,255,0},curveStyle,scatterShape)
        simUI.addCurve(robotPlot_ui,1,simUI.curve_type.time,'axis3',{0,128,255},curveStyle,scatterShape)
        simUI.addCurve(robotPlot_ui,1,simUI.curve_type.time,'axis4',{255,255,0},curveStyle,scatterShape)
        simUI.setLegendVisibility(robotPlot_ui,1,true)
        simUI.setMouseOptions(robotPlot_ui,1,false,false,false,false)
        simUI.addCurve(robotPlot_ui,2,simUI.curve_type.time,'axis1',{255,0,0},curveStyle,scatterShape)
        simUI.addCurve(robotPlot_ui,2,simUI.curve_type.time,'axis2',{0,255,0},curveStyle,scatterShape)
        simUI.addCurve(robotPlot_ui,2,simUI.curve_type.time,'axis3',{0,128,255},curveStyle,scatterShape)
        simUI.addCurve(robotPlot_ui,2,simUI.curve_type.time,'axis4',{255,255,0},curveStyle,scatterShape)
        simUI.setLegendVisibility(robotPlot_ui,2,true)
        simUI.setMouseOptions(robotPlot_ui,2,false,false,false,false)
        simUI.addCurve(robotPlot_ui,3,simUI.curve_type.time,'X',{255,0,0},curveStyle,scatterShape)
        simUI.addCurve(robotPlot_ui,3,simUI.curve_type.time,'Y',{0,255,0},curveStyle,scatterShape)
        simUI.addCurve(robotPlot_ui,3,simUI.curve_type.time,'Z',{0,128,255},curveStyle,scatterShape)
        simUI.addCurve(robotPlot_ui,3,simUI.curve_type.time,'Rot',{255,255,0},curveStyle,scatterShape)
        simUI.addCurve(robotPlot_ui,3,simUI.curve_type.time,'Gripper close',{255,0,255},simUI.curve_style.scatter,{scatter_shape=simUI.curve_scatter_shape.circle,scatter_size=10,line_size=1,add_to_legend=true,selectable=true,track=false})
        simUI.addCurve(robotPlot_ui,3,simUI.curve_type.time,'Gripper open',{0,255,255},simUI.curve_style.scatter,{scatter_shape=simUI.curve_scatter_shape.circle,scatter_size=10,line_size=1,add_to_legend=true,selectable=true,track=false})
        simUI.setLegendVisibility(robotPlot_ui,3,true)
        simUI.setMouseOptions(robotPlot_ui,3,false,false,false,false)
    end
end

function stopShowingPlotFromRobot_callback()
    robotPlotWasClosed=true
    stopShowingPlotFromRobot()
end

function stopShowingPlotFromRobot()
    if robotPlot_ui then
        local x,y=simUI.getPosition(robotPlot_ui)
        local xs,ys=simUI.getSize(robotPlot_ui)
        simBWF.writeSessionPersistentObjectData(model,"ragnarPlotPosAndSize"..simOrRealIndex,{x,y},{xs,ys})
        plotTabIndex=simUI.getCurrentTab(robotPlot_ui,77)
        simUI.destroy(robotPlot_ui)
        robotPlot_ui=nil
    end
end

function startShowingClearancePlot()
    if not clearancePlot_ui then
        local xml=[[
                <plot id="1" max-buffer-size="100000" cyclic-buffer="false" background-color="25,25,25" foreground-color="150,150,150"/>
                ]]
        local prevPos,prevSize=simBWF.readSessionPersistentObjectData(model,"ragnarClearancePlotPosAndSize")
        if not prevPos then
            prevPos="bottomRight"
        end
        clearancePlot_ui=simBWF.createCustomUi(xml,simBWF.getObjectAltName(model).." Clearance",prevPos,true,"stopShowingClearancePlot_callback",false,true,false,nil,prevSize)
        simUI.setPlotLabels(clearancePlot_ui,1,"time (seconds)","meters")

        local curveStyle=simUI.curve_style.line
        local scatterShape={scatter_shape=simUI.curve_scatter_shape.none,scatter_size=5,line_size=1,add_to_legend=true,selectable=true,track=false}
        simUI.addCurve(clearancePlot_ui,1,simUI.curve_type.time,'Clearance',{255,255,0},curveStyle,scatterShape)
        simUI.setLegendVisibility(clearancePlot_ui,1,true)
        simUI.setMouseOptions(clearancePlot_ui,1,false,false,false,false)
    end
end

function stopShowingClearancePlot_callback()
    clearancePlotWasClosed=true
    stopShowingClearancePlot()
end

function stopShowingClearancePlot()
    if clearancePlot_ui then
        local x,y=simUI.getPosition(clearancePlot_ui)
        local xs,ys=simUI.getSize(clearancePlot_ui)
        simBWF.writeSessionPersistentObjectData(model,"ragnarClearancePlotPosAndSize",{x,y},{xs,ys})
        simUI.destroy(clearancePlot_ui)
        clearancePlot_ui=nil
    end
end

function getColorFromIntensity(intensity)
    local col={0.16,0.16,0.16,0.16,0.16,1,1,0.16,0.16,1,1,0.16}
    if intensity>1 then intensity=1 end
    if intensity<0 then intensity=0 end
    intensity=math.exp(4*(intensity-1))
    local d=math.floor(intensity*3)
    if (d>2) then d=2 end
    local r=(intensity-d/3)*3
    local coll={}
    coll[1]=col[3*d+1]*(1-r)+col[3*(d+1)+1]*r
    coll[2]=col[3*d+2]*(1-r)+col[3*(d+1)+2]*r
    coll[3]=col[3*d+3]*(1-r)+col[3*(d+1)+3]*r
    return coll
end

function sysCall_init()
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    ikTips={}
    for i=1,4,1 do
        ikTips[i]=sim.getObjectHandle('Ragnar_secondaryArm'..i..'a_tip')
    end
    ragnarRef=sim.getObjectHandle('Ragnar_ref')
    ragnarGripperPlatformAttachment=sim.getObjectHandle('Ragnar_gripperPlatformAttachment')
    ikGroups={}
    for i=1,4,1 do
        ikGroups[i]=sim.getIkGroupHandle('ragnarIk_arm'..i)
    end
    platform=getPlatform()
    gripper=getGripper(platform)
    robotArmCollection=sim.getCollectionHandle("RagnarArms")
    robotArmAndPlatformCollection=sim.getCollectionHandle("RagnarArmsAndPlatform")
    robotObstaclesCollection=sim.getCollectionHandle("RagnarObstacles")
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    online=simBWF.isSystemOnline()
    simOrRealIndex=1
    lastMoveVisualizeUpdateTimeInMs=-1000
    lastPlotVisualizeUpdateTimeInMs=-1000
    lastClearancePlotVisualizeUpdateTimeInMs=-1000
    if online then
        simOrRealIndex=2
        lastMoveVisualizeUpdateTimeInMs=sim.getSystemTimeInMs(-1)-1000
        lastPlotVisualizeUpdateTimeInMs=sim.getSystemTimeInMs(-1)-1000
        lastClearancePlotVisualizeUpdateTimeInMs=sim.getSystemTimeInMs(-1)-1000
    end
    local properties=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.RAGNAR_TAG))
    connectionBufferSize=properties['connectionBufferSize'][simOrRealIndex]
    primaryArmLengthInMM=properties['primaryArmLengthInMM']
    secondaryArmLengthInMM=properties['secondaryArmLengthInMM']
    trajectoryDrawingObject=sim.addDrawingObject(sim.drawing_lines+sim.drawing_itemcolors+sim.drawing_emissioncolor+sim.drawing_cyclic,3,0,-1,1000)
    graspCloseDrawingObject=sim.addDrawingObject(sim.drawing_spherepoints+sim.drawing_cyclic,0.005,0,-1,1,{1,0,1})
    graspOpenDrawingObject=sim.addDrawingObject(sim.drawing_spherepoints+sim.drawing_cyclic,0.005,0,-1,1,{0,1,1})
    --[[
    if platform>=0 then
        if properties.gripperActionsWithColorChange[simOrRealIndex] then
            local obj=sim.getObjectsInTree(platform,sim.object_shape_type,0)
            for i=1,#obj,1 do
                local res,col=sim.getShapeColor(obj[i],'RAGNARPLATFORM',sim.colorcomponent_ambient)
                if res>0 then
                    platformOriginalCol=col
                    lastPlatformColor=col
                    platformShape=obj[i]
                    break
                end
            end
        end
    end
    --]]
    lastClearanceData={}
    lastClearanceData.times={}
    lastClearanceData.clearances={}
    robotPlotWasClosed=false
    clearancePlotWasClosed=false
    previousClearanceFlag=properties.clearance[simOrRealIndex]
    previousClearanceIncludePlatformFlag=properties.clearanceWithPlatform[simOrRealIndex]
    previousClearanceEveryStepFlag=properties.clearanceForAllSteps[simOrRealIndex]
    previousClearanceValue=0
    enableRagnar()
end


function sysCall_customCallback1()
    local properties=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.RAGNAR_TAG))
    showTrajectory=properties.showTrajectory[simOrRealIndex]
    maxSpeed=properties.maxVel
    local delaysInMs={50,200,200}
    moveVisUpdateFrequMs=delaysInMs[properties.visualizeUpdateFrequ[simOrRealIndex]+1]
    local delaysInMs={50,200,1000}
    plotVisUpdateFrequMs=delaysInMs[properties.visualizeUpdateFrequ[simOrRealIndex]+1]
    if properties.showPlot[simOrRealIndex] then
        if not robotPlotWasClosed then
            startShowingPlotFromRobot()
        end
    else
        robotPlotWasClosed=false
        stopShowingPlotFromRobot()
    end
    if properties.clearance[simOrRealIndex] then
        if not clearancePlotWasClosed then
            startShowingClearancePlot()
        end
    else
        clearancePlotWasClosed=false
        stopShowingClearancePlot()
    end
    getAndApplyRagnarState()
end


function sysCall_sensing()
    if not online then
        local properties=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.RAGNAR_TAG))
        local clearBuff=false
        if previousClearanceIncludePlatformFlag~=properties.clearanceWithPlatform[simOrRealIndex] then
            clearBuff=true
        end
        if previousClearanceEveryStepFlag~=properties.clearanceForAllSteps[simOrRealIndex] then
            clearBuff=true
        end
        previousClearanceFlag=properties.clearance[simOrRealIndex]
        previousClearanceIncludePlatformFlag=properties.clearanceWithPlatform[simOrRealIndex]
        previousClearanceEveryStepFlag=properties.clearanceForAllSteps[simOrRealIndex]
        if clearBuff then
            lastClearanceData.times={}
            lastClearanceData.clearances={}
        end
        
        if properties.clearance[simOrRealIndex] and not properties.clearanceForAllSteps[simOrRealIndex] then
            local collection1=robotArmCollection
            if properties.clearanceWithPlatform[simOrRealIndex] then
                collection1=robotArmAndPlatformCollection
            end
            local res,distData=sim.checkDistance(collection1,robotObstaclesCollection,0)
            local clearanceValue=distData[7]
            if res>0 then
                lastClearanceData.times[#lastClearanceData.times+1]=sim.getSimulationTime()
                lastClearanceData.clearances[#lastClearanceData.clearances+1]=clearanceValue
                while #lastClearanceData.times>200 do
                    table.remove(lastClearanceData.times,1)
                    table.remove(lastClearanceData.clearances,1)
                end
                if properties.clearanceWarning[simOrRealIndex]>0 then
                    if previousClearanceValue>properties.clearanceWarning[simOrRealIndex] and clearanceValue<=properties.clearanceWarning[simOrRealIndex] then
                        local nm=' ['..simBWF.getObjectAltName(model)..']'
                        simBWF.outputMessage("WARNING (run-time): Clearance threshold triggered"..nm)
                    end
                end
                previousClearanceValue=clearanceValue
            end
        end
        local updatePlot=false
        local t=(sim.getSimulationTime()+sim.getSimulationTimeStep())*1000
        if t+1>lastClearancePlotVisualizeUpdateTimeInMs+plotVisUpdateFrequMs then
            updatePlot=true
            lastClearancePlotVisualizeUpdateTimeInMs=t
        end
        if updatePlot then
            setClearancePlotData(lastClearanceData,1)
        end
    end
end
--[[
function setPlatformColor(col)
    if platformShape then
        for i=1,3,1 do
            if col[i]~=lastPlatformColor then
                sim.setShapeColor(platformShape,'RAGNARPLATFORM',sim.colorcomponent_ambient,col)
                lastPlatformColor=col
                break
            end
        end
    end
end
--]]
function sysCall_cleanup()
--    setPlatformColor(platformOriginalCol)
    stopShowingPlotFromRobot()
    stopShowingClearancePlot()
    disableRagnar()
end

