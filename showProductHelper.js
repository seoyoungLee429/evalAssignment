({
    showToast : function(type, message) {
        var evt = $A.get("e.force:showToast");
        evt.setParams({
            "key" : "info_alt"
            , type : type
            , message : message
        });
        evt.fire();
    },
    getInitData : function(component) {
        var action = component.get("c.getInitData");

        action.setParams({
            recordId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.listOppItem", returnValue[0]);
                component.set("v.listPrdItem", returnValue[1]);
            } else if(state === "ERROR") {
                var errors = response.getError();
                if(errors) {
                    //참고 :에러가 났을경우는 주로 ShowToast 함수를 이용하여 토스트 메시지를 띄움
                } else {
                    
                }
            }
        });
        $A.enqueueAction(action);
    },
    getOppItemListData : function(component) {
        var action = component.get("c.getOppItemListData");

        action.setParams({
            recordId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.listOppItem", returnValue);
            } else if(state === "ERROR") {
                var errors = response.getError();
                if(errors) {
                    //참고 :에러가 났을경우는 주로 ShowToast 함수를 이용하여 토스트 메시지를 띄움
                } else {
                    
                }
            }
        });
        $A.enqueueAction(action);
    },
    saveList : function(component) {
        var listInfo = component.get("v.listOppItem");   
        var flagOk = true;
        listInfo.forEach(element => {
            if(Number(element['Quantity']) == 0 || Number(element['UnitPrice']) == 0 || element['Product2'] == undefined){
                flagOk = false;
            }
        });
        if(flagOk){
            var action = component.get("c.saveList");
            action.setParams({
                listOppItem : listInfo,
                recordId : component.get("v.recordId")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if(state === "SUCCESS") {
                    console.log(':: save SUCCESS :: ');
                } else if(state === "ERROR") {
                    var errors = response.getError();
                    console.log(':: save errors :: '+errors);
                }
            });
            $A.enqueueAction(action);
        }else{
            this.showToast('error','필요 정보 부족'); 
        }        
    },
    callApiForPlus : function(component) {
        var action = component.get("c.callApi");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                var listOppItem = component.get("v.listOppItem");
                var recordId = component.get("v.recordId");
                var oppItemSize = listOppItem.length;
                var seq = oppItemSize+1;
                var plusOppOne = {'SortOrder':seq,'UnitPrice':0,'Quantity':0,'TotalPrice': 0,'OpportunityId':recordId, 'ExchangeRate__c' : Number(returnValue['exchangerate']),'UsdTotalPrice__c' : 0};
                listOppItem.push(plusOppOne);
                component.set('v.listOppItem', listOppItem);
                
            } else if(state === "ERROR") {
                console.log('callApi :: ERROR');
            }else{
                console.log('callApi :: else');
            }
        });
        $A.enqueueAction(action);
        
    },   
    callApiForResetAll : function(component) {

        component.set("v.showSpinner",true);
        this.saveList(component);
        var listOppItem = component.get("v.listOppItem");
        var jobList = component.get("v.jobList");
        listOppItem.forEach(element => {
            var action = component.get("c.exchangerateResetAllandSave");   
            action.setParams({
                oppItem : element,
                recordId : component.get("v.recordId")
            });	
            action.setCallback(this, function(response) {
                var state = response.getState();            
                if(state === "SUCCESS") {
                    var returnValue = response.getReturnValue();
                    jobList.push(returnValue);
                } else if(state === "ERROR") {
                    var errors = response.getError();
                    console.log(':: exchangerateResetAllandSave errors :: '+errors);
                }
            });	
            $A.enqueueAction(action);                    
        }); 	
        // 0.5초 간격으로 메시지를 보여줌
        let timerId = setInterval(() => {
            var action2 = component.get("c.checkQueuedState");   
            action2.setParams({
                jobListInfo : jobList
            });	
            action2.setCallback(this, function(response) {
                var state = response.getState();            
                if(state === "SUCCESS") {
                    var returnValue = response.getReturnValue();
                    if(returnValue){
                        clearInterval(timerId);
                        component.set("v.showSpinner",false);
                        component.set("v.jobList",[]);                   
                        this.getOppItemListData(component);
                    }
                } else if(state === "ERROR") {
                    var errors = response.getError();
                    console.log(':: checkQueuedState errors :: '+errors);
                }
            });
            $A.enqueueAction(action2);
        }, 1000);
        // 50초 후에 정지
        setTimeout(() => { 
            if(component.get("v.showSpinner") == true){
                clearInterval(timerId);
                component.set("v.showSpinner",false);
                component.set("v.jobList",[]);                   
                this.getOppItemListData(component);
        }}, 50000);
        
    },
});