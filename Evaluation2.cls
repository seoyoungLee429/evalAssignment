/*
요구사항 - lightning component로 개발
개발된 컴포넌트는 Opportunity Record Page에 노출

화면
┌───────────────┬───────────────┬───────────────┬───────────────┬───────────────┬───────────────┬───────────────┬───────────────┐
│ Seq           │ Product       │ List Price    │ Unit Price    │ Quantity      │ TotalPrice    │ Description   │ Action [+ Button]│
├───────────────┼───────────────┼───────────────┼───────────────┼───────────────┼───────────────┼───────────────┼───────────────┤
│[seq]          │[Search Product│[List Price]   │[Input]        │[Input]        │[Auto]         │[Input]        │[-,▲,▼ Button] │
└───────────────┴───────────────┴───────────────┴───────────────┴───────────────┴───────────────┴───────────────┴───────────────┘

[Cancel] [Save]

로딩시 이미 저장되어 있는 OpportunityLineItem 레코드를 불러 화면에 뿌려줌
필드 : SortOrder, Product2Id, ListPrice, UnitPrice, Quantity, TotalPrice, Description

+ 버튼 클릭시 맨 아래에 빈라인이 생성이 되면서 Seq(SortOrder)는 가장큰 Seq(SortOrder)+1 로 생성이 됨

Product를 검색하여 선택한 경우 Product에 등록되어 있는 ListPrice를 불어와 화면에 노출

UnitPrice와 Quantity 입력 또는 수정시 TotalPrice는 자동 계산

- 버튼 클릭시 해당 라인은 삭제

▲ 버튼은 맨 상단은 노출안함

▲ 버튼 클릭시 해당라인을 위 라인으로 이동하면서 Seq(SortOrder) 조정

▼ 버튼은 맨 하단은 노출안함

▼ 버튼 클릭시 해당라인을 아래 라인으로 이동하면서 Seq(SortOrder) 조정

Cancel 버튼 클릭시 현재까지 수정된 사항은 취소되고 초기화

Save 버튼 클릭시 현재까지 입력된 사항 저장

기타 필요한 사항이 있다고 판단이 되면 추가
*/
/*
Evaluation3 작업 이후 작업
OpportunityLineItem에 아래 필드 추가
Exchange Rate (ExchangeRate__c Number(10,8))
USD TotalPrice (UsdTotalPrice__c Number(16,2))
┌───────────────┬───────────────┬───────────────┬───────────────┬───────────────┬───────────────┬───────────────┬───────────────┬───────────────┬───────────────┐
│ Seq           │ Product       │ List Price    │ Unit Price    │ Quantity      │ TotalPrice    │ Description   │ Exchange Rate │ USD TotalPrice│ Action [+ Button]│
├───────────────┼───────────────┼───────────────┼───────────────┼───────────────┼───────────────┼───────────────┼───────────────┼───────────────┼───────────────┤
│[seq]          │[Search Product│[List Price]   │[Input]        │[Input]        │[Auto]         │[Input]        │[Auto]         │[Auto]         │[-,▲,▼ Button] │
└───────────────┴───────────────┴───────────────┴───────────────┴───────────────┴───────────────┴───────────────┴───────────────┴───────────────┴───────────────┘

[Cancel] [Save] [환율 Reset]

라인이 추가될때 Evaluation3에서 만든 API를 호출하여 (웹서비스로 호출) Exchange Rate 및 USD TotalPrice를 계산하여 넣는다.
USD TotalPrice는 TotalPrice * (1 / Exchange Rate)
이후 TotalPrice가 변경될때마다 USD TotalPrice를 자동으로 계산하여 보여준다.
USD TotalPrice를 소수점3자리에서 반올림 처리하여 2자리까지만 보여준다.

환율 Reset 버튼을 클릭하면 비동기식 방식으로 (Queueable 방식) Evaluation3에서 만든 API를 하나씩 호출하며 한 라인씩 업데이트한다.
화면에서 한 라인씩 호출하여야 하며 화면에서는 완료될때까지 pending 처리를 한다.

저장시 Exchange Rate 및 USD TotalPrice까지 저장한다.

jobID 사용해서 pending 처리하도록 개선

*/
public with sharing class Evaluation2 implements Queueable, Database.AllowsCallouts {

    private OpportunityLineItem oppOne;

    public Evaluation2(OpportunityLineItem oppItemInfo){
        this.oppOne = oppItemInfo;
    }

    public void execute(QueueableContext context) {
        try {
            Integer exchangerate = (Integer)callApi().get('exchangerate');
            this.oppOne.ExchangeRate__c = exchangerate;
            upsert this.oppOne;
        } catch (Exception e) {
            System.debug(' catch 내용 >>'+e.getMessage());
        }        
    }

    @AuraEnabled
    public static List<List<Object>> getInitData(String recordId){
        
        List<List<Object>> objList = new List<List<Object>>();
        List<PricebookEntry> prdList = new List<PricebookEntry>();
        Opportunity opp = [select Id, Pricebook2Id from Opportunity WHERE Id = :recordId ];
        if(opp.Pricebook2Id == null){
            opp.Pricebook2Id = [select Id from Pricebook2 Where IsStandard = true].Id; 
            update opp;
        }     
        prdList = [select Id,Name,UnitPrice,Product2Id from PricebookEntry Where Pricebook2Id = :opp.Pricebook2Id ];
        objList.add(getOppItemListData(recordId));
        objList.add(prdList);
        return objList;

    }

    @AuraEnabled
    public static List<OpportunityLineItem> getOppItemListData(String recordId){
        List<OpportunityLineItem> listOppItem = [
                SELECT Id, SortOrder, Product2.Id, Product2.Name, Name , ListPrice, UnitPrice, Quantity, TotalPrice, ExchangeRate__c, UsdTotalPrice__c, Description
                FROM OpportunityLineItem
                WHERE OpportunityId = :recordId
            	ORDER BY SortOrder
        ];
        return listOppItem;
    }


    
    @AuraEnabled
    public static void saveList(List<OpportunityLineItem> listOppItem, String recordId){
       
        List<OpportunityLineItem> newItemList = new List<OpportunityLineItem>();//insert

        List<OpportunityLineItem> keepList = new List<OpportunityLineItem>(); // update
        Set<Id> Ids = new Set<Id>(); //
        for(OpportunityLineItem each : listOppItem){       
            each.sortOrder = (Integer)each.sortOrder;
            each.UnitPrice = (Integer)each.UnitPrice;
            if(each.id == null){
                each.TotalPrice = null;
                //기존 database에 없는 row 새로 insert
                newItemList.add(each);
                System.debug('newItem ==>'+each);
            }else{
                //기존 database에 있으면서 update 혹은 delete 할 것 분류하기 위한 기준 ID List
                keepList.add(each);
                Ids.add(each.Id);
            }
        }

        List<OpportunityLineItem> deleteList = [SELECT Id,name FROM OpportunityLineItem WHERE OpportunityId = :recordId AND Id NOT IN :Ids];

        delete deleteList;
        insert newItemList;  
        update keepList;        
    }
    @AuraEnabled
    public static ID exchangerateResetAllandSave(OpportunityLineItem oppItem, String recordId){
        ID jobId;
        try {
            oppItem.sortOrder = (Integer)oppItem.sortOrder;
            oppItem.UnitPrice = (Integer)oppItem.UnitPrice;
            jobId = System.enqueueJob(new Evaluation2(oppItem));            
        } catch (Exception e) {
            System.debug('Error executing the job : ' + e.getMessage());
        } finally {
            System.debug('Completed: execution of queueable job: '+jobId); 
        }
        return jobId;
    }

    @AuraEnabled
    public static Boolean checkQueuedState(List<Id> jobListInfo){
        Boolean checkFlag = false;
        List<SObject> asyncData = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob where status in ('Queued') and Id in :jobListInfo];
        if(asyncData.size() == 0){
            checkFlag = true; //끝남
        }
        return checkFlag;
    }
    
    @AuraEnabled
    public static Map<String, Object> callApi(){

        Map<String, String> mapSendData = new Map<String, String>();
        mapSendData.put('currencyisocode', 'usd');
        String sSendDate = JSON.serialize(mapSendData);

        Http http = new Http();
        HttpRequest request = new HttpRequest();        
        String token = getToken();
        request.setEndpoint('https://goodpeoplesoft5-dev-ed.develop.my.salesforce.com/services/apexrest/util/exchangerate');        
        request.setBody(sSendDate);
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setHeader('Content-Type', 'application/json');
        HttpResponse response = http.send(request);
        Map<String, Object> results = new Map<String, Object>();
        if(response.getStatusCode() == 200){
            results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        }else{
            throw new CalloutException('FAILED TO ACCESS');
        }
        return results;
    }
    public static String getToken(){

        String token = '';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String body = 'grant_type=password&client_id='+'3MVG9n_HvETGhr3BDSJeT2Cne_5dRVcY0_4073wcEvrVuhjhG68nsRqdzlSH2mILniwYrLuUwuf4VbLvF9PPc'+'&client_secret='+'191A71F5D9176775B579E7E5DDA67A47BBE652A3764FCC997CFA69A39222F17B'+'&username='+'syleegptest@gpsoft.com'+'&password='+'qweasd!23';
        request.setEndpoint('https://login.salesforce.com/services/oauth2/token');
        request.setMethod('POST');
        request.setBody(body);
        HttpResponse response = http.send(request);
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        if(response.getStatusCode() == 200){
            System.debug('response >> ' + results);
            token = (String)results.get('access_token');
            System.debug('token >> ' + token);      
        }else{            
            throw new CalloutException('FAILED TO GET TOKEN');            
        }
        return token;
    }
}