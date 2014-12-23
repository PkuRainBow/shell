#********************************#
#        PianoCoder              #
#   20141130 @ sohu-inc-bigdata  #
#********************************#
# 以昨天为基准，统计昨天所有用户访问最近一次访问时间距离昨天的天数信息 [1] [2]（2-4]（4-8]（8-16]（16-30]

#!/bin/bash
cd /root/yuanyuhui/wcms_rec_rfm
# 设置开始的日期
let startdate=1
# 提取最近31天的数据
for((i=1;i<=31;i++)) 
do
	let j=${i}+${startdate}-1
	inputpath=`date -d "${j} days ago" +%Y%m%d`
	cat $inputpath/* > temp
  	cat temp | grep TuiJian | cut -d ' ' -f 1 > logfile_${i}
done

# idR_1 ... idR_6 分别统计对应的出现在6个区间段同时也出现在昨天的用户的ID信息
cat logfile_1 logfile_2 > logfilelist_1
sort logfilelist_1 -t ' ' -k 2 | uniq -d > idR_1

cat logfile_1 logfile_3 > logfilelist_2
sort logfilelist_2 -t ' ' -k 2 | uniq -d > idR_2

cat logfile_4 logfile_5 | sort -t ' ' -k 2 | uniq > temp
cat temp logfile_1 > logfilelist_3
sort logfilelist_3 -t ' ' -k 2 | uniq -d > idR_3

cat logfile_6 logfile_7 logfile_8 logfile_9 | sort -t ' ' -k 2 | uniq  > temp
cat temp logfile_1 > logfilelist_4
sort logfilelist_4 -t ' ' -k 2 | uniq -d > idR_4

cat logfile_10 > temp
for((i=11; i<=17;i++))
do
	cat logfile_${i} >> temp 
done
cat temp | sort -t ' ' -k 2 | uniq  > ttemp
cat ttemp logfile_1 > logfilelist_5
sort logfilelist_5 -t ' ' -k 2 | uniq -d > idR_5

cat logfile_18 > temp
for((i=19; i<=31;i++))
do
	cat logfile_${i} >> temp
done
cat temp | sort -t ' ' -k 2 | uniq  > ttemp
cat ttemp logfile_1 > logfilelist_6
sort logfilelist_6 -t ' ' -k 2 | uniq -d > idR_6

# 依次过滤统计用户最近一次访问的时间所属不同区间的用户数
# 1
cat idR_1 | wc -l > recentlist
# 2
cat idR_2 idR_1 | sort -t ' ' -k 2 | uniq -d > temp
cat idR_2 temp | sort | uniq -u | wc -l >> recentlist
# 3,4
cat idR_2 idR_1 | sort -t ' ' -k 2 | uniq > temp
cat idR_3 temp | sort | uniq -d > ttemp
cat idR_3 ttemp | sort | uniq -u | wc -l >> recentlist
# 5-8
cat idR_3 idR_2 idR_1 | sort -t ' ' -k 2 | uniq > temp
cat idR_4 temp | sort | uniq -d > ttemp
cat idR_4 ttemp | sort | uniq -u | wc -l >> recentlist
# 9-16
cat idR_4 idR_3 idR_2 idR_1 | sort -t ' ' -k 2 | uniq > temp
cat idR_5 temp | sort | uniq -d > ttemp
cat idR_5 ttemp | sort | uniq -u | wc -l >> recentlist
# 17- 30
cat idR_5 idR_4 idR_3 idR_2 idR_1 | sort -t ' ' -k 2 | uniq > temp
cat idR_6 temp | sort | uniq -d > ttemp
cat idR_6 ttemp | sort | uniq -u | wc -l >> recentlist
# 统计昨天出现但是之前30天都没有出现的用户ID 即 （30-）
cat logfile_1 > temp
for((i=1;i<=6;i++))
do
	cat idR_${i} >> temp
done
cat temp | sort | uniq -u | wc -l >> recentlist
# 昨天访问的用户ID总数
cat logfile_1 | sort | uniq | wc -l >> recentlist

# 保存所有要统计的信息到数组中
array=(0 0 0 0 0 0 0 0)
array[0]=`sed -n '1p' recentlist` 
array[1]=`sed -n '2p' recentlist`
array[2]=`sed -n '3p' recentlist`
array[3]=`sed -n '4p' recentlist`
array[4]=`sed -n '5p' recentlist`
array[5]=`sed -n '6p' recentlist`
array[6]=`sed -n '7p' recentlist`
array[7]=`sed -n '8p' recentlist`

date=`date -d "${startdate} days ago" +%Y-%m-%d`
# 写入数据库
mysql -h10.16.10.215 -ucms -pcms@dp99 -N -e "insert into rec_wcms_rfm(date, type, channel, region1, region2, region3, region4, region5, region6, region7, uidnum) values(\"$date\",\"R\",\"TuiJian\",\"${array[0]}\",\"${array[1]}\",\"${array[2]}\",\"${array[3]}\",\"${array[4]}\",\"${array[5]}\",\"${array[6]}\",\"${array[7]}\")" cms;

# 清空中间文件
for((i=1;i<=30;i++))
do
        rm -f logfile_${i}
done

for((i=1;i<=6;i++))
do
    rm -f logfilelist_${i}
	rm -f idR_${i}
done

rm -f temp
rm -f ttemp
rm -f recentlist
