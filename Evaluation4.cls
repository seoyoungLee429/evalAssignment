/*
OpportunityLineItem 전체를 검색하여
Evaluation3에서 만든 API를 호출하여 (웹서비스로 호출) Exchange Rate 및 USD TotalPrice를 계산하여 전체를 업데이트 한다.
*/
public with sharing class Evaluation4 {
    public static void updateOppItemAll(){
        List<OpportunityLineItem> listOppItem = [
        SELECT Id, SortOrder, Product2.Id, Product2.Name, Name , ListPrice, UnitPrice, Quantity, TotalPrice, ExchangeRate__c, UsdTotalPrice__c, Description
        FROM OpportunityLineItem
        ];
        for(OpportunityLineItem each : listOppItem){
            each.ExchangeRate__c = (Decimal)Evaluation2.callApi().get('exchangerate');
            each.UsdTotalPrice__c = (each.TotalPrice * (1/each.ExchangeRate__c)).setScale(2);
        }
        update listOppItem;
    }
    

}