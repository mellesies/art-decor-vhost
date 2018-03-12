xquery version "3.0";
import module namespace repo="http://exist-db.org/xquery/repo";

(:  install xars from database :)
repo:install-and-deploy-from-db(concat("/db/system/repo/", request:get-parameter("pkg", "")))
 

 
