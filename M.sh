#********************************#
#        PianoCoder              #
#   20141130 @ sohu-inc-bigdata  #
#********************************#
# 以昨天为基准，统计昨天所有用户在最近30天访问的新闻条数信息 [0] [1]（1-2]（2-4]（4-8]（8-16]（16-30] （31-) 


#!/bin/bash
cd /root/yuanyuhui/wcms_rec_rfm 
cat /dev/null > id_list
cat /dev/null > count_list

# 设置开始的日期
let startdate=1
# 提取昨天的数据
yesterday=`date -d "${startdate} days ago" +%Y%m%d`
cat ${yesterday}/* | grep TuiJian | awk '{print $2}' > list
# 提取最近30天的数据
for((i=2; i<=31; i++)) 
do
	let j=${i}+${startdate}-1
    day=`date -d "${i} days ago" +%Y%m%d`
    # 提取每条统计的新闻条数，有N条新闻就打印N次用户ID信息
    # 信息的统计格式:  TuiJian  07rNsU210hznbKWnNBat3T 2 7 556331724#406782486#556331757#406929184#406788596#406889527#406932675
	cat $day/* | grep TuiJian | awk '{i=1} {while(i<=$4) {print $2;i++;}}' >> count_list
done
# 统计31天所有不同ID用户查看新闻的条数
cat count_list list | sort | uniq -c > temp1
# 统计30天所有不同ID用户查看新闻的条数 uniq -c 会在每一行前面加上此行重复出现的次数
cat count_list | sort | uniq -c > temp2
# 统计在昨天没有出现,在昨天之前前30天出现过的用户ID
cat temp1 temp2 | sort | uniq -d  > temp3
# 过滤掉31天中昨天没有出现的用户ID,剩下的就是昨天的用户在31天内的信息
cat temp3 temp1 | sort | uniq -u > news_list

rm -f temp1
rm -f temp2
rm -f temp3
# news_list 保存最终的统计信息
cat /dev/null > newslist

# 分别统计在过去31天的M（新闻阅读）信息
cat news_list | awk 'BEGIN {F_0=0;F_1=0;F_2=0;F_3=0;F_4=0;F_5=0;F_6=0;F_7=0}
				{if($1 <= 1) F_0=F_0+1; else if($1 <= 2) F_1=F_1+1; else if($1 <= 3) F_2=F_2+1; 
				else if($1 <= 5) F_3=F_3+1; else if($1 <= 9) F_4=F_4+1;
				else if($1 <= 17) F_5=F_5+1; else if($1 <= 31) F_6=F_6+1;
				else F_7=F_7+1} 
				END{print F_0; print F_1; print F_2; print F_3; print F_4; print F_5;
					print F_6; print F_7}' >> newslist
rm -f news_list

# 昨天访问的用户总数
cat list | wc -l >> newslist

# 提取所有的统计信息保存到数组中
array=(0 0 0 0 0 0 0 0 0)
array[0]=`sed -n '1p' newslist` 
array[1]=`sed -n '2p' newslist`
array[2]=`sed -n '3p' newslist`
array[3]=`sed -n '4p' newslist`
array[4]=`sed -n '5p' newslist`
array[5]=`sed -n '6p' newslist`
array[6]=`sed -n '7p' newslist`
array[7]=`sed -n '8p' newslist`
array[8]=`sed -n '9p' newslist`
uid=1
date=`date -d "${startdate} days ago" +%Y-%m-%d`

rm -f newslist

# 将统计的新闻信息写入数据库
mysql -h10.16.10.215 -ucms -pcms@dp99 -N -e "insert into rec_wcms_rfm(date, type, channel, region0, region1, region2, region3, region4, region5, region6, region7, uidnum) values(\"$date\",\"M\",\"TuiJian\",\"${array[0]}\",\"${array[1]}\",\"${array[2]}\",\"${array[3]}\",\"${array[4]}\",\"${array[5]}\",\"${array[6]}\",\"${array[7]}\", \"${array[8]}\")" cms;
