#!/bin/bash

#If received logout parameter, send a logout request to eportal server
if [ "${1}" = "logout" ]; then
  userIndex=`curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.3296.62 Safari/537.36" -I http://10.30.252.71/eportal/redirectortosuccess.jsp | grep -o 'userIndex=.*'` #Fetch user index for logout request
  logoutResult=`curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.3296.62 Safari/537.36" -d "${userIndex}" http://10.30.252.71/eportal/InterFace.do?method=logout`
  echo $logoutResult
  exit 0
fi

#If received parameters is less than 3, print usage
if [ "${#}" -lt "3" ]; then
  echo "Usage: ./ruijie_gdpst.sh service username password"
  echo "Service parameter can be \"teacher\", \"teaching\", \"intranet\" and \"chinanet\". If service parameter do not set as these value, it will use chinaunicom as default internet service provider."
  echo "Example: ./ruijie_gdpst.sh chinanet 0120240001 123456"
  echo "if you want to logout, use: ./ruijie_gdpst.sh logout"
  exit 1
fi

#Exit the script when is already online, use www.google.cn/generate_204 to check the online status
captiveReturnCode=`curl -s -I -m 10 -o /dev/null -s -w %{http_code} http://www.google.cn/generate_204`
if [ "${captiveReturnCode}" = "204" ]; then
  echo "You are already online!"
  exit 0
fi

#If not online, begin Ruijie Auth

#Get Ruijie login page URL
loginPageURL=`curl -s "http://www.google.cn/generate_204" | awk -F \' '{print $2}'`

teacher="default"
teaching="JiaoXue"
intranet="NeiBu"
chinanet="DianXin"
chinaunicom="LianTong"

service=""


if [ "${1}" = "teacher" ]; then
  echo "Use Teacher Network internet service provider."
  service="${teacher}"
fi

if [ "${1}" = "teaching" ]; then
  echo "Use Teaching Area Network internet service provider."
  service="${teaching}"
fi

if [ "${1}" = "intranet" ]; then
  echo "Use Intranet Network internet service provider."
  service="${intranet}"
fi

if [ "${1}" = "chinanet" ]; then
  echo "Use ChinaNet as internet service provider."
  service="${chinanet}"
fi

if [ -z "${service}" ]; then
  echo "Use ChinaUnicom as internet service provider."
  service="${chinaunicom}"
fi

#Structure loginURL
loginURL=`echo ${loginPageURL} | awk -F \? '{print $1}'`
loginURL="${loginURL/index.jsp/InterFace.do?method=login}"

#Structure quertString
queryString=`echo ${loginPageURL} | awk -F \? '{print $2}'`
queryString="${queryString//&/%2526}"
queryString="${queryString//=/%253D}"

#Send Ruijie eportal auth request and output result
if [ -n "${loginURL}" ]; then
  authResult=`curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.3296.62 Safari/537.36" -e "${loginPageURL}" -b "EPORTAL_COOKIE_USERNAME=; EPORTAL_COOKIE_PASSWORD=; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_SERVER_NAME=; EPORTAL_AUTO_LAND=; EPORTAL_USER_GROUP=; EPORTAL_COOKIE_OPERATORPWD=;" -d "userId=${2}&password=${3}&service=${service}&queryString=${queryString}&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=false" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" "${loginURL}"`
  echo $authResult
fi