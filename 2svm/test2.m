%------------主函数----------------
clear;
close all;
C = 10;  %成本约束参数
kertype = 'rbf';  %rbf高斯核
 
%①------数据准备5*10方格，每个方格20个点，共1000个点
x1=[];
x3=[];
for i=0:1:9
    for j=0:1:4
        b=j+rand(20,1);%随机生成20个点
        c=i+rand(20,1);      
        x0=[x1;b];
        x2=[x3;c];
        x1=x0;  %这里的x1放所有点的横坐标
        x3=x2;  %x3放所有点的纵坐标,(x1,x3)
    end
end
 
y0=[];%这个矩阵放所有点的标记
y1 = ones(20,1); %20个+1标记
y2 = -ones(20,1);%20个-1标记
for k=0:1:24    %循环赋值，使得5*10方格内相邻的格子标记都不一样
        y0=[y0;y1];
        y0=[y0;y2];
end
 
 
x1=x1.'
x3=x3.'  %记得转置一下哦
figure;  %创建一个用来显示图形输出的一个窗口对象
 
for m=1:1:25
    plot(x1(1,(1+20*(2*m-2)):(20*(2*m-1))),...
        x3(1,(1+20*(2*m-2)):(20*(2*m-1))),'k.');  %画图
    hold on; 
    plot(x1(1,(1+20*(2*m-1)):(20*(2*m))),...
        x3(1,(1+20*(2*m-1)):(20*(2*m))),'b+');  %画图
    hold on;    %在同一个figure中画几幅图时，用此句
end
%axis([0 5 0 10]);  %设置坐标轴范围
 
%②-------------训练样本
X = [x1;x3];        %训练样本2*n矩阵，n为样本个数，d为特征向量个数
Y = y0.';        %训练目标1*n矩阵，n为样本个数，值为+1或-1
svm = svmTrain(X,Y,kertype,C);  %训练样本
%%%把支持向量标出来,若支持向量画的不对，此时可通过在kernel函数调参来修改
for i=1:1:svm.svnum
    if svm.Ysv(1,i)==1
        plot(svm.Xsv(1,i),svm.Xsv(2,i),'mo');%一类支持向量用粉色圈住
    else
        plot(svm.Xsv(1,i),svm.Xsv(2,i),'ko');%另一类支持向量黑色圈
    end
end
%plot(svm.Xsv(1,:),svm.Xsv(2,:),'ro');
 
%③-------------测试
[x1,x2] = meshgrid(0:0.05:5,0:0.05:10);  %最大值控制着等高线在几乘几范围画出来
[rows,cols] = size(x1);  
nt = rows*cols;                  
Xt = [reshape(x1,1,nt);reshape(x2,1,nt)];
%前半句reshape(x1,1,nt)是将x1转成1*（rows*cols）的矩阵，所以Xt是2*（rows*cols）的矩阵
%reshape函数重新调整矩阵的行、列、维数
y3 = ones(1,floor(nt/2));
y4 = -ones(1,floor(nt/2)+1);
Yt = [y3,y4];
 
result = svmTest(svm, Xt, Yt, kertype);
 
%④--------------画曲线的等高线图
Yd = reshape(result.Y,rows,cols);
contour(x1,x2,Yd,3); %产生三个水平的等高线
 
title('5*10数据分类');   
x1=xlabel('X轴');  
x2=ylabel('Y轴'); 
 
 
 
%-----------训练样本的函数svmTrain---------
function svm = svmTrain(X,Y,kertype,C)
 
% Options是用来控制算法的选项参数的向量，optimset无参时，创建一个选项结构所有字段为默认值的选项
options = optimset;    
options.LargeScale = 'off';%LargeScale指大规模搜索，off表示在规模搜索模式关闭
options.Display = 'off';    %表示无输出
 
%二次规划来求解问题，可输入命令help quadprog查看详情
n = length(Y);  %返回Y最长维数
H = (Y'*Y).*kernel(X,X,kertype);    
f = -ones(n,1); %f为1*n个-1,f相当于Quadprog函数中的c
A = [];
b = [];
Aeq = Y; %相当于Quadprog函数中的A1,b1
beq = 0;
lb = zeros(n,1); %相当于Quadprog函数中的LB，UB
ub = C*ones(n,1);
a0 = zeros(n,1);  % a0是解的初始近似值
[a,fval,eXitflag,output,lambda]  = quadprog(H,f,A,b,Aeq,beq,lb,ub,a0,options);
%a是输出变量，问题的解
%fval是目标函数在解a处的值
%eXitflag>0,则程序收敛于解x；=0则函数的计算达到了最大次数；<0则问题无可行解，或程序运行失败
%output输出程序运行的某些信息
%lambda为在解a处的值Lagrange乘子
 
epsilon = 1e-8;  
 %0<a<a(max)则认为x为支持向量,find返回一个包含数组X中每个非零元素的线性索引的向量。 
sv_label = find(abs(a)>epsilon);     
svm.a = a(sv_label);
svm.Xsv = X(:,sv_label);
svm.Ysv = Y(sv_label);
svm.svnum = length(sv_label);
%svm.label = sv_label;
end
 
 
 
%---------------核函数kernel---------------
function K = kernel(X,Y,type)
%X 维数*个数
switch type
case 'linear'   %此时代表线性核
    K = X'*Y;
case 'rbf'      %此时代表高斯核
    delta = 0.5;  %改变这个参数图会变的不一样唉。。。越大支持向量越多。。。
    delta = delta*delta;
    XX = sum(X'.*X',2);     %2表示将矩阵中的按行为单位进行求和
    YY = sum(Y'.*Y',2);
    XY = X'*Y;
    K = abs(repmat(XX,[1 size(YY,1)]) + repmat(YY',[size(XX,1) 1]) - 2*XY);
    K = exp(-K./delta);
end
end
 
 
 
%---------------测试的函数svmTest-------------
function result = svmTest(svm, Xt, Yt, kertype)
temp = (svm.a'.*svm.Ysv)*kernel(svm.Xsv,svm.Xsv,kertype);
%total_b = svm.Ysv-temp;
b = mean(svm.Ysv-temp);  %b取均值
w = (svm.a'.*svm.Ysv)*kernel(svm.Xsv,Xt,kertype);
result.score = w + b;
Y = sign(w+b);  %f(x)
result.Y = Y;
result.accuracy = size(find(Y==Yt))/size(Yt);
end
