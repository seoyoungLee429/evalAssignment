/*
사전 준비
1. Account에 LeadSource__c MultiPicklist 필드를 생성하고 Opportunity의 LeadSource Picklist 값을 모두 추가
2. Account에 Grade__c Picklist 필드를 추가, 값은 A,B,C,D,E
3. Account에 GradeLastYear__c Picklist 필드를 추가, 값은 A,B,C,D,E


LeadSource는 'Other' 로 생성할 수 없음
LeadSource는 변경할 수 없음
단, 다른 클래스내에서 'Other' 로 생성할 수 있도록 처리가 되어야 함 (예외 처리를 할 수 있도록)


Opportunity가 IsWon 이고, ClosedDate가 올해인 Account 별 Amount 총액에 따라 Account의 GradeThisYear__c값에 Amount 총액별로 등급 업데이트
500만원미만 E, 500만원이상 D, 1000만원이상 C, 5000만원이상 B, 1억이상 A
단 작년등급 (GradeLastYear__c)가 높은 경우 작년등급으로 그대로 둠
예) Account "sample1" GradeLastYear__c 가 값이 없는 경우
Account "sample1" 에 IsWon된 Opportunity Amount 300만원 발생 -> Grade__c E
Account "sample1" 에 IsWon된 Opportunity Amount 300만원 추가발생 -> Grade__c D
Account "sample1" 에 IsWon된 Opportunity Amount 300만원 추가발생 -> Grade__c D 유지
Account "sample1" 에 IsWon된 Opportunity Amount 300만원 추가발생 -> Grade__c C
예) Account "sample1" GradeLastYear__c 가 D이고 Grade__c 가 D인 경우
Account "sample1" 에 IsWon된 Opportunity Amount 300만원 발생 -> Grade__c D 유지
Account "sample1" 에 IsWon된 Opportunity Amount 300만원 추가발생 -> Grade__c D 유지
Account "sample1" 에 IsWon된 Opportunity Amount 300만원 추가발생 -> Grade__c D 유지
Account "sample1" 에 IsWon된 Opportunity Amount 300만원 추가발생 -> Grade__c C


Opportunity가 등록될때마다 Opportunity의 LeadSource가 Account의 LeadSource__c에 포함되어 있지 않으면 Account의 LeadSource__c에 추가 선택된 걸로 업데이트

*/

// 개선사항: for 문안에 dml 있는 것 빼기, test class 만들기 쉽게 메서드화, update는 두번 하지 않도록 한번만 하도록 변경==>afterUpdate

public with sharing class Opportunity_tr {
	List<Opportunity> listNew = Trigger.new;
	List<Opportunity> listOld = Trigger.old;
	Map<Id, Opportunity> mapNew = (Map<Id, Opportunity>)Trigger.newMap;
	Map<Id, Opportunity> mapOld = (Map<Id, Opportunity>)Trigger.oldMap;
	
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

		for(Opportunity opp : listNew){
			if(opp.LeadSource != null){
				if(opp.LeadSource.equals('Other')){
					opp.LeadSource.addError('Other 입력 불가');
				}
			}			
		}
	}
	private void beforeUpdate() {		
		for(Opportunity newOpp : listNew){
			if(newOpp.LeadSource != null && newOpp.LeadSource.equals('Other')){
				newOpp.LeadSource.addError('Other 입력 불가');
			}
			for(Opportunity oldOpp : listOld){
				if(oldOpp.LeadSource != null && oldOpp.Id.equals(newOpp.Id) && !oldOpp.LeadSource.equals('') && !oldOpp.LeadSource.equals(newOpp.LeadSource)){
					newOpp.LeadSource.addError('lead source 변경 불가');

				}		
			}
		}
	}
	private void beforeDelete() {}
	private void afterInsert() {
		List<Account> updateAcctInfo = settingGradeInfo(listNew);	
		update updateAcctInfo;
	}
	private void afterUpdate() {
		List<Account> updateAcctInfo1 = settingGradeInfo(listOld);			
		List<Account> updateAcctInfo2 = settingGradeInfo(listNew);	
		Set<Account> targetAcctSet = new Set<Account>(updateAcctInfo1);
		List<Account> targeAccttList;

		if( updateAcctInfo1 == updateAcctInfo2){
			targeAccttList = updateAcctInfo1;
					
		}else{
			for(Account acct: updateAcctInfo2){
				targetAcctSet.add(acct);
			}
			targeAccttList = new List<Account>(targetAcctSet);	
		}
		//System.debug('targeAccttList ==>'+targeAccttList);
		update targeAccttList;
	}
	private void afterDelete() {
		List<Account> updateAcctInfo = settingGradeInfo(listOld);	
		//System.debug('afterDelete updateAcctInfo ==>'+updateAcctInfo);
		update updateAcctInfo;
	}
	private void afterUndelete() {
		List<Account> updateAcctInfo = settingGradeInfo(listNew);	
		//System.debug('afterUndelete updateAcctInfo ==>'+updateAcctInfo);
		update updateAcctInfo;
	}

	//금액에 따른 등급 반환
	private String getGradeInfo(Decimal amt){
		String gradeInfo = 'E';
		if(amt < 5000000){
			gradeInfo = 'E';
		}else if(5000000 <=  amt &&  amt < 10000000){
			gradeInfo = 'D';

		}else if(10000000 <=  amt &&  amt < 50000000){
			gradeInfo = 'C';
			
		}else if(50000000 <=  amt &&  amt < 100000000){
			gradeInfo = 'B';
			
		}else if(100000000 <=  amt){
			gradeInfo = 'A';
			
		}
		return gradeInfo;
	}

	//sum 리스트에서 해당 account의 sum 반환
	private Decimal getYearAmt(List<AggregateResult> aggResult,Id acctIdInfo){

		Decimal returnVal = 0;
		for(AggregateResult each :aggResult){
			if(each.get('AccountId').equals(acctIdInfo)){
				returnVal = (Decimal)each.get('amt');
			}
		}
		return returnVal;
	}

	//Account ID와 그에 속한 opportunity List를 받아 Account에 넣을 leadSource 반환
	private String getLeadInfoList(List<Opportunity> oppList,Id acctIdInfo){
		set<String> leadInfoSet = new set<String>();    
		for(Opportunity opp: oppList){	
			if(opp.AccountId.equals(acctIdInfo)){
				if(opp.LeadSource != null){
					leadInfoSet.add(opp.LeadSource);
				}		
			}
		}
		String acctLeadSource='';    
		for(String st : leadInfoSet){
			acctLeadSource+=st+';';
		}
		if(leadInfoSet.size() != 0){
			acctLeadSource=acctLeadSource.substring(0,acctLeadSource.length()-1);
		}
		return acctLeadSource;
	}

	private List<Account> settingGradeInfo(List<Opportunity> forOppList){

		//1. 매건 opp에 해당 하는 account에 속한 (작년/올해) opp amt 계산 후 등급 산정
		//2. 만약 올해 등급이 더 높으면 올해 등급 setting, 아니면 작년 등급 setting
		Integer thisYear = Date.today().year();
		Integer lastYear = Date.today().year()-1;

		//최종 반환할 Account List
		List<Account> acctList = new List<Account>();

		//trigger된 opportunity에 관련된 Account Id List
		Set<Id> acctIdList = new Set<Id>();
		for(Opportunity eachOpp : forOppList){
            if(eachOpp.AccountId != null){
                acctIdList.add(eachOpp.AccountId);
            }			
		}		
		//trigger된 opportunity와 관련된 Account 있는지 체크해서 있으면 실행
		if(acctIdList.size() != 0){
			//accountId별 올해 sum(amount)
			List<AggregateResult> thisAmtSumInfoPerAcct = 
				[select AccountId, sum(Amount) amt 
				from Opportunity 
				where IsWon = true and CALENDAR_YEAR(CloseDate)=:thisYear and AccountId in :acctIdList 
				group by AccountId];
			//accountId별 작년 sum(amount)
			List<AggregateResult> lastAmtSumInfoPerAcct = 
				[select AccountId, sum(Amount) amt 
				from Opportunity 
				where IsWon = true and CALENDAR_YEAR(CloseDate)=:lastYear and AccountId in :acctIdList 
				group by AccountId];
            List<Opportunity> allOpp = [select AccountId, LeadSource from Opportunity where AccountId in :acctIdList];
			for(Id acctId : acctIdList){

				Decimal thisAmt = getYearAmt(thisAmtSumInfoPerAcct,acctId);
                Decimal lastAmt = getYearAmt(lastAmtSumInfoPerAcct,acctId);

				String thisYearGradeInfo= getGradeInfo(thisAmt);
                String lastYearGradeInfo= getGradeInfo(lastAmt);
    
                Account acct = new Account();
                acct.Id = acctId;		
    
                //작년 등급이 더 좋으면 올해 등급도 작년 등급으로 셋팅
                if(thisYearGradeInfo > lastYearGradeInfo){
                    thisYearGradeInfo = lastYearGradeInfo;
                }
    
                acct.Grade__c = thisYearGradeInfo;
                acct.GradeLastYear__c = lastYearGradeInfo;

                acct.LeadSource__c = getLeadInfoList(allOpp,acctId);
    
                acctList.add(acct);
            }
        }
		return acctList;
	}
}