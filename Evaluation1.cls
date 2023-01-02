public with sharing class Evaluation1 {
	/**
	 * @param intValue 입력값
	 * @return 결과값
	 * @description 1부터 입력값까지의 3의배수, 5의배수 값의 합
	 * 예) 입력값 10이면 3,5,6,9,10를 더한 33, 입력값이 20이면 3,5,6,9,10,12,15,18,20를 더한 98
	 */
	public Integer getResult3And5(Integer intValue) {
		Integer intResult=0;
        
        for(integer i=1; i<= intValue ; i++){
            if(Math.MOD(i,3) == 0){
                intResult+=i;
            }
            if(Math.MOD(i,5) == 0){
                intResult+=i;
            }
            if(Math.MOD(i,3) == 0 && Math.MOD(i,5) == 0){
                intResult-=i;
            }                          
        }
        System.debug('3and5 result :: '+intResult);
		
		return intResult;
	}
	
	/**
	 * @param intValue 입력숫자
	 * @param intDigit 자리수
	 * @return 결과값
	 * @description 입력숫자에 자리수 만큼 0를 붙여 Return, 자리수가 입력숫자보다 적을 경우는 그냥 입력숫자 return
	 * 예) 입력값이 123, 5 이면 00123, 입력값이 123, 2 이면 123, 입력값이 1234, 8 이면 00001234
	 */
	public String getStrPatternIntegerToString(Integer intValue, Integer intDigit) {
		String strReturn;
        strReturn = intValue+'';
        String strIntValue = intValue+'';
        
        if(strIntValue.length() < intDigit){
            for(Integer i=0;i<(intDigit-strIntValue.length());i++){
                strReturn = '0'+strReturn;
            }            
        }
        
        System.debug('result :: '+strReturn);        
		
		return strReturn;
	}
	
	/**
	 * @param dtValue 입력날짜
	 * @return 결과값
	 * @description 입력날짜를 yyyymmdd 형식의 String으로 Return
	 * 예) 2022-12-01 이면 '20221201' 로 return
	 */
	public String getStrFormatYyyyMmDd(Date dtValue) {
		String strReturn;
        String strDtValue = dtValue+'';
        
        strReturn=strDtValue.substring(0, 4)+strDtValue.substring(5, 7)+strDtValue.substring(8, 10);
        System.debug('result :: '+strReturn);  
		return strReturn;
	}
}