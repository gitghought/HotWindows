<?php
header("Content-type:text/html;charset=utf-8");	//意思是申明请求的数据为UTF-8
$con = mysql_connect("localhost","hotwindows","hotwindows081006@)!%"); //链接数据库
if (!$con)
{
 echo 链接失败;
}
mysql_select_db("hotwindows",$con); //需要操作的数据库名
mysql_query('SET NAMES UTF8'); //设置数据库编码
$result = mysql_query("SELECT * FROM Edition ORDER BY time DESC",$con); //执行数据库查询命令
$results = array(); //将查询结果转换为数组
while ($row = mysql_fetch_assoc($result))
 $results[] = $row;
echo urldecode(json_encode($results,JSON_UNESCAPED_UNICODE)); //输出JSON字符串
mysql_query("INSERT INTO Edition VALUES ('" date_add() "','中文测试','http://www.baidu.com')"); //设置数据库编码
mysql_close($con); //关闭数据库连接
?>
