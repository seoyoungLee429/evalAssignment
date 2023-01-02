/*
UrlMapping='/util/exchangerate' 로 하여 환율정보를 제공하는 인터페이스 개발
실제환율이 아닌 테스트를 위한 random 환율 생성함

{"currencyisocode":"usd"}

로 호출하면

{"exchangerate":random 생성된 숫자}

1200~1300까지 random으로 소수점 이하 없이 생성하여 return

*/
@RestResource(UrlMapping='/util/exchangerate')
global with sharing class Evaluation3{

    global class Input {
        public String currencyisocode;
    }

    global class Output {
        public Integer exchangerate;
    }

    @HttpPost
    global static Output getExchangerate() {
        System.debug('in Evaluation3!!!');
        Output objOutput = new Output();
        try {
            System.debug('getExchangerate START');
            RestRequest request = RestContext.request;
            String requestBody = request.requestBody.toString();
            if (requestBody != null && requestBody != '') {
                Input objInput = (Input)JSON.deserializeStrict(requestBody, Input.class);
                if(objInput.currencyisocode.equals('usd')){
                    objOutput.exchangerate = (Integer)(math.random()*100+1200);
                }else{
                    objOutput.exchangerate = 1;
                }               

            }		
            
        } catch (Exception e) {
            System.debug('Exception >> '+ e.getMessage());
        }
        System.debug('objOutput >> '+ objOutput);

        return objOutput;

    }


}