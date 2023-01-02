@IsTest
private class Opportunity_tr_test {
	static testMethod void doTest() {
		Account objAccount = new Account();
		objAccount.Name = '테스트Account';
		insert objAccount;

		Account objAccount2 = new Account();
		objAccount2.Name = '테스트Account2';
		insert objAccount2;
		
		Opportunity obj = new Opportunity();
		obj.Name = '테스트Opportunity';
		obj.AccountId = objAccount.Id;
		obj.StageName = 'Closed Won';
		obj.CloseDate = System.today();

		Opportunity obj2 = new Opportunity();
		obj2.Name = '테스트Opportunity2';
		obj2.AccountId = objAccount2.Id;
		obj2.StageName = 'Closed Won';
		obj2.LeadSource ='Web';
		obj2.CloseDate = System.today();
		
		test.startTest();
		
		insert obj;		
		delete obj;
		undelete obj;
		update obj;

		insert obj2;
		obj2.AccountId = objAccount.Id;
		update obj2;
		
		test.stopTest();
	}
}