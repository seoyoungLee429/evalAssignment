@isTest(SeeAllData=true)
private class Evaluation2_test {
	private class RestMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = '{ "exchangerate": "1256"}';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
	static testMethod void doTest() {
		
		Test.setMock(HttpCalloutMock.class, new RestMock());

		test.startTest();		
		Evaluation2.getInitData('0062w00000H4EYuAAN');
		List<OpportunityLineItem> tt = Evaluation2.getOppItemListData('0062w00000H4EYuAAN');
		Evaluation2.saveList(tt,'0062w00000H4EYuAAN');

		List<Id> idList = new List<Id>();
		for(OpportunityLineItem a : tt){
			Id b = Evaluation2.exchangerateResetAllandSave(a,'0062w00000H4EYuAAN');
			idList.add(b);
		}		
		Evaluation2.checkQueuedState(idList);
		
		test.stopTest();
	}
}