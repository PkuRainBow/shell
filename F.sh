#********************************#
#        PianoCoder              #
#   20141130 @ sohu-inc-bigdata  #
#********************************#
#以昨天为基准，统计昨天所有用户在最近30天访问的频率信息 [0] [1]（1-2]（2-4]（4-8]（8-16]（16-30]

#!/bin/bash

cd /root/yuanyuhui/wcms_rec_rfm
# 设置开始的日期
let startdate=1
# 提取昨天的数据
yesterday=`date -d "${startdate} days ago" +%Y%m%d`
cat $yesterday/* > temp
cat temp | grep TuiJian | cut -d ' ' -f 1 > idlist

cat /dev/null > sumlist
# 依次统计昨天出现的用户在最近30天的访问信息 
for((i=2;i<=31;i++)) 
do
	let j=${i}+${startdate}-1
	inputpath=`date -d "${j} days ago" +%Y%m%d`
	cat $inputpath/* > temp
  	cat temp | grep TuiJian | cut -d ' ' -f 1 > curlist	
	cat curlist idlist | sort | uniq -d >> sumlist
done
cat idlist >> sumlist

#uniq -c 会在每一行前面加上此行重复出现的次数
cat sumlist | sort | uniq -c  > freqlist

# 统计不同区间段的访问的用户数量信息
cat freqlist | awk 'BEGIN {F_0=0;F_1=0;F_2=0;F_3=0;F_4=0;F_5=0;F_6=0;F_7=0}
				{if($1 <= 1) F_0=F_0+1; else if($1 <= 2) F_1=F_1+1; else if($1 <= 3) F_2=F_2+1; 
				else if($1 <= 5) F_3=F_3+1; else if($1 <= 9) F_4=F_4+1;
				else if($1 <= 17) F_5=F_5+1; else if($1 <= 31) F_6=F_6+1;
				else F_7=F_7+1} 
				END{print F_0; print F_1; print F_2; print F_3; print F_4; print F_5;
					print F_6; print F_7}' > frequencylist

cat idlist | wc -l >> frequencylist

# 提取到数组中
array=(0 0 0 0 0 0 0 0 0 0)
array[0]=`sed -n '1p' frequencylist` 
array[1]=`sed -n '2p' frequencylist`
array[2]=`sed -n '3p' frequencylist`
array[3]=`sed -n '4p' frequencylist`
array[4]=`sed -n '5p' frequencylist`
array[5]=`sed -n '6p' frequencylist`
array[6]=`sed -n '7p' frequencylist`
array[7]=`sed -n '8p' frequencylist`
array[8]=`sed -n '9p' frequencylist`

date=`date -d "${startdate} days ago" +%Y-%m-%d`

# 写入数据库
mysql -h10.16.10.215 -ucms -pcms@dp99 -N -e "insert into rec_wcms_rfm(date, type, channel, region0, region1, region2, region3, region4, region5, region6, region7, uidnum) values(\"$date\",\"F\",\"TuiJian\",\"${array[0]}\",\"${array[1]}\",\"${array[2]}\",\"${array[3]}\",\"${array[4]}\",\"${array[5]}\",\"${array[6]}\",\"${array[7]}\",\"${array[8]}\")" cms;

# 清空中间文件
rm -f frequencylist
rm -f temp
rm -f curlist
rm -f sumlist
rm -f freqlist
rm -f idlist
