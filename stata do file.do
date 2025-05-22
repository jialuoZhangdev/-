clear all
set more off
foreach pkg in reghdfe esttab ivreg2 {        // 自动安装缺包
    capture which `pkg'
    if _rc ssc install `pkg', replace
}

* 读取Excel文件
import excel "最终版.xlsx", sheet("Sheet1") firstrow clear

* 将变量重命名为英文
rename 省份 province
rename 年份 year
rename 数字经济指数 digit
rename 政府透明度指数 ft
rename 协同效应 fde
rename 飞轮效应 govc
rename 财政分权 fisd
rename 城镇化率 urban
rename 二产值占比 es
rename 市场化指数 market
rename GDP增速 gdpgrowth
rename 财政支出效率 efficiency

* 查看数据结构
describe
summarize


* 转换province为类别变量，year已经是数值型变量
encode province, gen(province_id)
* 对于年份，因为已经是数值，直接创建一个分组变量
egen year_id = group(year)

* 查看缺失值
misstable summarize
di "原始数据行数: " _N

* 去除含缺失值的行
egen missing_count = rmiss(*)
drop if missing_count > 0
di "清洗后数据行数: " _N
di "移除了 " missing_count " 行含缺失值的数据"
drop missing_count


* 创建交互项（注意移除了注释中的/ 符号）
gen digit_ft = digit * ft      /* 数字经济 × 政府透明度交互项 */
gen digit_fde = digit * fde    /* 数字经济 × 协同效应交互项 */
gen digit_govc = digit * govc  /* 数字经济 × 飞轮效应交互项 */


* 声明面板数据
xtset province_id year_id

* 设置固定效应回归选项
global fe_options fe vce(robust)
global controls fisd urban es market gdpgrowth


* (M1) 基准模型
reghdfe efficiency digit $controls, absorb(province_id year_id) vce(robust)
estimates store m1

* (M2) 透明度交互效应模型
reghdfe efficiency digit ft digit_ft $controls, absorb(province_id year_id) vce(robust)
estimates store m2

* (M3) 协同效应交互模型
reghdfe efficiency digit fde digit_fde $controls, absorb(province_id year_id) vce(robust)
estimates store m3

* (M4) 飞轮效应交互模型
reghdfe efficiency digit govc digit_govc $controls, absorb(province_id year_id) vce(robust)
estimates store m4


* 使用estimates table输出结果（替代esttab）
estimates table m1 m2 m3 m4, b(%9.4f) se(%9.4f) stats(N r2_w)



* 创建一个关系数据集
preserve

* 创建临时数据集记录相邻省份关系
clear
set obs 1000
gen province = ""
gen neighbor = ""
gen id = _n



* 手动定义相邻省份关系（与R代码中的neighbor_map对应）
local i = 1

* 北京市的邻居
foreach n in "天津市" "河北省" {
    replace province = "北京市" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 天津市的邻居
foreach n in "北京市" "河北省" {
    replace province = "天津市" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 河北省的邻居
foreach n in "北京市" "天津市" "山西省" "内蒙古自治区" "辽宁省" "山东省" "河南省" {
    replace province = "河北省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 山西省的邻居
foreach n in "河北省" "内蒙古自治区" "陕西省" "河南省" {
    replace province = "山西省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 内蒙古自治区的邻居
foreach n in "黑龙江省" "吉林省" "辽宁省" "河北省" "山西省" "陕西省" "宁夏回族自治区" "甘肃省" {
    replace province = "内蒙古自治区" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 辽宁省的邻居
foreach n in "内蒙古自治区" "吉林省" "河北省" {
    replace province = "辽宁省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 吉林省的邻居
foreach n in "黑龙江省" "辽宁省" "内蒙古自治区" {
    replace province = "吉林省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 黑龙江省的邻居
foreach n in "内蒙古自治区" "吉林省" {
    replace province = "黑龙江省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 上海市的邻居
foreach n in "江苏省" "浙江省" {
    replace province = "上海市" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 江苏省的邻居
foreach n in "上海市" "浙江省" "安徽省" "山东省" {
    replace province = "江苏省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 浙江省的邻居
foreach n in "上海市" "江苏省" "安徽省" "江西省" "福建省" {
    replace province = "浙江省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 安徽省的邻居
foreach n in "江苏省" "浙江省" "江西省" "河南省" "湖北省" "山东省" {
    replace province = "安徽省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 福建省的邻居
foreach n in "浙江省" "江西省" "广东省" {
    replace province = "福建省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 江西省的邻居
foreach n in "浙江省" "安徽省" "湖北省" "湖南省" "广东省" "福建省" {
    replace province = "江西省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 山东省的邻居
foreach n in "河北省" "河南省" "安徽省" "江苏省" {
    replace province = "山东省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 河南省的邻居
foreach n in "河北省" "山西省" "安徽省" "湖北省" "陕西省" "山东省" {
    replace province = "河南省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 湖北省的邻居
foreach n in "河南省" "安徽省" "江西省" "湖南省" "重庆市" "陕西省" {
    replace province = "湖北省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 湖南省的邻居
foreach n in "江西省" "湖北省" "重庆市" "贵州省" "广西壮族自治区" "广东省" {
    replace province = "湖南省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 广东省的邻居
foreach n in "福建省" "江西省" "湖南省" "广西壮族自治区" "香港特别行政区" "澳门特别行政区" {
    replace province = "广东省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 广西壮族自治区的邻居
foreach n in "广东省" "湖南省" "贵州省" "云南省" {
    replace province = "广西壮族自治区" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 海南省的邻居 (岛屿)
replace province = "海南省" in `i'
replace neighbor = "广东省" in `i'
local i = `i' + 1

* 重庆市的邻居
foreach n in "湖北省" "湖南省" "贵州省" "四川省" "陕西省" {
    replace province = "重庆市" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 四川省的邻居
foreach n in "重庆市" "贵州省" "云南省" "西藏自治区" "青海省" "甘肃省" "陕西省" {
    replace province = "四川省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 贵州省的邻居
foreach n in "湖南省" "重庆市" "四川省" "云南省" "广西壮族自治区" {
    replace province = "贵州省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 云南省的邻居
foreach n in "贵州省" "四川省" "西藏自治区" "广西壮族自治区" {
    replace province = "云南省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 西藏自治区的邻居
foreach n in "新疆维吾尔自治区" "青海省" "四川省" "云南省" {
    replace province = "西藏自治区" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 陕西省的邻居
foreach n in "山西省" "河南省" "湖北省" "重庆市" "四川省" "甘肃省" "宁夏回族自治区" "内蒙古自治区" {
    replace province = "陕西省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 甘肃省的邻居
foreach n in "内蒙古自治区" "宁夏回族自治区" "陕西省" "四川省" "青海省" "新疆维吾尔自治区" {
    replace province = "甘肃省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 青海省的邻居
foreach n in "新疆维吾尔自治区" "甘肃省" "四川省" "西藏自治区" {
    replace province = "青海省" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 宁夏回族自治区的邻居
foreach n in "内蒙古自治区" "陕西省" "甘肃省" {
    replace province = "宁夏回族自治区" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 新疆维吾尔自治区的邻居
foreach n in "西藏自治区" "青海省" "甘肃省" {
    replace province = "新疆维吾尔自治区" in `i'
    replace neighbor = "`n'" in `i'
    local i = `i' + 1
}

* 香港特别行政区的邻居
replace province = "香港特别行政区" in `i'
replace neighbor = "广东省" in `i'
local i = `i' + 1

* 澳门特别行政区的邻居
replace province = "澳门特别行政区" in `i'
replace neighbor = "广东省" in `i'
local i = `i' + 1

* 清理无效行并准备导出到Excel
drop if province == ""
drop id

* 保存为Excel格式
export excel using "province_neighbors.xlsx", firstrow(variables) replace

* 同时保存为Stata格式（可选）
save "province_neighbors.dta", replace

* 恢复主数据集
restore




* 创建一个空数据集用于保存工具变量结果
preserve
clear
set obs 0
gen province = ""
gen year = .
gen neighbor_digit_mean = .
save "neighbor_iv.dta", replace
restore

* 对于每个省份和年份计算工具变量
levelsof province, local(provinces)
foreach p of local provinces {
    * 对每个年份
    levelsof year, local(years)
    foreach y of local years {
        * 跳过2000年，因为没有1999年的数据
        if (`y' == 2000) continue
        
        * 获取上一年
        local prev_year = `y' - 1
        
        * 暂存当前数据
        preserve
        
        * 加载邻居关系数据
        use "province_neighbors.dta", clear
        keep if province == "`p'"
        levelsof neighbor, local(neighbors)
        
        * 恢复主数据并筛选相邻省份上一年的数据
        restore
        preserve
        
        * 构建邻居列表字符串用于 inlist() 函数
        local neighbor_list ""
        foreach n of local neighbors {
            local neighbor_list `"`neighbor_list' "`n'""'
        }
        
        * 计算相邻省份上一年的数字经济指数平均值
        keep if inlist(province, `neighbor_list') & year == `prev_year'
        
        * 只有在有邻居数据的情况下继续
        if (_N > 0) {
            collapse (mean) neighbor_digit_mean=digit
            
            * 添加省份和年份信息
            gen province = "`p'"
            gen year = `y'
            
            * 保存到工具变量结果
            append using "neighbor_iv.dta"
            save "neighbor_iv.dta", replace
        }
        restore
    }
}



* 合并工具变量回原始数据集
merge m:1 province year using "neighbor_iv.dta"

* 检查合并变量名
describe _merge

* 创建一个临时变量来保存合并状态
gen merge_status = _merge
* 保留成功合并的记录
keep if merge_status == 3
drop merge_status

* 检查工具变量是否有很多NA值
count if missing(neighbor_digit_mean)
di "NA values in IV: " r(N)

* 查看工具变量与原变量的相关性
correlate digit neighbor_digit_mean
local corr_value = r(rho)
di "Correlation between digit and IV: `corr_value'"

* 将合并后的数据保存为Excel格式
export excel using "merged_data.xlsx", firstrow(variables) replace






* (M1) 基准模型 - IV回归
ivregress 2sls efficiency $controls (digit = neighbor_digit_mean), robust
estimates store iv_m1

* (M2) 透明度交互效应模型 - IV回归
gen iv_digit_ft = neighbor_digit_mean * ft
ivregress 2sls efficiency ft $controls (digit digit_ft = neighbor_digit_mean iv_digit_ft), robust
estimates store iv_m2

* (M3) 协同效应交互模型 - IV回归
gen iv_digit_fde = neighbor_digit_mean * fde
ivregress 2sls efficiency fde $controls (digit digit_fde = neighbor_digit_mean iv_digit_fde), robust
estimates store iv_m3

* (M4) 飞轮效应交互模型 - IV回归
gen iv_digit_govc = neighbor_digit_mean * govc
ivregress 2sls efficiency govc $controls (digit digit_govc = neighbor_digit_mean iv_digit_govc), robust
estimates store iv_m4

* 输出IV回归结果汇总表
estimates table iv_m1 iv_m2 iv_m3 iv_m4, b(%9.4f) se(%9.4f) stats(N chi2 p)
di "数字经济对财政支出效率的影响（工具变量回归）"
di "=============================================================="




* 弱工具变量测试 - 第一阶段回归
regress digit neighbor_digit_mean $controls
test neighbor_digit_mean
local f_stat = r(F)
di "弱工具变量F统计量: `f_stat'"

if (`f_stat' > 10) {
    di "F > 10，根据Stock-Yogo经验法则，工具变量足够强"
}
else {
    di "F < 10，可能存在弱工具变量问题"
}

* Hausman内生性检验
regress efficiency digit $controls
predict ols_residuals, residuals
regress ols_residuals neighbor_digit_mean $controls
test neighbor_digit_mean
local hausman_p = r(p)

di "Hausman测试 p值: `hausman_p'"
if (`hausman_p' < 0.05) {
    di "p < 0.05，拒绝外生性假设，存在内生性问题，使用IV回归更合适"
}
else {
    di "p > 0.05，无充分证据拒绝外生性假设"
}


* 8. 比较OLS和IV结果 ------------------------------------------------

* 运行OLS回归作为比较
regress efficiency digit $controls
estimates store ols_m1

* 比较OLS和IV的digit系数
estimates table ols_m1 iv_m1, b(%9.4f) se(%9.4f) keep(digit) stats(N)
di "OLS与IV结果比较 - digit系数"
di "=============================================================="



* 9. 清理临时文件 ----------------------------------------------------
capture erase "province_neighbors.dta"
capture erase "neighbor_iv.dta"

* 总结
di _newline
di "工具变量稳健性检验完成！"
di "使用相邻省份上一年数字化水平的平均值作为工具变量"



* 目前写到这里了
