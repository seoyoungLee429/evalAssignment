public with sharing class OpportunityLineItem_tr {
    List<OpportunityLineItem> listNew = Trigger.new;
	List<OpportunityLineItem> listOld = Trigger.old;
	Map<Id, OpportunityLineItem> mapNew = (Map<Id, OpportunityLineItem>)Trigger.newMap;
	Map<Id, OpportunityLineItem> mapOld = (Map<Id, OpportunityLineItem>)Trigger.oldMap;
	
	public void run() {
		if(Trigger.isBefore && Trigger.isInsert) beforeInsert();
		else if(Trigger.isBefore && Trigger.isUpdate) beforeUpdate();
		else if(Trigger.isBefore && Trigger.isDelete) beforeDelete();
		else if(Trigger.isAfter && Trigger.isInsert) afterInsert();
		else if(Trigger.isAfter && Trigger.isUpdate) afterUpdate();
		else if(Trigger.isAfter && Trigger.isDelete) afterDelete();
		else if(Trigger.isAfter && Trigger.isUndelete) afterUndelete();
	}
	
	private void beforeInsert() {
        for(OpportunityLineItem a:listNew){       
            if(a.SortOrder == null){
                Integer amt = [select count() from OpportunityLineItem where OpportunityId=:a.OpportunityId];
            	a.SortOrder=amt+1;  
            }                                 
        }     
    }
	private void beforeUpdate() {}
	private void beforeDelete() {}
	private void afterInsert() {}
	private void afterUpdate() {}
	private void afterDelete() {}
	private void afterUndelete() {}
}