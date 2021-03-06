:- encoding(utf8).

房间( 厨房 ).
房间( 办公室 ).
房间( 客厅 ).
房间( 餐厅 ).
房间( 地下室 ).

门( 办公室 , 客厅 ).
门( 厨房 , 办公室 ).
门( 客厅 , 餐厅 ).
门( 厨房 , 地下室 ).
门( 餐厅 , 厨房 ).

存在( 桌子 , 办公室 ).
存在( 苹果 , 厨房 ).
存在( 手电筒 , 桌子 ).
存在( 洗衣机 , 地下室 ).
存在( 纳尼 , 洗衣机 ).
存在( 花椰菜 , 厨房 ).
存在( 饼干 , 厨房 ).
存在( 电脑 , 办公室 ).

可食用( 苹果 ).
可食用( 饼干 ).
难以下咽( 花椰菜 ).

我在( 厨房 ).

/** <examples> Your example queries go here, e.g.
?- X #> 存在( X , 厨房 ).
*/