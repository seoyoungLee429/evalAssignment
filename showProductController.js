({
    fnInit : function(component, event, helper) {
        helper.getInitData(component);
    },    
    fnCancel : function(component, event, helper){
        //화면 테이블 변경한 것 되돌리기
        helper.getOppItemListData(component);
    },
    fnPlus : function(component, event, helper){
        helper.callApiForPlus(component);     
    },
    fnResetExAll : function(component, event, helper){
        helper.callApiForResetAll(component);
    },
    fnSearchProduct: function(component, event, helper){
        
        var value = event.getSource().get("v.value");
        component.set('v.selectedItem', value);
        component.set('v.modalFlag', true);        
    },        
    fnSave :function(component, event, helper){     
        helper.saveList(component);                
    },
    fnRemoveItem: function(component, event, helper){   
        var idx = event.getSource().get("v.value");
        
        var listOppItem = component.get("v.listOppItem");
        listOppItem.splice(idx,1);      
        for(var i=1;i<=listOppItem.length ; i++){
            listOppItem[i-1].SortOrder = i;
        }
        component.set('v.listOppItem', listOppItem);
        
    },
    fnUnitPriceCh: function(component, event, helper){        
        var idx = event.getSource().get("v.id");
        var listOppItem = component.get("v.listOppItem");
        var thisItem = listOppItem[idx];
        thisItem['TotalPrice'] = thisItem.UnitPrice * thisItem.Quantity;
        thisItem['UsdTotalPrice__c'] = (thisItem.TotalPrice * (1/thisItem.ExchangeRate__c)).toFixed(2); //TotalPrice * (1 / Exchange Rate)
        component.set('v.listOppItem', listOppItem);        
    },
    fnQuantityCh: function(component, event, helper){      
        var idx = event.getSource().get("v.id");
        var listOppItem = component.get("v.listOppItem");
        var thisItem = listOppItem[idx];
        thisItem['TotalPrice']=thisItem.UnitPrice * thisItem.Quantity;
        thisItem['UsdTotalPrice__c'] = (thisItem.TotalPrice * (1/thisItem.ExchangeRate__c)).toFixed(2); //TotalPrice * (1 / Exchange Rate)
        component.set('v.listOppItem', listOppItem);        
    },
    fnMoveUp: function(component, event, helper){      
        var idx = event.getSource().get("v.value");
        var listOppItem = component.get("v.listOppItem");
        var upItem = listOppItem[idx-1];
        var upItemSortOrder = listOppItem[idx-1].SortOrder;
        var thisItem = listOppItem[idx];
        var thisItemSortOrder = listOppItem[idx].SortOrder;
        upItem['SortOrder'] = thisItemSortOrder;
        thisItem['SortOrder'] = upItemSortOrder;
        listOppItem.splice(idx-1,1,thisItem);
        listOppItem.splice(idx,1,upItem);
        component.set('v.listOppItem', listOppItem);
        
    },   
    fnMoveDown: function(component, event, helper){      
        var idx = event.getSource().get("v.value");
        var listOppItem = component.get("v.listOppItem");
        var thisItem = listOppItem[idx];
        var thisItemSortOrder = listOppItem[idx].SortOrder;
        var downItem = listOppItem[idx+1];
        var downItemSortOrder = listOppItem[idx+1].SortOrder;
        downItem['SortOrder'] = thisItemSortOrder;
        thisItem['SortOrder'] = downItemSortOrder;
        listOppItem.splice(idx,1,downItem);
        listOppItem.splice(idx+1,1,thisItem);
        component.set('v.listOppItem', listOppItem);
        
    },
    fnColseModal: function(component, event, helper){     
        component.set('v.selectedPrdName', '');
        component.set('v.selectedPrdPrice', '');
        component.set('v.selectedPrdId', '');
        component.set('v.modalFlag', false);
        
    },
    fnChoosePrd: function(component, event, helper){
        var value = event.getSource().get("v.value");
        var val1 = value.split('>>')[0].trim();
        var val2 = value.split('>>')[1].trim();
        var val3 = value.split('>>')[2].trim();
        component.set('v.selectedPrdId', val1); 
        component.set('v.selectedPrdName', val2);
        component.set('v.selectedPrdPrice', val3);
        
              
    },
    fnSelectPrd: function(component, event, helper){     
        var listOppItem = component.get("v.listOppItem");        
        var listPrdItem = component.get("v.listPrdItem");               
        var selectedPrdName = component.get('v.selectedPrdName');
        var selectedPrdPrice = component.get('v.selectedPrdPrice');
        var selectedPrdId = component.get('v.selectedPrdId');
        if(selectedPrdName == '' || selectedPrdPrice == '' || selectedPrdId ==  ''){
            selectedPrdName = listPrdItem[0].Name;
            selectedPrdPrice = listPrdItem[0].UnitPrice;
            selectedPrdId = listPrdItem[0].Product2Id;
        }
        var selectedItem = component.get("v.selectedItem");
        selectedItem['Product2'] = {'Name':selectedPrdName,'Id':selectedPrdId};
        selectedItem['ListPrice'] = Number(selectedPrdPrice);    
        selectedItem['Product2Id'] = selectedPrdId;
        console.log('selectedItem ==>'+selectedItem);
        console.log('selectedItem.SortOrder ==>'+selectedItem.SortOrder);
        var idx = Number(selectedItem.SortOrder-1);        
        listOppItem.splice(idx, 1, selectedItem);
        component.set('v.listOppItem', listOppItem);
        component.set('v.selectedPrdName', '');
        component.set('v.selectedPrdPrice', '');
        component.set('v.selectedPrdId', '');
        component.set('v.modalFlag', false);
        
    },   
});